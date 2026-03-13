/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef VOLUMETRIC_CLOUDS_GLSL
#define VOLUMETRIC_CLOUDS_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphere.glsl"
#include "/lib/util/phaseFunctions.glsl"
#include "/lib/util/misc.glsl"

uniform sampler3D cloudshapetex;
uniform sampler3D clouddetailtex;
uniform sampler2D cloudcoveragetex;
uniform sampler2D vanillacloudtex;

const float cloudScattering = 2.0;
const float cloudAbsorption = 0.44;
const float cloudExtinction = cloudScattering + cloudAbsorption;

// float get2DCloudDensity(vec3 rayPos){

// }

float getVolumetricCloudDensity(vec3 rayPos, bool highQuality) {
  #if VOLUMETRIC_CLOUDS_STYLE == 2
  vec2 samplePos = (rayPos.xz + vec2(frameTimeCounter, 0.0)) * 2.0;
  ivec2 p = ivec2(floor(mod(samplePos / 24, 256)));

  return texelFetch(vanillacloudtex, p, 0).r * VOLUMETRIC_CLOUDS_DENSITY;
  #else
  vec2 windDir = vec2(0.0, 1.0);
  vec2 wind = windDir * frameTimeCounter;

  rayPos.xz += wind;

  #if VOLUMETRIC_CLOUDS_STYLE == 1
  rayPos = floor(rayPos / 16) * 16;
  #endif

  float heightInPlane = linearstep(
    VOLUMETRIC_CLOUDS_BASE_ALTITUDE,
    VOLUMETRIC_CLOUDS_TOP_ALTITUDE,
    rayPos.y
  );
  rayPos.xz += windDir * heightInPlane * 20.0;

  // Based loosely upon "Real Time Volumetric Cloudscapes" by Andrew Schneider in GPU Pro 7
  // Coverage texture generated with 'Strepitus' by luna5ama (https://github.com/luna5ama/strepitus)
  // Shape and detail textures generated with jaekmichie97's noise generator (https://github.com/jcm2606/volume-noise-generator)
  float coverage = smoothstep(
    0.7 * (1.0 - wetness),
    1.0,
    texture(cloudcoveragetex, fract(rayPos.xz / 50000.0)).r
  ); // todo: make this a setting so it's consistent for cloud shadows
  // coverage += rainStrength;
  coverage *= heightInPlane * 0.3 + 0.7;

  // coverage = sqrt(coverage);

  vec4 lowFrequencyNoise = texture(cloudshapetex, fract(rayPos.xyz / 1100.0));
  float lowFrequencyFBM =
    lowFrequencyNoise.g * 0.625 +
    lowFrequencyNoise.b * 0.25 +
    lowFrequencyNoise.a * 0.125;
  float density = remap(
    lowFrequencyNoise.r,
    lowFrequencyFBM * 0.7,
    1.0,
    0.0,
    1.0
  );
  density = sqrt(density);

  float heightFactor = min(
    smoothstep(0.0, 0.15, heightInPlane / 2),
    pow2(1.0 - smoothstep(0.15, 1.0, heightInPlane / 2))
  );
  density *= heightFactor;

  density = remap(density, 1.0 - coverage, 1.0, 0.0, 1.0);
  // density *= coverage;

  // density = pow(density, 1.5);

  if (highQuality) {
    vec3 highFrequencyNoise = texture(
      clouddetailtex,
      fract(rayPos.xyz / 300.0 + vec3(wind.x * 0.01, 0.0, wind.y * 0.01))
    ).rgb;
    float highFrequencyFBM =
      highFrequencyNoise.r * 0.625 +
      highFrequencyNoise.g * 0.25 +
      highFrequencyNoise.b * 0.125;
    highFrequencyFBM = mix(
      highFrequencyFBM,
      1.0 - highFrequencyFBM,
      saturate(heightInPlane * 10.0)
    );

    density = remap(density, highFrequencyFBM * 0.7, 1.0, 0.0, 1.0);
  } else {
    density = remap(density, 0.25, 1.0, 0.0, 1.0); // the remap operation from the high quality noise affects the overall density - this emulates that
  }

  return density * VOLUMETRIC_CLOUDS_DENSITY * (1.0 + wetness * 4.0);
  #endif
}

float getVolumetricCloudTransmittanceToSun(vec3 start, vec3 dir, vec2 jitter) {
  vec3 jitterDir = unmapSphere(jitter);
  dir = normalize(dir + jitterDir * 0.1);

  vec3 a = start;
  vec3 b;
  if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_TOP_ALTITUDE, b)) {
    if (!rayPlaneIntersection(a, dir, VOLUMETRIC_CLOUDS_BASE_ALTITUDE, b)) {
      return 1.0;
    }
  }

  float density = 0.0;

  vec3 previousSamplePos = a;
  for (int i = 0; i < CLOUD_SECONDARY_SAMPLES; i++) {
    float progress = (float(i) + jitter.x) / float(CLOUD_SECONDARY_SAMPLES);
    vec3 samplePos = mix(a, b, exp(5.0 * (progress - 1.0)));

    density +=
      getVolumetricCloudDensity(samplePos, false) *
      distance(previousSamplePos, samplePos);

    previousSamplePos = samplePos;
  }

  return exp(-density * cloudExtinction);
}

vec4 getVolumetricClouds(inout vec3 position, bool sky) {
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
  if (start == cameraPosition && distance(cameraPosition, end) > 1000) {
    end = start + dir * 1000;
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

  vec3 rayStep = (end - start) / CLOUD_PRIMARY_SAMPLES;
  float stepLength = length(rayStep);

  vec3 rayPos = start;

  vec3 jitter = blueNoise(gl_FragCoord.xy, frameCounter);
  rayPos += rayStep * jitter.x;

  float transmittance = 1.0;
  vec3 scattering = vec3(0.0);

  float phase = hgDraine(11, dot(dir, worldLightDir));

  bool hasHitStart = false;
  position = mix(start, end, 0.5) - cameraPosition;

  for (int i = 0; i < CLOUD_PRIMARY_SAMPLES; i++, rayPos += rayStep) {
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
    float transmittanceToSun = getVolumetricCloudTransmittanceToSun(
      rayPos,
      worldLightDir,
      jitter.yz
    );
    vec3 radiance = sunlightColor * transmittanceToSun * phase;

    // multiple scattering approximation by ohmygggod (窝的舔)
    // https://zhuanlan.zhihu.com/p/457997155
    // "discovered" by Luna5ama
    float fMS =
      (1.0 -
        exp(
          -VOLUMETRIC_CLOUDS_MULTIPLE_SCATTERING *
            density *
            cloudExtinction *
            stepLength
        )) *
      cloudScattering /
      cloudExtinction;
    // fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS)); // this part by luna
    radiance +=
      sunlightColor * transmittanceToSun * isotropicPhase * fMS / (1.0 - fMS);

    // ambient scattering
    radiance += skylightColor;

    scattering +=
      transmittance *
      (radiance *
        (1.0 - saturate(sampleTransmittance)) *
        cloudScattering /
        cloudExtinction);
    transmittance *= sampleTransmittance;
  }

  // apply aerial perspective to clouds
  if (hasHitStart) {
    // fuck it - random density value
    // the assumption here is that any clouds far enough away to have aerial perspective
    // applied to them are unlikely to have any terrain behind them
    // so we can just fade them out into the sky
    float atmoTransmittance = exp(-length(position) * 5e-5);
    scattering *= atmoTransmittance;
    transmittance = mix(1.0, transmittance, atmoTransmittance);
  }

  return vec4(scattering, transmittance);
}

#endif // VOLUMETRIC_CLOUDS_GLSL
