#ifndef DIFFUSE_SHADING_INCLUDE
#define DIFFUSE_SHADING_INCLUDE

#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/getSunlight.glsl"

vec3 shadeDiffuse(vec3 feetPlayerPos, vec3 color, vec2 lightmap, vec3 mappedNormal, vec3 faceNormal){
  vec3 sunlightColor = getSky(SUN_VECTOR, true);
  vec3 skyLightColor = getSky(mat3(gbufferModelViewInverse) * faceNormal, false);

  vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * lightmap.y;
  vec3 blockLight = TORCH_COLOR * lightmap.x;
  vec3 sunlight = getSunlight(feetPlayerPos, sunlightColor, mappedNormal, faceNormal);
  vec3 ambient = vec3(AMBIENT_STRENGTH);

  return color * (
    skyLight +
    blockLight +
    sunlight +
    ambient
  );
}

#endif