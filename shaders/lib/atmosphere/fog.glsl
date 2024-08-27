#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec4 getFog(vec4 color, vec3 playerPos){
  vec3 fog = getSky(normalize(playerPos), false);
  float fogFactor = length(playerPos) / far;
  fogFactor = clamp01(fogFactor - FOG_START) / (1.0 - FOG_START);
  fogFactor = pow(fogFactor, FOG_POWER);
  fogFactor = clamp01(fogFactor);
  color = mix(color, vec4(fog, 1.0), fogFactor);
  return color;
}

#endif