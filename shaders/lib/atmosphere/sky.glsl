/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/atmosphere/atmosphere.glsl"

vec3 getSky(vec3 dir, bool includeSun){
  vec3 sky = getValFromSkyLUT(dir);

  if(includeSun && dot(dir, worldSunDir) > cos(sunAngularRadius)){
    sky += sunRadiance * getValFromTLUT(sunTransmittanceLUTTex, tLUTRes, atmospherePos, dir);
  }

  return sky;
}

#endif