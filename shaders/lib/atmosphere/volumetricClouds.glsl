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

#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphere.glsl"
#include "/lib/util/phaseFunctions.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/perlinNoise.glsl"

const float cloudScattering = 0.2;
const float cloudAbsorption = 0.0;
const float cloudExtinction = cloudScattering + cloudAbsorption;

const vec2 windDir = vec2(0.0, 1.0);
const float windSpeed = 10;

vec2 getWind() {
  return windDir * worldTimeCounter * windSpeed;
}

float getVolumetricCloudDensity(vec3 rayPos, bool highQuality) {
  rayPos.xz += getWind();

  vec2 coverageCoord = fract(rayPos.xz / 200000 + 0.5);
  vec2 coverageData = texture(cloudCoverageTex, coverageCoord).rg;
  float coverage = linearstep(0.5 - 0.2 * wetness, 0.7, coverageData.r);

  float cloudHeight = coverageData.g;
  cloudHeight = mix(cloudHeight, 1.0, wetness);
  float topAltitude =
    (VOLUMETRIC_CLOUDS_TOP_ALTITUDE - VOLUMETRIC_CLOUDS_BASE_ALTITUDE) *
      cloudHeight +
    VOLUMETRIC_CLOUDS_BASE_ALTITUDE;

  vec3 lowFrequencyNoiseCoord = fract(rayPos / 3000 + 0.5);
  vec2 lowFrequencyNoises = texture(
    lowFrequencyCloudNoiseTex,
    lowFrequencyNoiseCoord
  ).xy;
  float lowFrequencyWorleyFBM = lowFrequencyNoises.x;
  float lowFrequencyPerlinWorley = lowFrequencyNoises.y;

  float heightInPlane = linearstep(
    VOLUMETRIC_CLOUDS_BASE_ALTITUDE,
    topAltitude,
    rayPos.y
  );

  heightInPlane /= 2.0;

  float heightFade =
    linearstep(0.0, 0.15, heightInPlane) *
    pow2(1.0 - linearstep(0.15, 1.2, heightInPlane));

  coverage *= pow2(heightFade);

  float density = remap(
    lowFrequencyPerlinWorley,
    -lowFrequencyWorleyFBM * 2.0,
    1.0,
    0.0,
    1.0
  );
  // float density = 1.0;
  density = remap(density, 1.0 - coverage, 1.0, 0.0, 1.0);
  // density *= heightFade;

  if (highQuality) {
    vec3 highFrequencyNoiseCoord = fract(rayPos / 400 + 0.5);
    float highFrequencyNoise = texture(
      highFrequencyCloudNoiseTex,
      highFrequencyNoiseCoord
    ).r;
    highFrequencyNoise = mix(
      1.0 - highFrequencyNoise,
      highFrequencyNoise,
      clamp01(heightInPlane * 10)
    );

    density = remap(density, 0.6 * highFrequencyNoise, 1.0, 0.0, 1.0);
  }

  density *= coverage;

  density *= 1.0 + wetness;
  return density * VOLUMETRIC_CLOUDS_DENSITY;
}

vec2 getVolumetricCloudTransmittanceToSun(vec3 start, vec3 dir, vec2 jitter) {
  vec3 jitterDir = unmapSphere(jitter);
  dir = normalize(dir + jitterDir * 0.02);

  vec3 a = start;
  vec3 b;
  if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_TOP_ALTITUDE, b)) {
    if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_BASE_ALTITUDE, b)) {
      return vec2(1.0);
    }
  }

  float density = 0.0;

  vec3 previousSamplePos = a;
  for (int i = 0; i < VOLUMETRIC_CLOUDS_SECONDARY_SAMPLES; i++) {
    float progress =
      (float(i) + jitter.x) / float(VOLUMETRIC_CLOUDS_SECONDARY_SAMPLES);
    vec3 samplePos = mix(a, b, exp(5.0 * (progress - 1.0)));

    density +=
      getVolumetricCloudDensity(samplePos, false) *
      distance(previousSamplePos, samplePos);

    previousSamplePos = samplePos;
  }

  return vec2(
    exp(-density * cloudExtinction), // direct transmittance
    exp(-density * cloudExtinction * 0.3) // multiple scattering transmittance
  );
}

vec4 getVolumetricClouds(inout vec3 position, bool sky) {
  #ifndef VOLUMETRIC_CLOUDS
  return vec4(0.0, 0.0, 0.0, 1.0);
  #endif
  vec3 dir = normalize(position);

  vec3 start;
  vec3 end;

  if (
    !rayPlaneIntersection(
      cameraPosition,
      dir,
      VOLUMETRIC_CLOUDS_BASE_ALTITUDE,
      start
    )
  ) {
    start = cameraPosition;
  }

  if (
    !rayPlaneIntersection(
      cameraPosition,
      dir,
      VOLUMETRIC_CLOUDS_TOP_ALTITUDE,
      end
    )
  ) {
    end = cameraPosition;
  }

  if (start == end) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }

  // ensure we are always marching away from the camera
  if (distance(cameraPosition, start) > distance(cameraPosition, end)) {
    vec3 swap = start;
    start = end;
    end = swap;
  }

  // limit ray length if inside cloud plane
  if (start == cameraPosition && distance(cameraPosition, end) > 10000) {
    end = start + dir * 10000;
  }

  if (!sky) {
    // if terrain is closer than entry point, don't both
    if (distance(cameraPosition, start) > length(position)) {
      return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // if terrain is closer than exit point, march to terrain instead
    if (distance(cameraPosition, end) > length(position)) {
      end = position + cameraPosition;
    }
  }

  vec3 rayStep = (end - start) / VOLUMETRIC_CLOUDS_PRIMARY_SAMPLES;
  float stepLength = length(rayStep);

  vec3 rayPos = start;

  vec3 jitter = blueNoise(gl_FragCoord.xy, frameCounter);
  rayPos += rayStep * jitter.x;

  float transmittance = 1.0;
  vec3 scattering = vec3(0.0);

  float VoL = dot(dir, worldLightDir);
  float phase = hgDraine(11, VoL);
  float msPhase = isotropicPhase;

  bool hasHitStart = false;
  position = mix(start, end, 0.5) - cameraPosition;

  for (
    int i = 0;
    i < VOLUMETRIC_CLOUDS_PRIMARY_SAMPLES;
    i++, rayPos += rayStep
  ) {
    float density = getVolumetricCloudDensity(rayPos, true);
    if (density < 1e-3) {
      continue;
    }

    float sampleTransmittance = exp(-density * stepLength * cloudExtinction);

    if (!hasHitStart) {
      hasHitStart = true;
      position = rayPos - cameraPosition;
    }

    // single scattering
    vec2 transmittanceToSun = getVolumetricCloudTransmittanceToSun(
      rayPos,
      worldLightDir,
      jitter.yz
    );
    vec3 radiance = sunlightColor * transmittanceToSun.x * phase * 2;

    // ambient scattering
    radiance += skylightColor * pow2(1.0 - density); // no isotropic phase because it comes from every direction which cancels out

    // multiple scattering
    float fMS =
      (1.0 - exp(-1000.0 * density * cloudExtinction)) *
      cloudScattering /
      cloudExtinction;

    radiance += fMS * sunlightColor * transmittanceToSun.y * msPhase * 2;

    scattering +=
      transmittance *
      (radiance *
        (1.0 - saturate(sampleTransmittance)) *
        cloudScattering /
        cloudExtinction);
    transmittance *= sampleTransmittance;
  }

  // // apply aerial perspective to clouds
  // if (hasHitStart) {
  //   // fuck it - random density value
  //   // the assumption here is that any clouds far enough away to have aerial perspective
  //   // applied to them are unlikely to have any terrain behind them
  //   // so we can just fade them out into the sky
  //   float atmoTransmittance = exp(-length(position) * 5e-5);
  //   scattering *= atmoTransmittance;
  //   transmittance = mix(1.0, transmittance, atmoTransmittance);
  // }

  return vec4(scattering, transmittance);
}

#endif // CLOUDS_GLSL
