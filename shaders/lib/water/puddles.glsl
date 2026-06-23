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

#ifndef PUDDLES_GLSL
#define PUDDLES_GLSL

float overlayBlend(float a, float b) {
  return a < 0.5
    ? 2.0 * a * b
    : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
}

void applyPuddles(
  inout Material material,
  float heightMap,
  vec3 worldPos,
  inout vec3 surfaceNormal,
  vec3 geometryNormal,
  float skyLightmap
) {
  vec2 noisePos = fract(worldPos.xz / 128.0);
  float noise = texture(perlinnoisetex, noisePos).r;
  noise = noise * 0.5 + texture(perlinnoisetex, noisePos * 2).g * 0.5;

  heightMap -= noise * 0.5;

  if (heightMap < 0.75 * wetness) {
    material.f0 = vec3(0.02);
    material.roughness = 0.0;
    surfaceNormal = geometryNormal;
  }
}

#endif // PUDDLES_GLSL
