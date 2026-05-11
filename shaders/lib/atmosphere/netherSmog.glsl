/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef NETHER_SMOG_GLSL
#define NETHER_SMOG_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/misc/voxel.glsl"
#include "/lib/util/phaseFunctions.glsl"

#define NETHER_SMOG_STEPS 16
const vec3 netherSmogAbsorption = vec3(0.0);
const vec3 netherSmogScattering = vec3(0.1);
const vec3 netherSmogExtinction = netherSmogAbsorption + netherSmogScattering;

float getNetherSmogDensity(vec3 pos) {
  return smoothstep(
    0.8,
    1.0,
    texture(
      cloudshapetex,
      fract(pos / vec3(200, 50, 200) + vec3(frameTimeCounter * 0.01, 0.0, 0.0))
    ).r
  ) +
  0.1;
}

Volume getNetherSmog(vec3 pos) {
  Volume v;
  v.scattering = vec3(0.0);
  v.transmittance = vec3(1.0);

  vec3 step = pos / NETHER_SMOG_STEPS;
  float stepLength = length(step);

  vec3 rayPos = vec3(0.0);
  float jitter = blueNoise(gl_FragCoord.xy, frameCounter).r;
  rayPos += step * jitter;

  for (int i = 0; i < NETHER_SMOG_STEPS; i++) {
    float density = getNetherSmogDensity(rayPos + cameraPosition) * stepLength;

    vec3 sampleTransmittance = exp(-density * netherSmogExtinction);
    vec3 radiance = vec3(0.0);

    #ifdef FLOODFILL
    radiance +=
      sampleFloodfill(rayPos) * EMISSIVE_STRENGTH * isotropicPhase / 16;
    #endif

    radiance += vec3(5.0, 2.0, 1.0);

    v.scattering +=
      v.transmittance *
      (radiance *
        (1.0 - saturate(sampleTransmittance)) *
        netherSmogScattering /
        netherSmogExtinction);
    v.transmittance *= sampleTransmittance;
    rayPos += step;
  }

  return v;
}

#endif
