/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef GBUFFER_GLSL
#define GBUFFER_GLSL

#include "/lib/util/dither.glsl"

vec3 getSurfaceNormal(vec2 texcoord, mat3 tbn) {
  vec3 surfaceNormal = texture(normals, texcoord).rgb;
  surfaceNormal = surfaceNormal * 2.0 - 1.0;
  surfaceNormal.z = sqrt(1.0 - dot(surfaceNormal.xy, surfaceNormal.xy)); // reconstruct z due to labPBR encoding

  return tbn * surfaceNormal;
}

vec2 applyLightmapFalloff(vec2 lightmap) {
  // attempt at an inverse square falloff
  const float f = 15;
  lightmap = clamp01(lightmap);
  lightmap = (1.0 - lightmap) * 15;
  lightmap = 1.0 / (lightmap + 1);

  return lightmap;
}

// based on snippet by NinjaMike
vec2 applyDirectionalLightmap(
  vec2 lightmap,
  vec3 viewPos,
  vec3 surfaceNormal,
  mat3 tbnMatrix,
  float subsurface
) {
  vec3 dFdViewposX = dFdx(viewPos);
  vec3 dFdViewposY = dFdy(viewPos);

  vec2 dFdTorch = vec2(dFdx(lightmap.x), dFdy(lightmap.x));
  vec2 dFdSky = vec2(dFdx(lightmap.y), dFdy(lightmap.y));

  vec3 torchDir =
    length(dFdTorch) > 1e-6
      ? normalize(dFdViewposX * dFdTorch.x + dFdViewposY * dFdTorch.y)
      : -tbnMatrix[2];
  vec3 skyDir =
    length(dFdSky) > 1e-6
      ? normalize(dFdViewposX * dFdSky.x + dFdViewposY * dFdSky.y)
      : -gbufferModelViewInverse[1].xyz;

  float torchFactor;

  if (length(dFdTorch) > 1e-6) {
    float NoL = dot(torchDir, surfaceNormal);
    float NGoL = dot(torchDir, tbnMatrix[2]);

    lightmap.x +=
      clamp01((NoL - NGoL) * lightmap.x * (1.0 - subsurface * 0.5)) * 0.25;
  } else {
    float NoL = 0.9 - dot(tbnMatrix[2], surfaceNormal);
    lightmap.x -= clamp01(NoL * lightmap.x * (1.0 - subsurface * 0.5)) * 0.25;
  }

  return clamp01(lightmap);

}

#endif
