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

layout(local_size_x = 16, local_size_y = 16) in;
const ivec3 workGroups = ivec3(32, 32, 1);

layout(rgba16f) uniform image2D skyCloudMap;

#define gl_FragCoord gl_GlobalInvocationID

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/planarClouds.glsl"
#include "/lib/util/packing.glsl"

void main() {
  ivec2 res = imageSize(skyCloudMap).xy;

  ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
  vec2 texcoord = clamp(gl_FragCoord.xy, vec2(0.0), vec2(res - 1)) / res;

  vec3 dir = decodeUnitVector(texcoord);

  vec4 clouds = getPlanarClouds(dir);
  vec4 volClouds = getVolumetricClouds(dir, true);

  clouds.rgb = fma(clouds.rgb, vec3(volClouds.a), volClouds.rgb);
  clouds.a *= volClouds.a;

  vec4 previousClouds = imageLoad(skyCloudMap, texelCoord);
  clouds = mix(clouds, previousClouds, 0.9);
  imageStore(skyCloudMap, texelCoord, clouds);
}

#endif
