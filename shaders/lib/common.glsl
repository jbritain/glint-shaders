/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/lib/common/settings.glsl"

#include "/lib/common/syntax.glsl"
#include "/lib/common/config.glsl"

#include "/lib/common/uniforms.glsl"
#include "/lib/common/spaceConversions.glsl"

#include "/lib/common/debug.glsl"

#include "/lib/material/materialIDs.glsl"

#include "/lib/util/voxy.glsl"

vec2 EB = vec2(eyeBrightness) / 240.0;
vec2 EBS = vec2(eyeBrightnessSmooth) / 240.0;

#ifndef GBUFFERS_VOXY
layout(std430, binding = 0) buffer environmentData {
  vec3 sunlightColor;
  vec3 skylightColor;
};
#endif

#endif