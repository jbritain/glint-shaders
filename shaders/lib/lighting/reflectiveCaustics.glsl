/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef REFLECTIVE_CAUSTICS_GLSL
#define REFLECTIVE_CAUSTICS_GLSL

#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/lighting/brdf.glsl"

float sampleReflectiveCaustics(vec3 playerPos, vec3 playerNormal) {
  vec3 reflectedDir = -reflect(-worldLightDir, vec3(0.0, 1.0, 0.0));
  vec3 reflectedDirShadow = mat3(shadowModelView) * reflectedDir;
  float diffuse = dot(reflectedDir, playerNormal);
  if (diffuse <= 0.0) {
    return 0.0;
  }

  float f = schlick(vec3(0.02), diffuse, 0.0).r;

  vec3 endPos = playerPos + reflectedDir * REFLECTIVE_CAUSTICS_RADIUS;

  vec3 startScreenPos = viewSpaceToScreenSpaceOrtho(
    transformView(playerPos, shadowModelView),
    shadowProjection
  );

  vec3 endScreenPos = viewSpaceToScreenSpaceOrtho(
    transformView(endPos, shadowModelView),
    shadowProjection
  );

  vec3 rayPos = startScreenPos;

  vec3 step = (endScreenPos - startScreenPos) / REFLECTIVE_CAUSTICS_STEPS;

  rayPos +=
    step * interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter);

  vec2 samplePos;
  float sampleDepth;

  for (int i = 0; i < REFLECTIVE_CAUSTICS_STEPS; i++) {
    samplePos = rayPos.xy + getWarp(rayPos.xy);
    sampleDepth = texture(shadowtex0, samplePos).r;
    float depthDifference = rayPos.z - sampleDepth;
    if (rayPos.z > sampleDepth && sampleDepth > startScreenPos.z) {
      if (i == REFLECTIVE_CAUSTICS_STEPS - 1) {
        float sampleIsWater = texture(shadowcolor2, samplePos).g;
        vec3 sampleNormal = texture(shadowcolor1, samplePos.xy).rgb * 2.0 - 1.0;
        sampleNormal.z = sqrt(1.0 - dot(sampleNormal.xy, sampleNormal.xy));

        vec3 halfway = normalize(vec3(0.0, 0.0, 1.0) - reflectedDirShadow);
        return pow(max0(dot(halfway, sampleNormal)), 2048) *
        diffuse *
        sampleIsWater *
        f;
        // return caustics.y * (1.0 - caustics.x);
      }
      step *= 0.5;
      rayPos -= step;

    } else {
      rayPos += step;
    }

  }
  return 0.0;
}

#endif
