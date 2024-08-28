#ifndef GET_SUNLIGHT_INCLUDE
#define GET_SUNLIGHT_INCLUDE

#include "/lib/lighting/shadowBias.glsl"
#include "/lib/textures/blueNoise.glsl"

vec4 noise;

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

	float NoL = clamp01(dot(normal, normalize(shadowLightPosition)));

	if(NoL > -0.00001){
		return 0.0;
	}

	float s = 1.0 / (SSS * 0.06);
	float z = blockerDistance * 255;

	if(isnan(z)){
		z = 0.0;
	}

	float scatter = 0.25 * (exp(-s * z) + 3*exp(-s * z / 3));

	return clamp01(scatter);
}

vec3 sampleShadow(vec4 shadowClipPos, vec3 normal){
	vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos, normal).xyz;
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

float getBlockerDistance(vec4 shadowClipPos, vec3 normal){
	float range = float(BLOCKER_SEARCH_RADIUS) / (2 * shadowDistance);

	vec3 receiverShadowScreenPos = getShadowScreenPos(shadowClipPos, normal).xyz;
	float receiverDepth = receiverShadowScreenPos.z;

	float blockerDistance = 0;

	float blockerCount = 0;

	for(int i = 0; i < BLOCKER_SEARCH_SAMPLES; i++){
		vec2 offset = vogelDiscSample(i, BLOCKER_SEARCH_SAMPLES, noise.r);
		vec3 newShadowScreenPos = getShadowScreenPos(shadowClipPos + vec4(offset * range, 0.0, 0.0), normal).xyz;
		float newBlockerDepth = texture(shadowtex0, newShadowScreenPos).r;
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

vec3 computeShadow(vec4 shadowClipPos, float penumbraWidthBlocks, vec3 normal){
	if(penumbraWidthBlocks == 0.0){
		return(sampleShadow(shadowClipPos, normal));
	}

	float penumbraWidth = penumbraWidthBlocks / shadowDistance;
	float range = penumbraWidth / 2;

	vec3 shadowSum = vec3(0.0);
	int samples = SHADOW_SAMPLES;

	for(int i = 0; i < samples; i++){
		vec2 offset = vogelDiscSample(i, samples, noise.g);
		shadowSum += sampleShadow(shadowClipPos + vec4(offset * range, 0.0, 0.0), normal);
	}
	shadowSum /= float(samples);

	return shadowSum;
}

vec3 getSunlight(vec3 feetPlayerPos, vec3 mappedNormal, vec3 faceNormal, float SSS){
	vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	noise = blueNoise(screenPos);
  vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);

	// TODO: separate hardware samplers for PCSS
  float blockerDistance = getBlockerDistance(shadowClipPos, faceNormal);
	// float penumbraWidth = mix(MIN_PENUMBRA_WIDTH, MAX_PENUMBRA_WIDTH, blockerDistance);
	float penumbraWidth = 0.0;

	float scatter = computeSSS(blockerDistance, SSS, faceNormal);

	vec3 shadow = computeShadow(shadowClipPos, penumbraWidth, faceNormal);
  float NoL = NoLSafe(faceNormal) * NoLSafe(mappedNormal);

  return max(shadow * NoL, vec3(scatter));
}
#endif