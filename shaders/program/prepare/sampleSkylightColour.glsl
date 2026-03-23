/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#include "/lib/common.glsl"

#ifdef csh

#include "/lib/atmosphere/sky.glsl"

layout(local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(1, 1, 1);

shared vec3 values[64];

void main() {
  uint id = gl_GlobalInvocationID.x * 8 + gl_GlobalInvocationID.y;

  float cosTheta = gl_GlobalInvocationID.x / 8.0;
  float sinTheta = sqrt(1.0 - pow2(cosTheta));
  float phi = 2.0 * PI * gl_GlobalInvocationID.y / 8.0;

  vec3 dir = vec3(
    cos(phi) * sinTheta,
    sin(phi) * sinTheta,
    cosTheta
  );

  values[id] = getSky(dir, false) / 64.0;

  skylightColor = vec3(0.0);

  barrier();

  
  for(int i = 0; i < 64; i++){
    skylightColor += values[i] / PI;
  }
}

#endif
