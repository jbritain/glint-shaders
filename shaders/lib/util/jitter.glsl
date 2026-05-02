/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef JITTER_GLSL
#define JITTER_GLSL

ivec2 getJitterOffset(int resolutionFraction, int frame) {
  int x = frame % resolutionFraction;
  int y = frame / resolutionFraction % resolutionFraction;

  return ivec2(x, y);
}

#endif // JITTER_GLSL
