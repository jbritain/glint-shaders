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

const vec3 waterAbsorption = WATER_ABSORPTION_MOD * vec3(WATER_ABSORPTION_R, WATER_ABSORPTION_G, WATER_ABSORPTION_B) / 255;
const vec3 waterScattering = WATER_SCATTERING_MOD * vec3(WATER_SCATTERING_R, WATER_SCATTERING_G, WATER_SCATTERING_B) / 255;
#define WATER_DENSITY 1.0

const vec3 waterExtinction =
  vec3(waterAbsorption + waterScattering);

vec3 getWaterFog(vec3 color, vec3 start, vec3 end) {
  if(waterExtinction == vec3(0.0)){
    return color;
  }
  float dist = distance(start, end);
  vec3 dir = normalize(end - start);

  vec3 transmittance = exp(-dist * waterExtinction);
  vec3 scattering =
    (1.0 - transmittance) * (waterScattering / waterExtinction);
  scattering *=
    (sunlightColor * henyeyGreenstein(0.4, dot(dir, lightDir)) +
      skylightColor * isotropicPhase) *
    EBS.y;
  return fma(color, transmittance, scattering);
}

#endif // WATER_FOG_GLSL
