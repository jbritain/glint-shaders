#ifndef DIFFUSE_SHADING_INCLUDE
#define DIFFUSE_SHADING_INCLUDE

#include "/lib/atmosphere/sky.glsl"
#include "/lib/util/material.glsl"

vec3 shadeDiffuse(vec3 color, vec2 lightmap, vec3 sunlight, Material material){
  vec3 skyLightColor = getSky(vec3(0, 1, 0), false);

  vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * pow2(lightmap.y);
  vec3 blockLight = TORCH_COLOR * clamp01(pow(lightmap.x, 10.0) + lightmap.x * 0.7 * 1.5);;

  vec3 ambient = vec3(AMBIENT_STRENGTH);

  return color * (
    skyLight +
    blockLight +
    sunlight +
    ambient * (hasSkylight ? 1.0 : 3.0) +
    material.emission * 16
  );
}

#endif