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
const ivec3 workGroups = ivec3(2, 2, 1);

layout(r16f) uniform image2D colorimg4;

#include "/lib/common.glsl"

void main() {
  bool vertical = gl_GlobalInvocationID.y == 1; // store vertical in second row

  uint maxWeight = 0;
  for (int x = 0; x < 256; x++) {
    maxWeight = max(
      maxWeight,
      texelFetch(
        shadowImportanceMapTex,
        ivec2(
          vertical
            ? x
            : gl_GlobalInvocationID.x,
          vertical
            ? gl_GlobalInvocationID.x
            : x
        ),
        0
      ).r
    );
  }

  imageStore(
    colorimg4,
    ivec2(gl_GlobalInvocationID.xy),
    vec4(maxWeight, 0.0, 0.0, 0.0) / 100
  );
}
