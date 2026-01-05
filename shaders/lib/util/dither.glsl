/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef DITHER_GLSL
#define DITHER_GLSL

vec2 r2(int index) {
    const float g = 1.6180339887498948482;
  float a1 = rcp(g);
  float a2 = rcp(pow2(g));

  return vec2(mod(0.5 + a1 * index, 1.0), mod(0.5 + a2 * index, 1.0));
}

// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
// adapted with help from balint and hardester
float interleavedGradientNoise(vec2 coord) {
  return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}

float interleavedGradientNoise(vec2 coord, int frame) {
  return interleavedGradientNoise(coord + r2(frame) * 128);
}

vec3 blueNoise(vec2 coord, int frame) {
  return texelFetch(bluenoisetex, ivec3(ivec2(coord) % 128, frame % 64), 0).rgb;
}

vec3 blueNoise(vec2 texcoord, int frame, int i) {
  return blueNoise(texcoord + r2(i), frame);
}

vec2 vogelDisc(int stepIndex, int stepCount, float noise) {
	float rotation = noise * 2 * PI;
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

#endif // DITHER_GLSL