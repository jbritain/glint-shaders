/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
layout(local_size_x = 128, local_size_y = 1) in;
const ivec3 workGroups = ivec3(2, 1, 1);

layout(r16) uniform image2D colorimg4;

#include "/lib/common.glsl"

shared float a[256];

void main() {
  uint i = gl_GlobalInvocationID.x * 2 + 1;

  // load values into shared memory
  a[i - 1] = texelFetch(colortex4, ivec2(i - 1, gl_GlobalInvocationID.y), 0).r;
  a[i] = texelFetch(colortex4, ivec2(i, gl_GlobalInvocationID.y), 0).r;
  barrier();

  // upsweep

  uint mask = 1u;
  for(int d = 0; d < int(log2(256)); d++){
    barrier();
    if ((i & mask) != mask){
      continue;
    }

    a[i] += a[i - (mask >> 1) - 1];

    mask = (mask << 1) | 1u;
  }
  barrier();


  float totalSum = a[255];

  // downsweep
  a[255] = 0;
  mask = 256 - 1;
  for(int d = int(log2(256)) - 1; d >= 0; d -= 1){
    barrier();
    if ((i & mask) != mask){
      continue;
    }
    
    float t = a[i];
    a[i] += a[i - (mask >> 1) - 1];
    a[i - (mask >> 1) - 1] = t;

    mask >>= 1;
  }
  barrier();

  // shifting the entire list is impractical and wasteful
  // so I will place the last value at the start
  a[0] = totalSum;
  barrier();

  // calculate warp factor
  a[i] = a[i] / totalSum - (i - 1) / 256;
  a[(i + 1) % 128] = a[(i + 1) % 128] / totalSum - (i) / 256;

  // store values
  imageStore(colorimg4, ivec2(i - 1, gl_GlobalInvocationID.y), vec4(a[i]));
  imageStore(colorimg4, ivec2(i, gl_GlobalInvocationID.y), vec4(a[(i + 1) % 256]));
}
