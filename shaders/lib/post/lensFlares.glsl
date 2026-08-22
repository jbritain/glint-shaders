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

#ifndef LENS_FLARES_GLSL
#define LENS_FLARES_GLSL

// based on https://john-chapman.github.io/2017/11/05/pseudo-lens-flare.html

#include "/lib/util/dither.glsl"
#include "/lib/post/bloom.glsl"
#define LENS_FLARE_GHOST_SAMPLES 8

vec3 sampleGhosts(vec2 uv) {
  // return texture(colortex16, scaleFromBloomTile(uv, tiles[2])).rgb;
  uv = 1.0 - uv;

  vec3 color = vec3(0.0);
  vec2 dir = vec2(0.5) - uv;
  vec2 sampleVector = dir * 0.2;

  for (int i = 0; i < LENS_FLARE_GHOST_SAMPLES; i++) {
    vec2 sampleUv = scaleFromBloomTile(uv, tiles[0]);
    vec3 lensFlareSample = vec3(
      texture(colortex16, sampleUv - 0.001 * dir).r,
      texture(colortex16, sampleUv).g,
      texture(colortex16, sampleUv + 0.001 * dir).b
    );

    color += lensFlareSample * (1.0 - smoothstep(0.5, 0.75, maxVec2(uv)));
    uv += sampleVector;
  }

  return color / LENS_FLARE_GHOST_SAMPLES;
}

vec3 sampleHalos(vec2 uv) {
  uv = 1.0 - uv;
  vec2 dir = normalize(vec2(0.5) - uv);

  uv += dir * 0.2;

  vec2 sampleUv = scaleFromBloomTile(uv, tiles[0]);

  vec3 lensFlareSample = vec3(
    texture(colortex16, sampleUv - 0.001 * dir).r,
    texture(colortex16, sampleUv).g,
    texture(colortex16, sampleUv + 0.001 * dir).b
  );

  // lensFlareSample *= abs(sin(dot(uv * 2.0 - 1.0, vec2(1.0, 0.0)) * 1000));

  return lensFlareSample;
}

#endif
