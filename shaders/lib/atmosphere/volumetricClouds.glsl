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
#include "/lib/atmosphere/atmosphericFog.glsl"

const float cloudExtinction = 0.2;

const vec2 windDir = vec2(0.0, 1.0);
const float windSpeed = 10;

vec2 getWind() {
  return windDir * worldTimeCounter * windSpeed;
}

float getVolumetricCloudDensity(vec3 rayPos, bool highQuality) {
  rayPos.xz += getWind();

  vec2 coverageCoord = fract(rayPos.xz / 200000 + 0.5);
  vec2 coverageData = texture(cloudCoverageTex, coverageCoord).rg;
  float coverage = linearstep(0.5 * (1.0 - wetness), 0.7, coverageData.r);

  float cloudHeight = coverageData.g;
  // cloudHeight = mix(cloudHeight, 1.0, wetness);
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
    sqrt(linearstep(0.0, 0.15, heightInPlane)) *
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

  density *= 1.0;
  return density * VOLUMETRIC_CLOUDS_DENSITY;
}

float getVolumetricCloudOpticalDepth(vec3 start, vec3 dir, float jitter) {
  vec3 a = start;
  vec3 b;
  if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_TOP_ALTITUDE, b)) {
    if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_BASE_ALTITUDE, b)) {
      return 1.0;
    }
  }

  float density = 0.0;

  vec3 previousSamplePos = a;
  for (int i = 0; i < VOLUMETRIC_CLOUDS_SECONDARY_SAMPLES; i++) {
    float progress =
      (float(i) + jitter) / float(VOLUMETRIC_CLOUDS_SECONDARY_SAMPLES);
    vec3 samplePos = mix(a, b, exp(5.0 * (progress - 1.0)));

    density +=
      getVolumetricCloudDensity(samplePos, false) *
      distance(previousSamplePos, samplePos);

    previousSamplePos = samplePos;
  }

  return density;
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

  // // limit ray length if inside cloud plane
  // if (start == cameraPosition && distance(cameraPosition, end) > 10000) {
  //   end = start + dir * 10000;
  // }

  if (!sky) {
    // if terrain is closer than entry point, don't bother
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
  // float msPhase = isotropicPhase;

  #define CLOUD_SCATTERING_OCTAVES 4
  #define CLOUD_SCATTERING_ATTENUATION 0.99
  #define CLOUD_SCATTERING_CONTRIBUTION 0.99
  #define CLOUD_SCATTERING_ECCENTRICITY_ATTENUATION 0.5

  float scatteringPhases[CLOUD_SCATTERING_OCTAVES];
  float eccentricity = CLOUD_SCATTERING_ECCENTRICITY_ATTENUATION;
  for (int i = 0; i < CLOUD_SCATTERING_OCTAVES; i++) {
    scatteringPhases[i] = henyeyGreenstein(eccentricity, VoL);
    eccentricity *= eccentricity;
  }

  bool hasHitStart = false;
  position = mix(start, end, 0.5) - cameraPosition;

  float summedTransmittance = 0.0;
  float summedDepth = 0.0;

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
    float densityToSun = getVolumetricCloudOpticalDepth(
      rayPos,
      normalize(worldLightDir + unmapSphere(jitter.yz) * 0.02),
      jitter.y
    );
    vec3 radiance =
      sunlightColor *
      exp(-densityToSun * cloudExtinction * vec3(0.85, 0.9, 1.0)) *
      phase;

    // multiple scattering
    vec3 contribution = vec3(CLOUD_SCATTERING_CONTRIBUTION); // * vec3(0.85, 0.9, 1.0); // slowly tint the clouds a bit blue with the scattering
    float attenuation = CLOUD_SCATTERING_ATTENUATION;
    for (int i = 0; i < CLOUD_SCATTERING_OCTAVES; i++) {
      radiance +=
        sunlightColor *
        exp(-densityToSun * cloudExtinction * attenuation) *
        scatteringPhases[i] *
        contribution;
      contribution *= contribution;
      attenuation *= attenuation;
    }

    // // ambient scattering
    // float densityToSky = getVolumetricCloudOpticalDepth(
    //   rayPos,
    //   vec3(0.0, 1.0, 0.0),
    //   jitter.y
    // );
    radiance += skylightColor * PI; // * exp(-densityToSky * cloudExtinction) * PI;

    summedDepth += transmittance * stepLength * i;
    summedTransmittance += transmittance;

    if (lightningBoltPosition.w > 0.0) {
      float distanceToLightning = distance(
        rayPos.xz,
        lightningBoltPosition.xz + cameraPosition.xz
      );
      radiance +=
        vec3(0.8, 0.5, 1.0) *
        10000000 *
        exp(-distanceToLightning * cloudExtinction * density * stepLength);
    }

    scattering +=
      transmittance * (radiance * (1.0 - saturate(sampleTransmittance)));
    transmittance *= sampleTransmittance;
  }

  float meanDepthWeightedTransmittance = summedDepth / summedTransmittance;
  vec3 fogPos = mapAerialPerspectivePos(
    mat3(gbufferModelView) * dir * meanDepthWeightedTransmittance
  );
  vec4 fog = texture(aerialPerspectiveLUTTex, clamp01(fogPos));
  scattering *= fog.a;
  scattering += fog.rgb;
  transmittance *= fog.a;

  return vec4(scattering, transmittance);
}

#endif // CLOUDS_GLSL
