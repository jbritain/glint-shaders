/*
    Copyright (c) 2026 Josh Britain (jbritain)
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
  const float g = 1.32471795724474602596;
  float a1 = rcp(g);
  float a2 = rcp(pow2(g));

  return vec2(fract(0.5 + a1 * index), fract(0.5 + a2 * index));
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
  return blueNoise(texcoord + r2(i) * 128, frame);
}

vec2 vogelDisc(int stepIndex, int stepCount, float noise) {
  float rotation = noise * 2 * PI;
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

// https://www.shadertoy.com/view/7sfXDn
float bayer2(vec2 a) {
  a = floor(a);
  return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

#define bayer4(a) (bayer2(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer8(a) (bayer4(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer16(a) (bayer8(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer32(a) (bayer16(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer64(a) (bayer32(0.5 * (a)) * 0.25 + bayer2(a))

float animateBayer(float value, int frameIndex, int bayerIndex) {
  int totalFrames = bayerIndex * bayerIndex;
  float offset = float(frameIndex % totalFrames) / float(totalFrames);
  return fract(value + offset);
}

#endif // DITHER_GLSL
