#ifndef PUDDLES_INCLUDE
#define PUDDLES_INCLUDE

#include "/lib/textures/cloudNoise.glsl"

float getWetnessFactor(vec3 worldPos, float porosity, float depth, vec2 lightmap, vec3 normal){
  float puddleFactor = smoothstep(0.85, 0.95, texture(cloudshapenoisetex, worldPos * vec3(rcp(10.0), 0.0, rcp(10.0))).r);

  return puddleFactor * smoothstep(0.66, 1.0, lightmap.y) * dot(normal, vec3(0.0, 1.0, 0.0));
}

#endif