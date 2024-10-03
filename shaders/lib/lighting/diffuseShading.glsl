#ifndef DIFFUSE_SHADING_INCLUDE
#define DIFFUSE_SHADING_INCLUDE

#include "/lib/atmosphere/sky.glsl"
#include "/lib/util/material.glsl"

vec3 shadeDiffuse(vec3 color, vec2 lightmap, vec3 sunlight, Material material, vec3 GI, vec3 skyLightColor){
  vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * pow2(lightmap.y);
  vec3 blockLight = TORCH_COLOR * clamp01(pow(lightmap.x, 10.0) + lightmap.x * 0.7 * 1.5) * BLOCKLIGHT_STRENGTH;

  vec3 ambient = vec3(AMBIENT_STRENGTH);

  #ifndef WORLD_OVERWORLD
  ambient *= 3.0;
  #endif

  return color * (
    (skyLight +
    blockLight +
    sunlight +
    GI) / PI +
    ambient +
    material.emission * 2
  );
}

#endif