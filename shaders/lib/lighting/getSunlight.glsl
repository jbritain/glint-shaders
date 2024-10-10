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

vec4 shadowNoise;

vec2 vogelDiscSample(int stepIndex, int stepCount, float rotation) {
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

int getBlockerID(vec3 shadowScreenPos){
	vec4 blockerData = texture(shadowcolor1, shadowScreenPos.xy);
	int materialID = int(blockerData.x * 255 + 0.5) + 10000;
	return materialID;
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
	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos, normal).xyz;
  float transparentShadow = shadow2D(shadowtex0HW, shadowScreenPos).r;

  if(transparentShadow == 1.0){ // no shadow at all
		return vec3(1.0);
	}

  float opaqueShadow = shadow2D(shadowtex1HW, shadowScreenPos).r;

  if(opaqueShadow == 0.0){ // opaque shadow so don't sample transparent shadow colour
		return vec3(0.0);
	}

  vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);

	int blockerID = getBlockerID(shadowScreenPos);

	if(materialIsWater(blockerID)){
		float blockerDistanceRaw = max0(shadowScreenPos.z - texture(shadowtex0, shadowScreenPos.xy).r);
		float blockerDistance = blockerDistanceRaw * 255 * 2;

		#ifdef composite
		// shadowColorData.a = mix(shadowColorData.a, 0.0, 0.9);
		#endif

		vec3 extinction = exp(-WATER_EXTINCTION * blockerDistance) * (1.0 - shadowColorData.a);

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

float getBlockerDistance(vec4 shadowClipPos, vec3 normal){
	float range = BLOCKER_SEARCH_RADIUS;

	vec3 receiverShadowScreenPos = getShadowScreenPos(shadowClipPos, normal).xyz;
	float receiverDepth = receiverShadowScreenPos.z;

	float blockerDistance = 0;

	float blockerCount = 0;

	for(int i = 0; i < BLOCKER_SEARCH_SAMPLES; i++){
		vec2 offset = vogelDiscSample(i, BLOCKER_SEARCH_SAMPLES, shadowNoise.r) * shadowProjection[0][0];
		vec3 newShadowScreenPos = getShadowScreenPos(shadowClipPos + vec4(offset * range, 0.0, 0.0), normal).xyz;
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
vec3 computeShadow(vec4 shadowClipPos, float penumbraWidth, vec3 normal, int samples, bool direct){
	if(penumbraWidth == 0.0){
		return(sampleShadow(shadowClipPos, normal));
	}

	vec3 shadowSum = vec3(0.0);

	vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;
	vec3 shadowViewNormal = mat3(shadowModelView) * worldNormal;
	vec3 shadowClipNormal = mat3(shadowProjection) * shadowViewNormal;

	int sampleCount = 0;

	for(int i = 0; i < samples; i++){
		vec2 offset = vogelDiscSample(i, samples, shadowNoise.g);
		if(dot(shadowClipNormal.xy, normalize(offset)) < 0){
			continue;
		}

		shadowSum += sampleShadow(shadowClipPos + vec4(offset * penumbraWidth * shadowProjection[0][0], 0.0, 0.0), normal);
		sampleCount++;
	}
	shadowSum /= float(sampleCount);

	if(direct){
		vec3 undistortedShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos, normal).xyz;
		vec3 cloudShadow = texture(colortex6, undistortedShadowScreenPos.xy).rgb;
		cloudShadow = mix(vec3(1.0), cloudShadow, smoothstep(0.1, 0.2, lightVector.y));
		shadowSum *= cloudShadow;
	}

	return shadowSum;
}

vec3 getSunlight(vec3 feetPlayerPos, vec3 mappedNormal, vec3 faceNormal, float SSS, vec2 lightmap){
	#ifdef WORLD_THE_END
	lightmap.y = 1.0;
	#endif

	vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	shadowNoise = vec4(
		interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter),
		interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter + 1),
		0.0,
		0.0
	);

	float faceNoL = NoLSafe(faceNormal);
	float NoL = NoLSafe(mappedNormal) * step(0.00001, faceNoL);

	if(DH_MASK){
		float lightmapShadow = smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y);

		vec3 shadow = vec3(lightmapShadow);
		float scatter = mix(NoL, pow2(NoL / 2 + 0.5), SSS) * lightmapShadow;

		return max(shadow * NoL, vec3(scatter));
	}

	#ifdef SHADOWS

		vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);

		float taxicabDistance = max(abs(feetPlayerPos.x), abs(feetPlayerPos.z));
		float distFade = smoothstep(0.8 * shadowDistance, shadowDistance, taxicabDistance);

		bool inShadowDistance = distFade < 1.0;

		float blockerDistance = inShadowDistance ? getBlockerDistance(shadowClipPos, faceNormal) : 0.0;
		float penumbraWidth = inShadowDistance ? mix(MIN_PENUMBRA_WIDTH, MAX_PENUMBRA_WIDTH, blockerDistance) : 0.0;
		
		vec3 bias = inShadowDistance ? getShadowBias(feetPlayerPos, mat3(gbufferModelViewInverse) * faceNormal, faceNoL) : vec3(0.0);
		if(inShadowDistance){
			shadowClipPos = getShadowClipPos(feetPlayerPos + bias);
		}
		
		float scatter = inShadowDistance ? computeSSS(blockerDistance, SSS, faceNormal) : 0.0;

		vec3 shadow = inShadowDistance ? computeShadow(shadowClipPos, penumbraWidth, faceNormal, SHADOW_SAMPLES, false) : vec3(0.0);

		if(distFade > 0.0){
			float lightmapShadow = smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y);

			scatter = mix(scatter, mix(NoL, pow2(NoL / 2 + 0.5), SSS) * lightmapShadow, distFade);
			shadow = mix(shadow, vec3(lightmapShadow), distFade);
		}
	#else
		float lightmapShadow = smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y);

		vec3 shadow = vec3(lightmapShadow);
		float scatter = mix(NoL, pow2(NoL / 2 + 0.5), SSS) * lightmapShadow;
	#endif

  vec3 sunlight = max(shadow * NoL, vec3(scatter));

	#if defined SHADOWS && defined CLOUD_SHADOWS
		vec3 undistortedShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos, faceNormal).xyz;
		vec3 cloudShadow = texture(colortex6, undistortedShadowScreenPos.xy).rgb;
		cloudShadow = mix(vec3(1.0), cloudShadow, smoothstep(0.1, 0.2, lightVector.y));

		sunlight *= cloudShadow;
	#endif

	return sunlight;
}
#endif