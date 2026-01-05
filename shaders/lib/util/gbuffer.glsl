/*
    Copyright (c) 2025 Josh Britain (jbritain)
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

vec3 getSurfaceNormal(vec2 texcoord, mat3 tbn){
  vec3 surfaceNormal = texture(normals, texcoord).rgb;
  surfaceNormal = surfaceNormal * 2.0 - 1.0;
  surfaceNormal.z = sqrt(1.0 - dot(surfaceNormal.xy, surfaceNormal.xy)); // reconstruct z due to labPBR encoding

  return tbn * surfaceNormal;
}

vec2 applyLightmapFalloff(vec2 lightmap){
  // attempt at an inverse square falloff
  lightmap = max0(1.0 / pow2(15 - lightmap * 15 + 1)) - 0.004;
  // dithering before gbuffer packing
  lightmap += vec2(interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter) / 255.0);

  return lightmap;
}

#endif