/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#include "/lib/util/phaseFunctions.glsl"
#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/util/dither.glsl"

const vec3 waterAbsorption =
  WATER_ABSORPTION_MOD *
  vec3(WATER_ABSORPTION_R, WATER_ABSORPTION_G, WATER_ABSORPTION_B) /
  255;
const vec3 waterScattering =
  WATER_SCATTERING_MOD *
  vec3(WATER_SCATTERING_R, WATER_SCATTERING_G, WATER_SCATTERING_B) /
  255;

const vec3 waterExtinction = vec3(waterAbsorption + waterScattering);

#ifdef VOLUMETRIC_WATER
vec3 getWaterFog(vec3 color, vec3 start, vec3 end) {
  float dist = distance(start, end);
  if (dist < 0.01) {
    return color;
  }
  vec3 transmittance = vec3(1.0);
  vec3 scattering = vec3(0.0);

  vec3 dir = normalize(end - start);
  // float phase = dualHenyeyGreenstein(0.7, 0.2, dot(dir, worldLightDir), 0.5);
  float phase = henyeyGreenstein(0.4, dot(dir, worldLightDir));

  vec3 rayStep = (end - start) / VOLUMETRIC_WATER_SAMPLES;
  float stepLength = length(rayStep);

  vec3 stepTransmittance = exp(-stepLength * waterExtinction);

  float jitter = blueNoise(gl_FragCoord.xy, frameCounter).r;

  vec3 shadowStart = viewSpaceToScreenSpaceOrtho(
    transformView(start, shadowModelView),
    shadowProjection
  );
  shadowStart.z /= 2.0;

  vec3 shadowEnd = viewSpaceToScreenSpaceOrtho(
    transformView(end, shadowModelView),
    shadowProjection
  );
  shadowEnd.z /= 2.0;

  for (int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++) {
    float progress = float(i + jitter) / float(VOLUMETRIC_WATER_SAMPLES);

    vec3 shadowRayPos = mix(shadowStart, shadowEnd, progress);
    vec3 rayPos = mix(start, end, progress);
    shadowRayPos.xy += getWarp(shadowRayPos.xy);

    float shadow = texture(shadowtex1HW, shadowRayPos).r;
    vec2 causticsPos =
      (mat3(shadowModelView) * mod(rayPos + cameraPosition, 512)).xy / 128;

    float t = frameTimeCounter * 0.005;
    float caustics = max(
      texture(noisetex, causticsPos + vec2(t, 0.0)).r,
      texture(
        noisetex,
        causticsPos + vec2(-t, t)
      ).r
    );

    caustics = pow3(caustics);

    shadow *= caustics;

    float distanceToSurface =
      max0(shadowRayPos.z - texture(shadowtex0, shadowRayPos.xy).r) *
      VOLUMETRIC_WATER_LIGHT_FALLOFF;

    float transmittanceToSun = shadow * exp(-distanceToSurface);
    vec3 radiance = sunlightColor * transmittanceToSun * phase;

    // vec3 fMS =
    //   (1.0 - exp(-WATER_MULTIPLE_SCATTERING * waterExtinction * stepLength)) *
    //   waterScattering /
    //   waterExtinction;
    // fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS));
    // radiance +=
    //   sunlightColor * transmittanceToSun * isotropicPhase * fMS / (1.0 - fMS);

    radiance += skylightColor * isotropicPhase * EBS.y;

    scattering +=
      transmittance *
      (radiance *
        (1.0 - saturate(stepTransmittance)) *
        waterScattering /
        waterExtinction);
    transmittance *= stepTransmittance;
  }

  return fma(color, transmittance, scattering);
}
#else
vec3 getWaterFog(vec3 color, vec3 start, vec3 end) {
  if (waterExtinction == vec3(0.0)) {
    return color;
  }
  float dist = distance(start, end);
  if (dist < 0.01) {
    return color;
  }
  vec3 dir = normalize(end - start);

  vec3 transmittance = exp(-dist * waterExtinction);
  vec3 scattering = (1.0 - transmittance) * (waterScattering / waterExtinction);
  scattering *=
    (sunlightColor *
      henyeyGreenstein(WATER_ANISOTROPY, dot(dir, worldLightDir)) +
      skylightColor * isotropicPhase) *
    EBS.y;
  return fma(color, transmittance, scattering);
}
#endif

#endif // WATER_FOG_GLSL
