/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifdef csh

#include "/lib/util/cloudNoise.glsl"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
const ivec3 workGroups = ivec3(4, 4, 4);

layout(r8) uniform image3D highFrequencyCloudNoise;

void main() {
  vec3 texcoord = gl_GlobalInvocationID.xyz / 32.0;

  float noise;
  noise =
    1.0 -
    (0.625 * worleyNoise(texcoord, 4) +
      0.25 * worleyNoise(texcoord, 8) +
      0.125 * worleyNoise(texcoord, 12));
  imageStore(
    highFrequencyCloudNoise,
    ivec3(gl_GlobalInvocationID.xyz),
    vec4(noise, 0.0, 0.0, 0.0)
  );
}
