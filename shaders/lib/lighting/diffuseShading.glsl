/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef DIFFUSE_SHADING_INCLUDE
#define DIFFUSE_SHADING_INCLUDE

#include "/lib/atmosphere/sky.glsl"
#include "/lib/util/material.glsl"

vec3 shadeDiffuse(vec3 color, vec2 lightmap, vec3 sunlight, Material material, vec3 GI, vec3 skyLightColor){
  vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * pow2(lightmap.y);
  vec3 blockLight = max0(exp(-(1.0 - lightmap.x) * 10.0)) * BLOCKLIGHT_COLOR * BLOCKLIGHT_STRENGTH;
  

  vec3 ambient = vec3(AMBIENT_STRENGTH);

  #ifndef WORLD_OVERWORLD
  ambient *= 3.0;
  #endif

  return color * (
    (
    skyLight +
    // blockLight +
    sunlight +
    GI
    ) / PI +
    ambient +
    material.emission * 2
  );
}

#endif