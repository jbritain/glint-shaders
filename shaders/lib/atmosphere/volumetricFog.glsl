/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

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
float fogDensityFactor = mix(
  pow2(1.0 - abs(worldLightDir.y)) * 0.9 + 0.1,
  1.0,
  wetness
);

float getFogDensity(vec3 position) {
  return (1.0 -
    linearstep(
      VOLUMETRIC_FOG_MIDDLE_PLANE,
      VOLUMETRIC_FOG_TOP_PLANE,
      position.y
    )) *
  VOLUMETRIC_FOG_DENSITY *
  fogDensityFactor;
}

float integrateFogDensity(vec3 position, vec3 dir) {
  float density = 0.0;
  vec3 p;
  if (rayPlaneIntersection(position, dir, VOLUMETRIC_FOG_MIDDLE_PLANE, p)) {
    density +=
      distance(p, position) * VOLUMETRIC_FOG_DENSITY * fogDensityFactor;
    position = p;
  }

  if (rayPlaneIntersection(position, dir, VOLUMETRIC_FOG_TOP_PLANE, p)) {
    density += distance(position, p) * getFogDensity(vec3(position)) / 2;
  }
  return density;
}

vec4 getVolumetricFog(vec3 position, float depth) {
  vec3 dir = normalize(position);

  vec3 start = cameraPosition;
  vec3 end = position + cameraPosition;

  if (depth == 1.0) {
    rayPlaneIntersection(cameraPosition, dir, VOLUMETRIC_FOG_TOP_PLANE, end);
  }
  if (distance(start, end) > 1000) {
    end = start + dir * 1000;
  }

  vec3 shadowStart = viewSpaceToScreenSpaceOrtho(
    transformView(start - cameraPosition, shadowModelView),
    shadowProjection
  );

  vec3 shadowEnd = viewSpaceToScreenSpaceOrtho(
    transformView(end - cameraPosition, shadowModelView),
    shadowProjection
  );

  float stepLength = distance(start, end) / VOLUMETRIC_FOG_SAMPLES;

  float jitter = blueNoise(gl_FragCoord.xy, frameCounter).r;

  float transmittance = 1.0;
  vec3 scattering = vec3(0.0);

  float phase = hgDraine(11, dot(dir, worldLightDir));

  for (int i = 0; i < VOLUMETRIC_FOG_SAMPLES; i++) {
    float progress = float(i + jitter) / float(VOLUMETRIC_FOG_SAMPLES);

    vec3 rayPos = mix(start, end, progress);
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

    radiance += weatherSkylightColor * EBS.y * isotropicPhase;

    #ifdef FLOODFILL
    radiance +=
      sampleFloodfill(rayPos - cameraPosition) *
      EMISSIVE_STRENGTH *
      isotropicPhase;
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

  vec3 radiance =
    sunlightColor * phase + skylightColor * isotropicPhase * EBS.y;

  float fMS =
    (1.0 - exp(-VOLUMETRIC_FOG_MULTIPLE_SCATTERING * density * fogExtinction)) *
    fogScattering /
    fogExtinction;
  fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS)); // this part by luna

  radiance += sunlightColor * 0.02 * isotropicPhase * fMS / (1.0 - fMS); // made up bullshit

  float transmittance = exp(-density * fogExtinction);
  vec3 scatter =
    radiance * (1.0 - transmittance) * (fogScattering / fogExtinction);

  return vec4(scatter, transmittance);
}
#endif
