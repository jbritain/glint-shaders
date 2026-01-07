/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#include "/lib/common.glsl"

#ifdef csh

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(16, 16, 1);

layout(rgba16f) uniform image2D skyCloudMap;

#define gl_FragCoord gl_GlobalInvocationID

#include "/lib/atmosphere/clouds.glsl"
#include "/lib/util/packing.glsl"

void main() {
  ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
  float u =
    clamp(float(texelCoord.x), 0.0, skyViewLUTRes.x - 1.0) / skyViewLUTRes.x;
  float v =
    clamp(float(texelCoord.y), 0.0, skyViewLUTRes.y - 1.0) / skyViewLUTRes.y;

  vec2 texcoord = clamp(gl_FragCoord.xy, vec2(0.0), vec2(255.0)) / 256.0;

  vec3 dir = decodeUnitVector(texcoord);
  vec4 clouds = getClouds(dir, true);
  vec4 previousClouds = imageLoad(skyCloudMap, texelCoord);
  clouds = mix(clouds, previousClouds, 0.9);
  imageStore(skyCloudMap, texelCoord, clouds);
}

#endif
