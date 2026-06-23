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

layout(local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(128, 128, 1);

layout(r8) uniform image2D cloudCoverage;

void main() {
  vec3 texcoord = vec3(gl_GlobalInvocationID.xy / 1024.0, 0.0);

  float coverage =
    0.625 * worleyNoise(texcoord, 64) +
    0.25 * worleyNoise(texcoord, 128) +
    0.125 * (1.0 - worleyNoise(texcoord, 256)) +
    0.0625 * (1.0 - worleyNoise(texcoord, 512));

  coverage *=
    pow(clamp(perlinNoise(texcoord, 16) * 0.5 + 0.5, 0.0, 1.0), 2.0) * 0.3 +
    0.7;

  float height = pow(perlinNoise(texcoord, 32) * 0.5 + 0.5, 1.5) * 1.8 + 0.2;

  imageStore(
    cloudCoverage,
    ivec2(gl_GlobalInvocationID.xy),
    vec4(coverage, height, 0.0, 0.0)
  );
}
