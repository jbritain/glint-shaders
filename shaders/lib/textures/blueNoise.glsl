/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef BLUE_NOISE_INCLUDE
#define BLUE_NOISE_INCLUDE

#include "/lib/util.glsl"

uniform sampler2D bluenoisetex;

#define BLUE_NOISE_RESOLUTION 1024


vec4 blueNoise(vec2 texcoord){
  ivec2 sampleCoord = ivec2(texcoord * vec2(viewWidth, viewHeight));
  sampleCoord = sampleCoord % ivec2(BLUE_NOISE_RESOLUTION);

  return texelFetch(bluenoisetex, sampleCoord, 0);
}

vec4 blueNoise(in vec2 texcoord, int frame){
  const float g = 1.6180339887498948482;
  float a1 = rcp(g);
  float a2 = rcp(pow2(g));

  vec2 offset = vec2(mod(0.5 + a1 * frame, 1.0), mod(0.5 + a2 * frame, 1.0));
  texcoord += offset;

  return blueNoise(texcoord);
}

#endif