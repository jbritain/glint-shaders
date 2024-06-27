#include "/lib/shadowBias.glsl"

vec3 getSunlight(vec3 feetPlayerPos, vec3 sunlightColor, vec3 normal){
  #ifndef SHADOWS
    return sunlightColor;
  #endif
  vec4 shadowPos = getShadowPosition(feetPlayerPos, normal);

  return vec3(shadow2D(shadow, shadowPos.xyz)) * sunlightColor;
}