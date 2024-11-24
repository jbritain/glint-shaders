/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

#include "/lib/textures/blueNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/lighting/getSunlight.glsl"
#include "/lib/atmosphere/common.glsl"
#include "/lib/water/waveNormals.glsl"

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

    float distFade = pow5(
      max(
        clamp01(max2(abs(shadowClipPos.xy))),
        mix(
          1.0, 0.55, 
          smoothstep(0.33, 0.8, lightVector.y)
        ) * (dot(rayPos.xz, rayPos.xz) * rcp(pow2(shadowDistance)))
      )
    );

    vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos).xyz;

    float sunlight = step(shadowScreenPos.z, textureLod(shadowtex1, shadowScreenPos.xy, 2).r);

    vec4 waterShadowData = texture(shadowcolor1, shadowScreenPos.xy);

    float isWater = step(0.5, waterShadowData.r);

    float doWaterShadow = (sunlight + isWater) / 2.0;
    doWaterShadow = mix(doWaterShadow, 1.0, clamp01(distFade));

    vec3 radiance;

    float distanceBelowSeaLevel = max0(63.0 - rayPos.y);
    vec3 skylightTransmittance = exp(-distanceBelowSeaLevel * waterExtinction);

    if(doWaterShadow > 0.99){
      float distanceToOpaque = waterShadowData.b;
      float blockerDistanceRaw = max0(shadowScreenPos.z - texture(shadowtex0, shadowScreenPos.xy).r);
      float percentageIntoWater = blockerDistanceRaw / distanceToOpaque;

      float caustics = textureLod(shadowcolor1, shadowScreenPos.xy, floor(log2(shadowMapResolution) * (1.0 - percentageIntoWater))).g;
      

		  float blockerDistance = mix(blockerDistanceRaw * 255 * 2, distanceBelowSeaLevel / clamp01(dot(lightVector, vec3(0.0, 1.0, 0.0))), clamp01(distFade));
      vec3 extinction = exp(-clamp01(WATER_ABSORPTION + WATER_SCATTERING) * blockerDistance);
      radiance = extinction * sunlightColor * caustics;

      vec3 undistortedShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos).xyz;
      vec3 cloudShadow = texture(colortex6, undistortedShadowScreenPos.xy).rgb;
      cloudShadow = mix(vec3(1.0), cloudShadow, smoothstep(0.1, 0.2, lightVector.y));
      cloudShadow = mix(cloudShadow, vec3(1.0), clamp01(distFade));
      radiance *= cloudShadow;
    } else {
      radiance = vec3(0.0);
    }



    //vec3 radiance = computeShadow(shadowClipPos, 0.1, lightVector, 2, true, interleavedGradientNoise(floor(gl_FragCoord.xy), i + 1)) * sunlightColor;
    
    radiance = mix(radiance, sunlightColor * skylightTransmittance, distFade);
    radiance += skyLightColor * skylightTransmittance * EBS.y;

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