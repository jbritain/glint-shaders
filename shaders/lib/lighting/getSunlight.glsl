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

vec2 vogelDiscSample(int stepIndex, int stepCount, float rotation) {
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

// ask tech, idk
float computeSSS(float blockerDistance, float SSS, vec3 normal){
	#ifndef SUBSURFACE_SCATTERING
	return 0.0;
	#endif

	if(SSS < 0.0001){
		return 0.0;
	}

	float NoL = dot(normal, normalize(shadowLightPosition));

	if(NoL > -0.00001){
		return 0.0;
	}

	float s = 1.0 / (SSS * 0.2);
	float z = blockerDistance * 255 * 2; // multiply by 2 to account for distortion halving z

	if(isnan(z)){
		z = 0.0;
	}

	float scatter = 0.25 * (exp(-s * z) + 3*exp(-s * z / 3));

	return clamp01(scatter);
}

vec3 sampleShadow(vec4 shadowClipPos, vec3 normal){
	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos).xyz;
  float transparentShadow = shadow2D(shadowtex0HW, shadowScreenPos).r;

  if(transparentShadow == 1.0){ // no shadow at all
		return vec3(1.0);
	}

  float opaqueShadow = shadow2D(shadowtex1HW, shadowScreenPos).r;

  if(opaqueShadow == 0.0){ // opaque shadow so don't sample transparent shadow colour
		return vec3(0.0);
	}

  vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);

	bool isWater = texture(shadowcolor1, shadowScreenPos.xy).r > 0.5;

	if(isWater){
		float blockerDistanceRaw = max0(shadowScreenPos.z - texture(shadowtex0, shadowScreenPos.xy).r);
		float blockerDistance = blockerDistanceRaw * 255 * 2;

		// #ifdef composite
		// if(isEyeInWater != 1){
		// 	shadowColorData.a = mix(shadowColorData.a, 1.0, 0.4);
		// }
		// #endif

		vec3 extinction = exp(-clamp01(WATER_ABSORPTION + WATER_SCATTERING) * blockerDistance) * (1.0 - shadowColorData.a);

		return extinction;
	}

  vec3 shadowColor = shadowColorData.rgb * (1.0 - shadowColorData.a);

  return mix(shadowColor * opaqueShadow, vec3(1.0), transparentShadow);
}

float NoLSafe(vec3 n){
  if (normalize(n) == normalize(shadowLightPosition)){
    return 0.0;
  }

  return clamp01(dot(n, normalize(shadowLightPosition)));
}

float getBlockerDistance(vec4 shadowClipPos, vec3 normal, float jitter, float range){
	vec3 receiverShadowScreenPos = getShadowScreenPos(shadowClipPos).xyz;
	float receiverDepth = receiverShadowScreenPos.z;

	float blockerDistance = 0;

	float blockerCount = 0;

	for(int i = 0; i < BLOCKER_SEARCH_SAMPLES; i++){
		vec2 offset = vogelDiscSample(i, BLOCKER_SEARCH_SAMPLES, jitter) * shadowProjection[0][0];
		vec3 newShadowScreenPos = getShadowScreenPos(shadowClipPos + vec4(offset * range, 0.0, 0.0)).xyz;
		float newBlockerDepth = texture(shadowtex0, newShadowScreenPos.xy).r;
		if (newBlockerDepth < receiverDepth){
			blockerDistance += (receiverDepth - newBlockerDepth);
			blockerCount += 1;
		}
	}

	if(blockerCount == 0){
		return 0.0;
	}
	blockerDistance /= blockerCount;

	return clamp01(blockerDistance);
}

// 'direct' is for whether we're coming via the `getSunlight` function.
// this is so that we don't compute the cloud shadows twice if not necessary
vec3 computeShadow(vec4 shadowClipPos, float penumbraWidth, vec3 normal, int samples, bool direct, float jitter){

	vec3 shadowSum = vec3(0.0);

	vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;
	vec3 shadowViewNormal = mat3(shadowModelView) * worldNormal;
	vec3 shadowClipNormal = mat3(shadowProjection) * shadowViewNormal;

	int sampleCount = 0;

	for(int i = 0; i < samples; i++){
		vec2 offset = vogelDiscSample(i, samples, jitter);
		if(dot(shadowClipNormal.xy, normalize(offset)) < 0){
			continue;
		}

		shadowSum += sampleShadow(shadowClipPos + vec4(offset * penumbraWidth * shadowProjection[0][0], 0.0, 0.0), normal);
		sampleCount++;
	}
	shadowSum /= float(sampleCount);

	if(direct){
		vec3 undistortedShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos).xyz;
		vec3 cloudShadow = texture(colortex6, undistortedShadowScreenPos.xy).rgb;
		cloudShadow = mix(vec3(1.0), cloudShadow, smoothstep(0.1, 0.2, lightVector.y));
		shadowSum *= cloudShadow;
	}

	return shadowSum;
}

float getCaustics(vec3 feetPlayerPos){
	vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);
	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos);

	bool isWater = textureLod(shadowcolor1, shadowScreenPos.xy, 4).r > 0.1;

	if (!isWater){
		return 1.0;
	}

	float blockerDistanceRaw = max0(shadowScreenPos.z - texture(shadowtex0, shadowScreenPos.xy).r);
	float blockerDistance = blockerDistanceRaw * 255 * 2;

	if(blockerDistance < 0.1){
		return 1.0;
	}

	// float blockerDistance = max0(63 - (feetPlayerPos.y + cameraPosition.y));

	vec3 blockerPos = feetPlayerPos + lightVector * blockerDistance;
	vec3 waveNormal = waveNormal(feetPlayerPos.xz + cameraPosition.xz, vec3(0.0, 1.0, 0.0));
	vec3 refracted = refract(lightVector, waveNormal, rcp(1.33));

	vec3 oldPos = blockerPos;
	vec3 newPos = blockerPos + refracted * blockerDistance;

	float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
	float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

	return clamp01(oldArea / newArea);
}

vec3 getSunlight(vec3 feetPlayerPos, vec3 mappedNormal, vec3 faceNormal, float SSS, vec2 lightmap){
	#ifdef WORLD_THE_END
	lightmap.y = 1.0;
	#endif

	float faceNoL = NoLSafe(faceNormal);
	float NoL = NoLSafe(mappedNormal) * step(0.00001, faceNoL);

	float lightmapShadow = smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y);
	float lightmapScatter = mix(NoL, pow2(NoL / 2 + 0.5), SSS) * lightmapShadow;

	#ifdef SHADOWS
		vec3 bias = getShadowBias(feetPlayerPos, mat3(gbufferModelViewInverse) * faceNormal, faceNoL, lightmap.y);
		vec4 shadowClipPos = getShadowClipPos(feetPlayerPos + bias);

		float distFade = max(
			max2(abs(shadowClipPos.xy)),
			mix(1.0, 0.55, smoothstep(0.33, 0.8, lightVector.y)) * dot(shadowClipPos.xz, shadowClipPos.xz) * rcp(pow2(shadowDistance))
		);

		bool inShadowDistance = distFade < 1.0;

		float scatter = 0.0;
		vec3 shadow = vec3(0.0);

		if(inShadowDistance){
			float blockerDistance = 0.0;
			float penumbraWidth = 0.0;
			blockerDistance = getBlockerDistance(shadowClipPos, faceNormal, interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter + 1), BLOCKER_SEARCH_RADIUS + SSS);
			penumbraWidth = mix(MIN_PENUMBRA_WIDTH, MAX_PENUMBRA_WIDTH, blockerDistance);

			if(blockerDistance >= 0.9999){
				return sampleCloudShadow(shadowClipPos, faceNormal);
			}
			
			scatter = computeSSS(blockerDistance, SSS, faceNormal);
		
			
			shadow = computeShadow(shadowClipPos, penumbraWidth, faceNormal, SHADOW_SAMPLES, false, interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter));
		}


		if(distFade > 0.0){
			scatter = mix(scatter, lightmapScatter * lightmapShadow, smoothstep(0.8, 1.0, distFade));
			shadow = mix(shadow, vec3(lightmapShadow), smoothstep(0.8, 1.0, distFade));
		}
	#else
		vec3 shadow = vec3(lightmapShadow);
		float scatter = lightmapScatter * lightmapShadow;
	#endif

  vec3 sunlight = max(shadow * NoL, vec3(scatter));

	#if defined SHADOWS && defined CLOUD_SHADOWS
		sunlight *= sampleCloudShadow(shadowClipPos, faceNormal);
	#endif

	return sunlight;
}
#endif