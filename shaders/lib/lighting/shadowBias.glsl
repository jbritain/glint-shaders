/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef SHADOW_BIAS_INCLUDE
#define SHADOW_BIAS_INCLUDE

float quarticLength(vec2 pos){
	return sqrt(sqrt(pow4(pos.x) + pow4(pos.y)));
}

float getShadowDistance(float depth) {
	depth = depth * 2.0 - 1.0;
	depth /= 0.5; // for distortion
	vec4 shadowHomPos = shadowProjectionInverse * vec4(0.0, 0.0, depth, 1.0);
	return shadowHomPos.z / shadowHomPos.w;
}

vec3 distort(vec3 pos) {
	float factor = quarticLength(pos.xy) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
	return vec3(pos.xy / factor, pos.z * 0.5);
}

vec4 getShadowClipPos(vec3 playerPos){
	vec4 shadowViewPos = shadowModelView * vec4(playerPos, 1.0);
	vec4 shadowClipPos = shadowProjection * shadowViewPos;
	return shadowClipPos;
}

vec3 getShadowScreenPos(vec4 shadowClipPos){
	vec3 shadowScreenPos = distort(shadowClipPos.xyz); //apply shadow distortion
  shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1


	return shadowScreenPos;
}

vec4 getUndistortedShadowScreenPos(vec4 shadowClipPos){

	vec4 shadowScreenPos = shadowClipPos; //convert to shadow ndc space.
  shadowScreenPos.xyz = shadowScreenPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1


	return shadowScreenPos;
}

// bias from complementary
vec3 getShadowBias(vec3 playerPos, vec3 worldNormal, float NoL, float skyLightmap){
	vec3 bias = 0.25 * worldNormal * clamp01(0.12 + 0.01 * length(playerPos) * (2.0 - clamp01(NoL)));

	vec3 edgeFactor = 0.1 - 0.2 * fract(playerPos + cameraPosition + worldNormal * 0.01);
	return bias + edgeFactor * clamp01(1.0 - skyLightmap);
}
#endif