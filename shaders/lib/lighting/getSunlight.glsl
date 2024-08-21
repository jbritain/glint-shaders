#ifndef GET_SUNLIGHT_INCLUDE
#define GET_SUNLIGHT_INCLUDE

#include "/lib/lighting/shadowBias.glsl"

vec3 sampleShadow(vec3 shadowScreenPos){
  float transparentShadow = shadow2D(shadowtex0, shadowScreenPos).r;

  if(transparentShadow == 1.0){ // no shadow at all
		return vec3(1.0);
	}

  float opaqueShadow = shadow2D(shadowtex1, shadowScreenPos).r;

  if(opaqueShadow == 0.0){ // opaque shadow so don't sample transparent shadow colour
		return vec3(0.0);
	}

  vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);
  vec3 shadowColor = shadowColorData.rgb * (1.0 - shadowColorData.a);

  return mix(shadowColor * opaqueShadow, vec3(1.0), transparentShadow);
}

float NoLSafe(vec3 n){
  if (normalize(n) == normalize(shadowLightPosition)){
    return 0.0;
  }

  return clamp01(dot(n, normalize(shadowLightPosition)));
}

vec3 getSunlight(vec3 feetPlayerPos, inout vec3 sunlightColor, vec3 mappedNormal, vec3 faceNormal){
  vec4 shadowPos = getShadowPosition(feetPlayerPos, faceNormal);

  vec3 shadow = sampleShadow(shadowPos.xyz);
  float NoL = NoLSafe(faceNormal);
  NoL = min(NoL, NoLSafe(mappedNormal));

  return sunlightColor * shadow * NoL;
}
#endif