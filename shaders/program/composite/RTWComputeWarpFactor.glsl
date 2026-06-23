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
layout(local_size_x = 256, local_size_y = 1) in;
const ivec3 workGroups = ivec3(1, 2, 1);

layout(r16f) uniform image2D colorimg4;

#include "/lib/common.glsl"
#include "/lib/util/rectilinearWarp.glsl"

shared float a[256];

void main() {

  // load values into shared memory
  a[gl_GlobalInvocationID.x] = max(0.0, texelFetch(colortex4, ivec2(gl_GlobalInvocationID.xy), 0).r);
  barrier();

  if(gl_GlobalInvocationID.x == 0){
    for(int i = 1; i < 256; i++){
      a[i] += a[i - 1];
    }
  }
  barrier();


  float warp = a[gl_GlobalInvocationID.x] / a[255] - float(gl_GlobalInvocationID.x) / 256.0;
  float previousWarp = texelFetch(colortex4, ivec2(gl_GlobalInvocationID.xy), 0).r;
  // warp = mix(warp, previousWarp, 0.1);
  imageStore(colorimg4, ivec2(gl_GlobalInvocationID.xy), vec4(warp, 0.0, 0.0, 0.0));
}
