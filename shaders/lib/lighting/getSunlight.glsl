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
#include "/lib/atmosphere/common.glsl"

vec2 vogelDiscSample(int stepIndex, int stepCount, float rotation) {
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

// subsurface scattering help from tech
vec3 computeSSS(float blockerDistance, float SSS, vec3 faceNormal, vec3 feetPlayerPos){
	#ifndef SUBSURFACE_SCATTERING
	return 0.0;
	#endif

	float NoL = dot(faceNormal, normalize(shadowLightPosition));

	if(SSS < 0.0001){
		return vec3(0.0);
	}

	// if(NoL > -0.00001){
	// 	return vec3(0.0);
	// }

	float s = 1.0 / (SSS * 2.0);
	float z = blockerDistance;

	if(isnan(z)){
		return vec3(0.0);
	}

	vec3 scatter = vec3(0.25 * (exp(-s * z) + 3*exp(-s * z / 3)));

	float cosTheta = clamp01(dot(normalize(feetPlayerPos), lightVector));
	scatter *= henyeyGreenstein(0.4, cosTheta);

	return clamp01(scatter);
}

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
	// if(blockerDistance <= 1.0){
	// 	return 1.0;
	// }

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

vec3 sampleShadow(vec3 shadowScreenPos, out bool isWater){
	float transparentShadow = shadow2D(shadowtex0HW, shadowScreenPos).r;

	if(transparentShadow >= 1.0 - 1e-6){
		return vec3(transparentShadow);
	}

	float opaqueShadow = shadow2D(shadowtex1HW, shadowScreenPos).r;

	if(opaqueShadow <= 1e-6){
		return vec3(opaqueShadow);
	}


	isWater = textureLod(shadowcolor1, shadowScreenPos.xy, 1).r > 0.5;

	vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);
	vec3 shadowColor = shadowColorData.rgb * (1.0 - shadowColorData.a);
	return mix(shadowColor * opaqueShadow, vec3(1.0), transparentShadow);
}

vec3 getShadows(vec4 shadowClipPos, float blockerDistance, float penumbraWidth, vec3 feetPlayerPos){
	float clipPenumbraWidth = penumbraWidth * shadowProjection[0].x * 0.5;

	vec3 shadowSum = vec3(0.0);
	bool doWaterShadow;

	for(int i = 0; i < SHADOW_SAMPLES; i++){
		vec2 offset = clipPenumbraWidth * vogelDiscSample(i, SHADOW_SAMPLES, interleavedGradientNoise(floor(gl_FragCoord.xy), i + frameCounter * SHADOW_SAMPLES));
		bool isWater;
		vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos + vec4(offset, 0.0, 0.0));
		shadowSum += sampleShadow(shadowScreenPos, isWater);

		doWaterShadow = doWaterShadow || isWater;
	}

	shadowSum /= SHADOW_SAMPLES;

	if(doWaterShadow){
		vec3 waterShadow = waterShadow(blockerDistance) * getCaustics(getShadowScreenPos(shadowClipPos), feetPlayerPos, blockerDistance);
		shadowSum *= waterShadow;
	}

	return shadowSum;
}

float blockerSearch(vec4 shadowClipPos){
	float clipBlockerSearchRadius = BLOCKER_SEARCH_RADIUS * shadowProjection[0].x * 0.5;

	float blockerDistanceSum = 0.0;

	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos);

	for(int i = 0; i < BLOCKER_SEARCH_SAMPLES; i++){
		vec2 offset = clipBlockerSearchRadius * vogelDiscSample(i, BLOCKER_SEARCH_SAMPLES, interleavedGradientNoise(floor(gl_FragCoord.xy), i + frameCounter * BLOCKER_SEARCH_SAMPLES));
		bool isWater;
		vec3 sampleShadowScreenPos = getShadowScreenPos(shadowClipPos + vec4(offset, 0.0, 0.0));
		
		float sampleDepth = texture(shadowtex0, sampleShadowScreenPos.xy).r;

		blockerDistanceSum += clamp01(shadowScreenPos.z - sampleDepth);
	}

	return blockerDistanceSum / BLOCKER_SEARCH_SAMPLES;
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
	vec3 bias = getShadowBias(shadowClipPos.xyz, mat3(gbufferModelViewInverse) * faceNormal, faceNoL);
	shadowClipPos.xyz += bias;

	vec3 shadow = vec3(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y));

	float distFade = pow5(
		max(
			clamp01(max2(abs(shadowClipPos.xy))),
			mix(
				1.0, 0.55, 
				smoothstep(0.33, 0.8, lightVector.y)
			) * (dot(feetPlayerPos.xz, feetPlayerPos.xz) * rcp(pow2(shadowDistance)))
		)
	);

	float blockerDistance = blockerSearch(shadowClipPos);


	float penumbraWidth = mix(MIN_PENUMBRA_WIDTH, MAX_PENUMBRA_WIDTH, blockerDistance);
	// penumbraWidth *= 1.0 + 7.0 * SSS * (1.0 - faceNoL);

	blockerDistance *= 2.0;
	blockerDistance *= 255.0;

	shadow = mix(getShadows(shadowClipPos, blockerDistance, penumbraWidth, feetPlayerPos), shadow, distFade);

	sunlight *= shadow;

	vec3 scatter = computeSSS(blockerDistance, SSS, faceNormal, feetPlayerPos);
	sunlight += scatter;


	return sunlight;
}
#endif