#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

#include "/lib/textures/blueNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/lighting/getSunlight.glsl"
#include "/lib/atmosphere/common.glsl"

#ifndef VOLUMETRIC_WATER
vec3 getWaterFog(vec3 color, vec3 frontPos, vec3 backPos, vec3 sunlightColor, vec3 skyLightColor){
  float dist = distance(frontPos, backPos);

  vec3 extinction = exp(-clamp01(WATER_ABSORPTION + WATER_SCATTERING) * dist);

  color.rgb *= extinction;

  return color;
}
#else
//takes player space positions
vec3 getWaterFog(vec3 color, vec3 a, vec3 b, vec3 sunlightColor, vec3 skyLightColor){
  const vec3 waterExtinction = clamp01(WATER_ABSORPTION + WATER_SCATTERING);

  vec3 rayPos = a;

  vec3 worldDir = normalize(b - a);

  if(distance(a, b) > far){
    b = a + worldDir * far;
  }

  vec3 increment = (b - a) / VOLUMETRIC_WATER_SAMPLES;
  float jitter = blueNoise(texcoord, frameCounter).r;
  // float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy));

  float cosTheta = clamp01(dot(normalize(increment), lightVector));

  rayPos += increment * jitter;

  vec3 totalTransmittance = vec3(1.0);
  vec3 scatter = vec3(0.0);

  for(int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++, rayPos += increment){
    float density = length(increment) * 1.0; // assume uniform water density

    vec3 transmittance = exp(-density * waterExtinction);

    vec4 shadowClipPos = getShadowClipPos(rayPos);

    float distFade = max(
			max2(abs(shadowClipPos.xy)),
			mix(1.0, 0.55, smoothstep(0.33, 0.8, lightVector.y)) * dot(shadowClipPos.xz, shadowClipPos.xz) * rcp(pow2(shadowDistance))
		);

    float distanceBelowSeaLevel = max0(-1 * (rayPos.y - 63));
    vec3 skylightTransmittance = exp(-distanceBelowSeaLevel * waterExtinction);

    vec3 radiance = computeShadow(shadowClipPos, 0.1, lightVector, 2, true, interleavedGradientNoise(floor(gl_FragCoord.xy), i + 1)) * sunlightColor + skyLightColor * skylightTransmittance * EBS.y;
    radiance = mix(radiance, skylightTransmittance * sunlightColor, distFade);

    vec3 integScatter = (radiance - radiance * clamp01(transmittance)) / waterExtinction;

    totalTransmittance *= transmittance;
    scatter += max0(integScatter) * totalTransmittance;


    if(length(totalTransmittance) < 0.01){
      break;
    }
  }

  vec3 phase = henyeyGreenstein(0.6, cosTheta) * WATER_SCATTERING;

  scatter *= phase;

  color = color * clamp01(totalTransmittance) + scatter;

  return color;
}
#endif

#endif