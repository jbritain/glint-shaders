/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef CLOUD_SHADOWS_GLSL
#define CLOUD_SHADOWS_GLSL

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/planarClouds.glsl"

float getCloudShadow(vec3 pos) {
  #ifdef CLOUDS
  float shadow = 1.0;

  vec3 dir = normalize(pos);

  pos += cameraPosition;
  if (
    rayPlaneIntersection(
      pos,
      worldLightDir,
      mix(
        float(VOLUMETRIC_CLOUDS_BASE_ALTITUDE),
        float(VOLUMETRIC_CLOUDS_TOP_ALTITUDE),
        0.2
      ),
      pos
    )
  ) {
    vec2 windDir = vec2(0.0, 1.0);
    vec2 wind = windDir * worldTimeCounter;
    pos.xz += wind;
    float coverage = smoothstep(
      0.7 * (1.0 - wetness),
      1.0,
      texture(cloudcoveragetex, fract(pos.xz / 50000.0)).r
    );

    shadow *= pow3(1.0 - coverage); // I tried doing actual stuff with beer's law but this works quite well as is and is very cheap
  }

  shadow = mix(1.0, shadow, smoothstep(0.0, 0.2, worldLightDir.y));

  return shadow;
  #else
  return 1.0;
  #endif

}

#endif // CLOUD_SHADOWS_GLSL
