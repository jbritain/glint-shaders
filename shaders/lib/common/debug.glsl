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

#ifndef DEBUG_GLSL
#define DEBUG_GLSL

#if defined DEBUG_ENABLE && defined fsh
layout(rgba8) uniform image2D debug;

void show(vec4 x) {
  imageStore(debug, ivec2(gl_FragCoord.xy), x);
}

#else
void show(vec4 x) {}
#endif

void show(vec3 x) {
  show(vec4(x, 1.0));
}

void show(vec2 x) {
  show(vec3(x, 0.0));
}

void show(float x) {
  show(vec3(x));
}

void show(bool x) {
  show(float(x));
}

void show(bvec2 x) {
  show(vec2(x));
}

void show(bvec3 x) {
  show(vec3(x));
}

void show(bvec4 x) {
  show(vec4(x));
}

#endif // DEBUG_GLSL
