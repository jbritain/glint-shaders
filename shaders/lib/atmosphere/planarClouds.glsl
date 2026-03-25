/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef PLANAR_CLOUDS_GLSL
#define PLANAR_CLOUDS_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphere.glsl"
#include "/lib/util/phaseFunctions.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/perlinNoise.glsl"

float getPlanarCloudDensity(vec2 pos, bool highSamples) {
  float density = 0.0;
  float weight = 0.0;

  pos = pos / 500000;

  pos += curl(pos * 0.9 - vec2(0.0, worldTimeCounter * 0.0001)) / 5000.0;

  for (int i = 0; i < 16; i++) {
    float sampleWeight = exp2(-float(i));
    pos.y += worldTimeCounter * 0.000025 * sqrt(i + 1);
    vec2 samplePos = pos * exp2(float(i));

    density += texture(perlinnoisetex, fract(samplePos)).r * sampleWeight;

    weight += sampleWeight;

    if (!highSamples) {
      break;
    }
  }

  density /= weight;

  float coverageFactor = 1.0 - (pow2(PLANAR_CLOUDS_COVERAGE) * 0.5 + 0.5);

  density = smoothstep(
    mix(
      0.2,
      0.99,
      max0(coverageFactor - wetness * 0.2 - thunderStrength * 0.3)
    ),
    1.0,
    density
  );

  density *= PLANAR_CLOUDS_DENSITY;

  return density;
}

vec4 getPlanarClouds(vec3 dir) {
  vec3 point;
  if (
    !rayPlaneIntersection(cameraPosition, dir, PLANAR_CLOUDS_ALTITUDE, point)
  ) {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }

  vec3 point2;
  rayPlaneIntersection(
    cameraPosition,
    dir,
    PLANAR_CLOUDS_ALTITUDE + PLANAR_CLOUDS_HEIGHT,
    point2
  ); // todo: this is wasteful and I can definitely just use trig

  float density = getPlanarCloudDensity(point.xz, true);
  float distanceAlongRay = distance(point, point2);
  float transmittance = exp(-distanceAlongRay * density);

  vec3 radiance = sunlightColor * hgDraine(11, dot(dir, worldLightDir));
  radiance += skylightColor * isotropicPhase;

  float fMS =
    1.0 - exp(-PLANAR_CLOUDS_MULTIPLE_SCATTERING * density * distanceAlongRay);
  radiance += fMS * sunlightColor;

  vec3 scattering =
    transmittance * vec3(radiance - radiance * clamp01(transmittance));

  float atmoTransmittance = exp(-length(point) * 5e-5);
  scattering *= atmoTransmittance;
  transmittance = mix(1.0, transmittance, atmoTransmittance);

  return vec4(scattering, transmittance);
}

#endif // PLANAR_CLOUDS_GLSL
