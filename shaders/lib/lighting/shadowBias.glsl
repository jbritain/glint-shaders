#ifndef SHADOW_BIAS_INCLUDE
#define SHADOW_BIAS_INCLUDE

float getShadowDistance(float depth) {
	depth = depth * 2.0 - 1.0;
	depth /= 0.5; // for distortion
	vec4 shadowHomPos = shadowProjectionInverse * vec4(0.0, 0.0, depth, 1.0);
	return shadowHomPos.z / shadowHomPos.w;
}

// distortion from photon
// https://github.com/sixthsurge/photon/blob/090b3b5d760087b090d8783e6810585fb6e3e44e/shaders/include/light/distortion.glsl
vec3 distort(vec3 pos) {
	float factor = sqrt(sqrt(pow4(pos.x) + pow4(pos.y))) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
	return vec3(pos.xy / factor, pos.z * 0.5);
}

vec4 getShadowClipPos(vec3 playerPos){
	vec4 shadowViewPos = shadowModelView * vec4(playerPos, 1.0);
	vec4 shadowClipPos = shadowProjection * shadowViewPos; //convert to shadow ndc space.
	return shadowClipPos;
}

vec3 getShadowScreenPos(vec4 shadowClipPos, vec3 normal){
	vec3 shadowScreenPos = distort(shadowClipPos.xyz); //apply shadow distortion
  shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1


	return shadowScreenPos;
}

vec4 getUndistortedShadowScreenPos(vec4 shadowClipPos, vec3 normal){

	vec4 shadowScreenPos = shadowProjection * shadowClipPos; //convert to shadow ndc space.
  shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1


	return shadowScreenPos;
}

// bias from complementary
vec3 getShadowBias(vec3 playerPos, vec3 worldNormal, float NoL){
	vec3 bias = 0.25 * worldNormal * clamp01(0.12 + 0.01 * length(playerPos) * (2.0 - clamp01(NoL)));

	return bias;
}
#endif