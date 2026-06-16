/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef RSM_GLSL
#define RSM_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/util/rectilinearWarp.glsl"

vec3 getReflectiveShadowMap(vec3 playerPos, vec3 playerNormal) {
  vec3 shadowViewPos = transformView(playerPos, shadowModelView);
  // shadowViewPos.z -= 0.1;
  vec3 shadowViewNormal = mat3(shadowModelView) * playerNormal;
  vec3 shadowScreenPos = viewSpaceToScreenSpaceOrtho(
    shadowViewPos,
    shadowProjection
  );

  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).rg;

  const float radius = RSM_RADIUS / shadowDistance;
  const float areaPerSample = PI * pow2(RSM_RADIUS) / RSM_SAMPLES;

  vec3 irradiance = vec3(0.0);

  for (int i = 0; i < RSM_SAMPLES; i++) {
    float angle = fract(float(i) / RSM_SAMPLES + jitter.x) * TAU;
    float r = sqrt(float(i + jitter.y) / RSM_SAMPLES);
    vec2 offset = r * radius * vec2(sin(angle), cos(angle));

    vec3 offsetPos = shadowScreenPos + vec3(offset, 0.0);
    vec2 warpedPos = offsetPos.xy + getWarp(offsetPos.xy);

    offsetPos.z = texture(shadowtex0, warpedPos).r;
    vec3 samplePos = screenSpaceToViewSpaceOrtho(
      offsetPos,
      shadowProjectionInverse
    );
    vec4 sampleColor = texture(shadowcolor0, warpedPos);
    vec3 sampleFlux = sampleColor.rgb * sampleColor.a;
    sampleFlux = sRGBToLinear(sampleFlux);
    vec3 sampleNormal = texture(shadowcolor1, warpedPos).rgb * 2.0 - 1.0;
    sampleNormal.z = sqrt(1.0 - dot(sampleNormal.xy, sampleNormal.xy));

    vec3 dir = normalize(shadowViewPos - samplePos); // direction from fragment to sample

    // this bit taken from zombye's implementation in spectrum
    // the original paper does not properly account for the radius but this seems to work
    float sampleIn = 2.0 * r;
    float sampleOut = clamp01(dot(sampleNormal, dir)) / PI;
    float bounceIn = clamp01(dot(shadowViewNormal, -dir));
    const float bounceOut = 1.0 / PI;

    irradiance +=
      sampleIn *
      sampleOut *
      bounceIn *
      bounceOut *
      sampleFlux /
      pow2(distance(samplePos, shadowViewPos));

    // irradiance +=
    //   sampleFlux *
    //   max0(dot(dir, sampleNormal)) *
    //   max0(dot(-dir, shadowViewNormal));

  }

  // irradiance /= float(RSM_SAMPLES);
  // irradiance *= PI * RSM_RADIUS * RSM_BRIGHTNESS;
  irradiance *= areaPerSample;
  irradiance *= RSM_BRIGHTNESS;

  return irradiance;
}

#endif
