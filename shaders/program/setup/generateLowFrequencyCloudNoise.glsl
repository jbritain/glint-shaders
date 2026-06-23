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

#ifdef csh

#include "/lib/util/cloudNoise.glsl"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
const ivec3 workGroups = ivec3(8, 8, 8);

layout(rg8) uniform image3D lowFrequencyCloudNoise;

void main() {
  vec3 texcoord = gl_GlobalInvocationID.xyz / 64.0;

  vec2 noise;
  noise.x =
    1.0 -
    (0.625 * worleyNoise(texcoord, 8) +
      0.25 * worleyNoise(texcoord, 12) +
      0.125 * worleyNoise(texcoord, 24));
  noise.y = mix(
    perlinNoise(texcoord, 4) * 0.5 + 0.5,
    1.0,
    0.1 * (2.0 * worleyNoise(texcoord, 20) - 1.0)
  );
  imageStore(
    lowFrequencyCloudNoise,
    ivec3(gl_GlobalInvocationID.xyz),
    vec4(noise, 0.0, 0.0)
  );
}
