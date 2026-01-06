/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#include "/lib/util/phaseFunctions.glsl"

#define WATER_ABSORPTION (vec3(0.3, 0.06, 0.04))
#define WATER_SCATTERING (vec3(0.01, 0.05, 0.03) * 0.1)
#define WATER_DENSITY 1.0

const vec3 waterExtinction = vec3(WATER_ABSORPTION + WATER_SCATTERING) * WATER_DENSITY;

vec3 getWaterFog(vec3 color, vec3 start, vec3 end){
  float dist = distance(start, end);
  vec3 dir = normalize(end - start);

  vec3 transmittance = exp(-dist * waterExtinction);
  vec3 scattering = (1.0 - transmittance) * (WATER_SCATTERING / waterExtinction) * sunlightColor;
  scattering *= henyeyGreenstein(0.4, dot(dir, lightDir)) * EBS.y;
  return fma(color, transmittance, scattering);
}

#endif // WATER_FOG_GLSL