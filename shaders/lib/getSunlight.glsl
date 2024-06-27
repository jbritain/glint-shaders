#include "/lib/shadowBias.glsl"

vec3 getSunlight(vec3 feetPlayerPos, inout vec3 sunlightColor, vec3 normal){
  #ifndef SHADOWS
    return sunlightColor;
  #endif
  vec4 shadowPos = getShadowPosition(feetPlayerPos, normal);

  #ifndef TRANSPARENT_SHADOWS
  return vec3(shadow2D(shadowtex0, shadowPos.xyz)) * sunlightColor;
  #endif

  float opaqueShadow = shadow2D(shadowtex0, shadowPos.xyz).r;
  float fullShadow = shadow2D(shadowtex1, shadowPos.xyz).r;
  vec4 shadowColorData = texture(shadowcolor0, shadowPos.xy);
  float shadowTransparency = 1.0 - shadowColorData.a;
  vec3 shadowColor = shadowColorData.rgb * shadowTransparency;
  

  return mix(shadowColor * fullShadow, vec3(1.0), opaqueShadow) * sunlightColor;
}