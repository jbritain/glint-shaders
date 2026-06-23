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

#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/lib/common/settings.glsl"

#include "/lib/common/syntax.glsl"
#include "/lib/common/config.glsl"

#ifndef PHOTONICS_SHADER_INTERFACE
#include "/lib/common/uniforms.glsl"
#endif


#include "/lib/common/spaceConversions.glsl"

#ifndef GBUFFERS_VOXELS
#include "/lib/common/debug.glsl"
#endif

#include "/lib/material/materialIDs.glsl"

#include "/lib/util/voxy.glsl"

vec2 EB = vec2(eyeBrightness) / 240.0;
vec2 EBS = vec2(eyeBrightnessSmooth) / 240.0;
float worldTimeCounter = ((worldTime / 20.0) + (worldDay * 1200.0));

// https://gist.github.com/Reedbeta/e8d3817e3f64bba7104b8fafd62906df
vec3 sRGBToLinear(vec3 rgb) {
  return mix(pow((rgb + 0.055) * (1.0 / 1.055), vec3(2.4)),
             rgb * (1.0/12.92),
             lessThanEqual(rgb, vec3(0.04045)));
}

vec3 linearToSRGB(vec3 rgb) {
  return mix(1.055 * pow(rgb, vec3(1.0 / 2.4)) - 0.055,
             rgb * 12.92,
             lessThanEqual(rgb, vec3(0.0031308)));
}

#ifndef GBUFFERS_VOXY
layout(std430, binding = 0) buffer environmentData {
  vec3 sunlightColor;
  vec3 skylightColor;
  vec3 weatherSkylightColor;
  float averageLuminanceSmooth;
  // float exposure;
};
#endif

#endif