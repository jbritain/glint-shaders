#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

#include "/lib/textures/blueNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/lighting/getSunlight.glsl"
#include "/lib/atmosphere/common.glsl"

#ifndef VOLUMETRIC_WATER
vec3 getWaterFog(vec3 color, vec3 frontPos, vec3 backPos, vec3 sunlightColor, vec3 skyLightColor){
  float dist = distance(frontPos, backPos);

  vec3 extinction = exp(-WATER_EXTINCTION * dist);

  color.rgb *= extinction;

  return color;
}
#else
//takes player space positions
vec3 getWaterFog(vec3 color, vec3 a, vec3 b, vec3 sunlightColor, vec3 skyLightColor){
  vec3 rayPos = a;

  vec3 increment = (b - a) / VOLUMETRIC_WATER_SAMPLES;
  float jitter = blueNoise(texcoord, frameCounter).r;
  // float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy));

  float cosTheta = clamp01(dot(normalize(increment), lightVector));
  float phase = dualHenyeyGreenstein(-0.97, 0.97, cosTheta, 0.7);

  rayPos += increment * jitter;

  vec3 totalTransmittance = vec3(1.0);
  vec3 scatter = vec3(0.0);

  for(int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++, rayPos += increment){
    float density = length(increment) * 1.0; // assume uniform water density

    vec3 transmittance = exp(-density * WATER_EXTINCTION);

    vec3 bias = getShadowBias(rayPos, lightVector, 1.0);
    vec4 shadowClipPos = getShadowClipPos(rayPos);

    float distanceBelowSeaLevel = max0(-1 * (rayPos.y - 63));
    vec3 skylightTransmittance = exp(-distanceBelowSeaLevel * WATER_EXTINCTION);

    shadowNoise.g = interleavedGradientNoise(floor(gl_FragCoord.xy), i + 1);
    vec3 radiance = computeShadow(shadowClipPos, 0.1, lightVector, 2, true) + skyLightColor * skylightTransmittance * EBS.y;
    radiance *= clamp01(phase) * sunlightColor;

    vec3 integScatter = (radiance - radiance * clamp01(transmittance)) / WATER_EXTINCTION;

    totalTransmittance *= transmittance;
    scatter += max0(integScatter) * totalTransmittance;

    if(length(totalTransmittance) < 0.01){
      break;
    }
  }

  color = color * clamp01(totalTransmittance) + scatter;

  return color;
}
#endif

#endif