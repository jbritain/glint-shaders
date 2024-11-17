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

vec3 distort(vec3 pos) {
	float factor = length(pos.xy) + SHADOW_DISTORTION;
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

vec3 getShadowBias(vec3 pos, vec3 worldNormal){
	vec4 shadowNormal = shadowProjection * vec4(mat3(shadowModelView) * worldNormal, 1.0);

	float numerator = pow2(length(pos.xy) + SHADOW_DISTORTION);
	float bias =  SHADOW_BIAS / shadowMapResolution * numerator / SHADOW_DISTORTION;

	return shadowNormal.xyz / shadowNormal.w * bias;
}
#endif