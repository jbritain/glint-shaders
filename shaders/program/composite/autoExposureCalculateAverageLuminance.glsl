/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
layout(local_size_x = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

#include "/lib/common.glsl"

void main() {
  int maxMipLevel = int(floor(log2(max(viewWidth, viewHeight))));
  averageLuminanceSmooth = textureLod(colortex0, vec2(0.5), maxMipLevel).a;
}
