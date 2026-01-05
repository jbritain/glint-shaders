/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
layout(local_size_x = 256, local_size_y = 1) in;
const ivec3 workGroups = ivec3(1, 2, 1);

layout(r16) uniform image2D colorimg4;

#include "/lib/common.glsl"

shared float a[256];

void main() {

  // load values into shared memory
  a[gl_GlobalInvocationID.x] = max(0.0, texelFetch(colortex4, ivec2(gl_GlobalInvocationID.xy), 0).r) + 1000.0;
  barrier();

  if(gl_GlobalInvocationID.x == 0){
    for(int i = 1; i < 256; i++){
      a[i] += a[i - 1];
    }
  }
  barrier();


  float warp = a[gl_GlobalInvocationID.x] / a[255] - float(gl_GlobalInvocationID.x) / 256.0;
  imageStore(colorimg4, ivec2(gl_GlobalInvocationID.xy), vec4(warp));
}
