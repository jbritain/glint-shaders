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

float getCloudShadow(vec3 rayPos) {
  float shadow = 1.0;

  vec3 dir = normalize(rayPos);

  rayPos += cameraPosition;
  #ifdef VOLUMETRIC_CLOUDS
  if (
    rayPlaneIntersection(
      rayPos,
      worldLightDir,
      mix(
        float(VOLUMETRIC_CLOUDS_BASE_ALTITUDE),
        float(VOLUMETRIC_CLOUDS_TOP_ALTITUDE),
        0.2
      ),
      rayPos
    )
  ) {
    vec2 coverageCoord = fract((rayPos.xz + getWind()) / 150000 + 0.5);
    vec2 coverageData = texture(cloudCoverageTex, coverageCoord).rg;
    float coverage = linearstep(0.5 * (1.0 - wetness), 0.7, coverageData.r);
    shadow *= pow3(1.0 - coverage); // I tried doing actual stuff with beer's law but this works quite well as is and is very cheap
  }
  #endif

  shadow = mix(1.0, shadow, smoothstep(0.0, 0.2, worldLightDir.y));

  return shadow;

}

#endif // CLOUD_SHADOWS_GLSL
