/*
    Copyright (c) 2024 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net                                  
*/

#ifndef RTW_GLSL
#define RTW_GLSL

layout(std430, binding = 1) buffer rtwMapBuffer {
  float xWarpMap[256];
  float yWarpMap[256];
};

vec2 getWarp(vec2 pos){
  ivec2 floorPos = ivec2(floor(pos * 255));
  ivec2 ceilPos = ivec2(ceil(pos * 255));

  return mix(
    vec2(
      xWarpMap[floorPos.x],
      yWarpMap[floorPos.y]
    ),
    vec2(
      xWarpMap[ceilPos.x],
      yWarpMap[ceilPos.y]
    ),
    fract(pos * 255)
  );
}

#endif // RTW_GLSL