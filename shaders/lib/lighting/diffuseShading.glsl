#ifndef DIFFUSE_SHADING_INCLUDE
#define DIFFUSE_SHADING_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec3 shadeDiffuse(vec3 color, vec2 lightmap, vec3 sunlight){
  vec3 skyLightColor = getSky(vec3(0, 1, 0), false);

  vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * lightmap.y;
  vec3 blockLight = TORCH_COLOR * lightmap.x;

  vec3 ambient = vec3(AMBIENT_STRENGTH);

  return color * (
    skyLight +
    blockLight +
    sunlight +
    ambient
  );
}

#endif