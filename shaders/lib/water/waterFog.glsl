#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

#include "/lib/textures/blueNoise.glsl"
#include "/lib/lighting/getSunlight.glsl"

vec3 waterFog(vec3 color, vec3 frontPos, vec3 backPos){
  float dist = distance(frontPos, backPos);

  vec3 extinction = exp(-WATER_EXTINCTION * dist);

  color.rgb *= extinction;

  return color;
}

//takes player space positions
vec3 waterFog(vec3 color, vec3 a, vec3 b, vec3 sunlightColor, vec3 skyLightColor){
  vec3 rayPos = a;

  vec3 increment = (b - a) / VOLUMETRIC_WATER_SAMPLES;
  vec4 noise = blueNoise(texcoord, 0);
  float jitter = noise.r;

  float phase = (1.0 - WATER_K * WATER_K) / (4.0 * PI * pow(1.0 - WATER_K * dot(normalize(increment), lightVector), 2.0));

  rayPos += increment * jitter;

  vec3 totalTransmittance = vec3(1.0);
  vec3 scatter = vec3(0.0);

  for(int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++, rayPos += increment){
    float density = length(increment) * 1.0; // assume uniform water density

    vec3 transmittance = exp(-density * WATER_EXTINCTION);

    vec4 shadowClipPos = getShadowClipPos(rayPos);

    float distanceBelowSeaLevel = max0(-1 * (rayPos.y - 63));
    vec3 skylightTransmittance = exp(-distanceBelowSeaLevel * WATER_EXTINCTION);

    vec3 sunlight = computeShadow(shadowClipPos, 16.0, lightVector, 2) + skyLightColor * skylightTransmittance * EBS.y;
    sunlight *= clamp01(phase) * sunlightColor;

    vec3 integScatter = sunlight * (1.0 - clamp01(transmittance)) / WATER_EXTINCTION;

    totalTransmittance *= transmittance;
    scatter += integScatter * totalTransmittance;

    if(length(totalTransmittance) < 0.01){
      break;
    }
  }

  color = color * clamp01(totalTransmittance) + scatter;

  return color;
}

#endif