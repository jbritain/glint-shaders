#ifndef SHADOW_BIAS_INCLUDE
#define SHADOW_BIAS_INCLUDE

// https://github.com/shaderLABS/Shadow-Tutorial/

#ifdef SHADOW_DISTORT_ENABLED
	vec3 distort(vec3 pos) {
		float factor = length(pos.xy) + SHADOW_DISTORT_FACTOR;
		return vec3(pos.xy / factor, pos.z * 0.5);
	}

	//returns the reciprocal of the derivative of our distort function,
	//multiplied by SHADOW_BIAS.
	//if a texel in the shadow map contains a bigger area,
	//then we need more bias. therefore, we need to know how much
	//bigger or smaller a pixel gets as a result of applying sistortion.
	float computeBias(vec3 pos) {
		//square(length(pos.xy) + SHADOW_DISTORT_FACTOR) / SHADOW_DISTORT_FACTOR
		float numerator = length(pos.xy) + SHADOW_DISTORT_FACTOR;
		numerator *= numerator;
		return SHADOW_BIAS / shadowMapResolution * numerator / SHADOW_DISTORT_FACTOR;
	}
#else
	vec3 distort(vec3 pos) {
		return vec3(pos.xy, pos.z * 0.5);
	}

	float computeBias(vec3 pos) {
		return SHADOW_BIAS / shadowMapResolution;
	}
#endif

vec4 getShadowPosition(vec3 playerPos, vec3 normal){
  float nDotL = clamp01(dot(normal, normalize(shadowLightPosition)));
  // if (nDotL <= 0.0) {
  //   return vec4(0.0);
  // }
  vec4 shadowPos = shadowProjection * (shadowModelView * vec4(playerPos, 1.0)); //convert to shadow ndc space.
  float bias = computeBias(shadowPos.xyz);
  shadowPos.xyz = distort(shadowPos.xyz); //apply shadow distortion
  shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1

  #ifdef NORMAL_BIAS
    //we are allowed to project the normal because shadowProjection is purely a scalar matrix.
    //a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
    shadowPos.xyz += normal.xyz * bias;
  #else
    shadowPos.z -= bias / abs(nDotL);
  #endif

  return shadowPos;
}

vec4 getShadowClipPos(vec3 playerPos){
	vec4 shadowClipPos = shadowModelView * vec4(playerPos, 1.0);
	return shadowClipPos;
}

vec4 getShadowScreenPos(vec4 shadowClipPos, vec3 normal){
	float NoL = clamp01(dot(normal, normalize(shadowLightPosition)));

	vec4 shadowScreenPos = shadowProjection * shadowClipPos; //convert to shadow ndc space.
	float bias = computeBias(shadowScreenPos.xyz);
	shadowScreenPos.xyz = distort(shadowScreenPos.xyz); //apply shadow distortion
  shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1

	#ifdef NORMAL_BIAS
    //we are allowed to project the normal because shadowProjection is purely a scalar matrix.
    //a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
    shadowScreenPos.xyz += normal.xyz * bias;
  #else
    shadowScreenPos.z -= bias;
  #endif


	return shadowScreenPos;
}
#endif