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
#include "/lib/util/packing.glsl"

#ifdef csh

#include "/lib/atmosphere/sky.glsl"

layout(local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(1, 1, 1);

shared vec3 values[64];
shared vec3 valuesWithCloud[64];

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

  vec3 sky = getSky(dir, false);
  vec4 clouds = texture(skyCloudMapTex, encodeUnitVector(dir));

  values[id] = sky / (64 * PI);
  valuesWithCloud[id] = fma(sky, vec3(clouds.a), clouds.rgb) / (64 * PI);


  barrier();

  if(gl_GlobalInvocationID.x == 0){
    skylightColor = vec3(0.0);
    weatherSkylightColor = vec3(0.0);
    for(int i = 0; i < 64; i++){
      skylightColor += values[i];
      weatherSkylightColor += valuesWithCloud[i];
    }
  }

}

#endif
