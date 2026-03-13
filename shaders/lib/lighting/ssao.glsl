/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "/lib/util/dither.glsl"

float getSSAO(vec3 viewPos, vec3 worldNormal) {
  vec3 normal = mat3(gbufferModelView) * worldNormal;

  mat3 tbn;
  tbn[2] = normal;
  tbn[0] = normal.yzx;
  tbn[1] = cross(tbn[0], tbn[2]);

  float occlusion = 0.0;

  for (int i = 0; i < SSAO_SAMPLES; i++) {
    vec3 noise = blueNoise(floor(gl_FragCoord.xy), frameCounter, i);

    float cosTheta = sqrt(noise.x);
    float sinTheta = sqrt(1.0 - noise.x);
    float phi = 2.0 * PI * noise.y;

    vec3 sampleDir =
      tbn * vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
    vec3 worldSampleDir = mat3(gbufferModelViewInverse) * sampleDir;
    float radius = noise.z;

    vec3 offset = sampleDir * radius * SSAO_RADIUS;

    vec3 sampleViewPos = viewPos + offset;
    vec3 sampleScreenPos = viewSpaceToScreenSpace(sampleViewPos);
    float sampleDepth = screenSpaceToViewSpace(
      texture(depthtex0, sampleScreenPos.xy).r
    );

    float sampleOcclusion =
      float(sampleDepth >= sampleViewPos.z + 0.025) *
      smoothstep(0.0, 1.0, SSAO_RADIUS / abs(sampleDepth - sampleViewPos.z));
    occlusion += 1.0 - sampleOcclusion;
  }

  return occlusion / SSAO_SAMPLES;
}

#endif // SSAO_GLSL
