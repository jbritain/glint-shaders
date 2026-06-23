/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef VOLUMETRIC_FOG_GLSL
#define VOLUMETRIC_FOG_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphere.glsl"
#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/util/phaseFunctions.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/lighting/cloudShadows.glsl"
#include "/lib/misc/voxel.glsl"

const float fogScattering = 1.0;
const float fogAbsorption = 0.0;
const float fogExtinction = fogScattering + fogAbsorption;

float getFogDensity(vec3 position) {
  const float falloff = VOLUMETRIC_FOG_HEIGHT_FALLOFF;
  const float topFactor = exp(
    -(VOLUMETRIC_FOG_TOP_PLANE - VOLUMETRIC_FOG_MIDDLE_PLANE) * falloff
  );

  float fogDensityFactor = 0.0;
  if (sunAngle <= 0.25) {
    fogDensityFactor = mix(
      VOLUMETRIC_FOG_DENSITY_MORNING,
      VOLUMETRIC_FOG_DENSITY_DAY,
      smoothstep(0.0, 0.25, sunAngle)
    );
  } else if (sunAngle <= 0.5) {
    fogDensityFactor = mix(
      VOLUMETRIC_FOG_DENSITY_DAY,
      VOLUMETRIC_FOG_DENSITY_EVENING,
      smoothstep(0.25, 0.5, sunAngle)
    );
  } else if (sunAngle <= 0.75) {
    fogDensityFactor = mix(
      VOLUMETRIC_FOG_DENSITY_EVENING,
      VOLUMETRIC_FOG_DENSITY_NIGHT,
      smoothstep(0.5, 0.75, sunAngle)
    );
  } else if (sunAngle <= 1.0) {
    fogDensityFactor = mix(
      VOLUMETRIC_FOG_DENSITY_NIGHT,
      VOLUMETRIC_FOG_DENSITY_MORNING,
      smoothstep(0.75, 1.0, sunAngle)
    );
  }

  fogDensityFactor = mix(
    fogDensityFactor,
    VOLUMETRIC_FOG_DENSITY_RAIN,
    wetness
  );
  fogDensityFactor = mix(
    fogDensityFactor,
    VOLUMETRIC_FOG_DENSITY_THUNDER,
    thunderStrength
  );

  return clamp01(
    (exp(-(position.y - VOLUMETRIC_FOG_MIDDLE_PLANE) * falloff) - topFactor) /
      (1.0 - topFactor)
  ) *
  linearstep(
    VOLUMETRIC_FOG_BOTTOM_PLANE,
    VOLUMETRIC_FOG_MIDDLE_PLANE,
    position.y
  ) *
  fogDensityFactor;
}

float integrateFogDensity(vec3 position, vec3 dir) {
  const float steps = 8;
  if (
    position.y > VOLUMETRIC_FOG_TOP_PLANE && dir.y > 0 ||
    position.y < VOLUMETRIC_FOG_BOTTOM_PLANE && dir.y < 0.0
  ) {
    return 0.0;
  }
  vec3 end;
  if (dir.y > 0.0) {
    rayPlaneIntersection(position, dir, VOLUMETRIC_FOG_TOP_PLANE, end);
  } else {
    rayPlaneIntersection(cameraPosition, dir, VOLUMETRIC_FOG_BOTTOM_PLANE, end);
  }

  float totalDensity = 0.0;
  vec3 rayStep = (end - position) / steps;

  for (int i = 0; i < steps - 1; i++) {
    totalDensity += getFogDensity(position);
    position += rayStep;
  }

  return totalDensity * length(rayStep);
}

vec4 getVolumetricFog(vec3 position, float depth) {
  vec3 dir = normalize(position);

  vec3 start = cameraPosition;
  vec3 end = position + cameraPosition;

  if (depth == 1.0) {
    if (dir.y > 0.0) {
      rayPlaneIntersection(cameraPosition, dir, VOLUMETRIC_FOG_TOP_PLANE, end);
    } else {
      rayPlaneIntersection(
        cameraPosition,
        dir,
        VOLUMETRIC_FOG_BOTTOM_PLANE,
        end
      );
    }

  }
  if (distance(start, end) > 10000) {
    end = start + dir * 10000;
  }

  vec3 shadowStart = viewSpaceToScreenSpaceOrtho(
    transformView(start - cameraPosition, shadowModelView),
    shadowProjection
  );

  vec3 shadowEnd = viewSpaceToScreenSpaceOrtho(
    transformView(end - cameraPosition, shadowModelView),
    shadowProjection
  );

  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).xy;

  float transmittance = 1.0;
  vec3 scattering = vec3(0.0);

  float phase = hgDraine(2.1, dot(dir, worldLightDir));

  vec3 previousRayPos = start;

  for (int i = 0; i < VOLUMETRIC_FOG_SAMPLES; i++) {
    float progress = float(i + jitter.x) / float(VOLUMETRIC_FOG_SAMPLES);
    // progress = pow(progress, 1.0 / (jitter.y * 0.5 + 0.5));
    // progress = exp(5.0 * (progress - 1.0));

    vec3 rayPos = mix(start, end, progress);
    float stepLength = distance(previousRayPos, rayPos);
    previousRayPos = rayPos;
    vec3 shadowRayPos = mix(shadowStart, shadowEnd, progress);
    shadowRayPos.xy += getWarp(shadowRayPos.xy);

    float density = getFogDensity(rayPos) * stepLength;
    if (density == 0.0) {
      continue;
    }

    float sampleTransmittance = exp(-density * fogExtinction);

    float shadow =
      shadowRayPos == clamp01(shadowRayPos)
        ? texture(shadowtex1HW, shadowRayPos).r
        : 1.0;
    shadow *= getCloudShadow(rayPos - cameraPosition);

    float transmittanceToSun =
      exp(-integrateFogDensity(rayPos, worldLightDir) * fogExtinction) * shadow;

    vec3 radiance = sunlightColor * transmittanceToSun * phase;

    float fMS =
      (1.0 -
        exp(-VOLUMETRIC_FOG_MULTIPLE_SCATTERING * density * fogExtinction)) *
      fogScattering /
      fogExtinction;
    fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS)); // this part by luna

    radiance +=
      sunlightColor * transmittanceToSun * isotropicPhase * fMS / (1.0 - fMS);

    radiance += weatherSkylightColor * EBS.y * 2.0; // should be divided by 2 but I like it brighter

    #ifdef FLOODFILL
    radiance +=
      sampleFloodfill(rayPos - cameraPosition) *
      EMISSIVE_STRENGTH *
      isotropicPhase /
      16;
    #endif

    scattering +=
      transmittance *
      (radiance *
        (1.0 - saturate(sampleTransmittance)) *
        fogScattering /
        fogExtinction);
    transmittance *= sampleTransmittance;

  }

  return vec4(scattering, transmittance);
}

// only works on sky pixels which is all we need anyway
vec4 analyticalFog(vec3 origin, vec3 dir) {
  float density = integrateFogDensity(origin + cameraPosition, dir);

  if (density == 0.0) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }

  float phase = hgDraine(11, dot(dir, worldLightDir));

  float transmittanceToSun = exp(
    -integrateFogDensity(origin, worldLightDir) * fogExtinction
  );

  vec3 radiance =
    sunlightColor * phase * transmittanceToSun +
    skylightColor * isotropicPhase * EBS.y;

  float fMS =
    (1.0 - exp(-VOLUMETRIC_FOG_MULTIPLE_SCATTERING * density * fogExtinction)) *
    fogScattering /
    fogExtinction;
  fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS)); // this part by luna

  radiance +=
    sunlightColor * transmittanceToSun * isotropicPhase * fMS / (1.0 - fMS); // made up bullshit

  float transmittance = exp(-density * fogExtinction);
  vec3 scatter =
    radiance * (1.0 - transmittance) * (fogScattering / fogExtinction);

  return vec4(scatter, transmittance);
}
#endif
