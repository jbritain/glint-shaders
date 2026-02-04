/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/


#ifndef ATMOSPHERIC_FOG_GLSL
#define ATMOSPHERIC_FOG_GLSL

#include "/lib/atmosphere/atmosphere.glsl"

vec3 getAtmosphericFog(vec3 color, vec3 viewPos) {
  vec3 pos = mapAerialPerspectivePos(viewPos);
  vec4 fog = texture(aerialPerspectiveLUTTex, clamp01(pos));

  return color * fog.a + fog.rgb * EBS.y;
}

#endif