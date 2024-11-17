/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef GET_SUNLIGHT_INCLUDE
#define GET_SUNLIGHT_INCLUDE

#include "/lib/lighting/shadowBias.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/util/materialIDs.glsl"
#include "/lib/util/dh.glsl"
#include "/lib/water/waveNormals.glsl"

vec3 sampleCloudShadow(vec4 shadowClipPos, vec3 faceNormal){
	vec3 undistortedShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos * vec4(vec2(shadowDistance / far), vec2(1.0))).xyz;

	if(clamp01(undistortedShadowScreenPos.xy) != undistortedShadowScreenPos.xy){
		return vec3(0.0);
	}

	const vec2 offsets[4] =  vec2[](
		vec2(0.5, 0.5),
		vec2(0.5, -0.5),
		vec2(-0.5, 0.5),
		vec2(-0.5, -0.5)
	);

	vec3 cloudShadow = vec3(0.0);

	for(int i = 0; i < offsets.length(); i++){
		cloudShadow += texture(colortex6, undistortedShadowScreenPos.xy + offsets[i] * rcp(512.0)).rgb * rcp(offsets.length());
	}

	cloudShadow = mix(vec3(1.0), cloudShadow, smoothstep(0.1, 0.2, lightVector.y));

	return cloudShadow;
}

float getCaustics(vec3 shadowScreenPos, vec3 feetPlayerPos, float blockerDistance){
	vec3 blockerPos = feetPlayerPos + lightVector * blockerDistance;
	vec3 waveNormal = waveNormal(feetPlayerPos.xz + cameraPosition.xz, vec3(0.0, 1.0, 0.0));
	vec3 refracted = refract(lightVector, waveNormal, rcp(1.33));

	vec3 oldPos = blockerPos;
	vec3 newPos = blockerPos + refracted * blockerDistance;

	float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
	float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

	return clamp01(oldArea / newArea);
}

vec3 waterShadow(float blockerDistance){
	vec3 extinction = exp(-clamp01(WATER_ABSORPTION + WATER_SCATTERING) * blockerDistance);
	return extinction;
}

vec3 sampleShadow(vec3 shadowScreenPos, vec3 feetPlayerPos){
	float transparentShadow = shadow2D(shadowtex0HW, shadowScreenPos).r;

	if(transparentShadow >= 1.0 - 1e-6){
		return vec3(transparentShadow);
	}

	float opaqueShadow = shadow2D(shadowtex1HW, shadowScreenPos).r;

	if(opaqueShadow <= 1e-6){
		return vec3(opaqueShadow);
	}

	bool isWater = textureLod(shadowcolor1, shadowScreenPos.xy, 2).r > 0.5;

	if(isWater){
		float blockerDistance = clamp01(texture(shadowtex0, shadowScreenPos.xy).r - shadowScreenPos.z) * 255 / 0.5;
		return waterShadow(blockerDistance) * getCaustics(shadowScreenPos, feetPlayerPos, blockerDistance);
	}

	vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);
	vec3 shadowColor = shadowColorData.rgb * (1.0 - shadowColorData.a);
	return mix(shadowColor * opaqueShadow, vec3(1.0), transparentShadow);
}

vec3 getSunlight(vec3 feetPlayerPos, vec3 mappedNormal, vec3 faceNormal, float SSS, vec2 lightmap){
	#ifdef WORLD_THE_END
	lightmap.y = 1.0;
	#endif

	vec3 viewLightVector = normalize(shadowLightPosition);
	float faceNoL = clamp01(dot(faceNormal, viewLightVector));
	float mappedNoL = clamp01(dot(mappedNormal, viewLightVector));

	vec3 sunlight = vec3(mappedNoL * step(1e-6, faceNoL));

	if (max3(sunlight) < 1e-6 && SSS < 1e-6){
		return sunlight;
	}

	vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);
	vec3 bias = getShadowBias(shadowClipPos.xyz, mat3(gbufferModelViewInverse) * faceNormal);
	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos);
	shadowScreenPos += bias;

	vec3 shadow = vec3(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y));

	float distFade = pow5(
		max(
			max2(abs(shadowScreenPos.xy * 2.0 - 1.0)),
			mix(
				1.0, 0.55, 
				smoothstep(0.33, 0.8, lightVector.y)
			) * (dot(feetPlayerPos.xz, feetPlayerPos.xz) * rcp(pow2(shadowDistance)))
		)
	);

	shadow = mix(sampleShadow(shadowScreenPos, feetPlayerPos), shadow, clamp01(distFade));

	sunlight = shadow;


	return sunlight;
}
#endif