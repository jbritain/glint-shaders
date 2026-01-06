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

#include "/lib/util/misc.glsl"

#if defined WORLD_THE_NETHER
vec3 getSky(vec3 dir, bool includeSun){
  return pow(fogColor, vec3(1.0/2.2));
}
#else
#include "/lib/atmosphere/atmosphere.glsl"

// TODO: moon phases

vec3 getMoon(vec3 dir){

  float VoL = dot(dir, worldMoonDir);
  
  if(VoL <= cos(moonAngularRadius)){
    return vec3(0.0);
  }

  vec3 intersectPos = dir * raySphereIntersect(vec3(0.0), dir, worldMoonDir, moonAngularRadius);
  vec3 normal = normalize(intersectPos - worldMoonDir);

  float lat = atan(normal.x, normal.z) / TAU + 0.5;
  float lon = asin(normal.y) / PI + 0.5;

  return dot(normal, worldSunDir) * texture(moontex, vec2(lat, lon)).rgb * moonRadiance / PI;
}

vec3 getSky(vec3 dir, bool includeSun){
  vec3 sky = getValFromSkyLUT(dir);

  if(includeSun){
    vec3 transmittance = getValFromTLUT(sunTransmittanceLUTTex, tLUTRes, atmospherePos, dir);
    if(dot(dir, worldSunDir) > cos(sunAngularRadius)){
      sky += sunRadiance * transmittance;
    }
    sky += getMoon(dir) * transmittance;
  }

  return sky;
}
#endif

#endif