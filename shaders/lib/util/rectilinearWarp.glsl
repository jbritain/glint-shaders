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

layout(r16f) writeonly uniform image2D rectilinearWarpMap;

vec2 getWarp(vec2 pos){
  return vec2(
    texture(colortex4, vec2(pos.x, 0.0)).r,
    texture(colortex4, vec2(pos.y, 1.0)).r
  );
}

#endif // RTW_GLSL