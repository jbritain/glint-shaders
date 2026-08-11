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

#ifndef CLOUD_SHADOWS_GLSL
#define CLOUD_SHADOWS_GLSL

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/planarClouds.glsl"

float getCloudShadow(vec3 rayPos) {
  float shadow = 1.0;

  rayPos += cameraPosition;
  #ifdef VOLUMETRIC_CLOUDS
  if (
    rayPos.y > VOLUMETRIC_CLOUDS_BASE_ALTITUDE ||
    rayPlaneIntersection(
      rayPos,
      worldLightDir,
      float(VOLUMETRIC_CLOUDS_BASE_ALTITUDE),
      rayPos
    )
  ) {
    shadow = exp(-cloudExtinction * getVolumetricCloudOpticalDepth(
      rayPos,
      worldLightDir,
      0.0
    ).r);
  }
  #endif

  shadow = mix(1.0, shadow, smoothstep(0.0, 0.2, worldLightDir.y));

  return shadow;

}

#endif // CLOUD_SHADOWS_GLSL
