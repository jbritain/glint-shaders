/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef WATER_PARALLAX_INCLUDE
#define WATER_PARALLAX_INCLUDE

#define WATER_PARALLAX_SAMPLES 32

#include "/lib/util/spaceConversions.glsl"
#include "/lib/textures/blueNoise.glsl"

// this code worked first try
// the scope of my engineering genius literally knows no bounds

vec3 getWaterParallaxNormal(vec3 viewPos, vec3 faceNormal, float jitter){

  vec3 playerPos = mat3(gbufferModelViewInverse) * viewPos;
  vec3 worldFaceNormal = mat3(gbufferModelViewInverse) * faceNormal;

  #ifdef WATER_PARALLAX
    // we know no wave is ever more than WAVE_DEPTH above the surface
    // so we shift the ray forwards until it is WAVE_DEPTH above the surface
    float fractionalDistance;
    fractionalDistance = (abs(playerPos.y) - WAVE_DEPTH) / abs(playerPos.y);
    vec3 origin = playerPos * fractionalDistance;

    vec3 increment = (playerPos - origin) / float(WATER_PARALLAX_SAMPLES);

    bool intersect = false;

    vec3 rayPos = origin;

    rayPos += increment * jitter;

    for(int i = 0; i < WATER_PARALLAX_SAMPLES; i++){
      float waveHeight = waveHeight(rayPos.xz + cameraPosition.xz) + playerPos.y;

      if((playerPos.y < 0) == (rayPos.y < waveHeight)){
        return waveNormal(rayPos.xz + cameraPosition.xz, worldFaceNormal);
      }

      rayPos += increment;
    }

  #endif

  return waveNormal(playerPos.xz + cameraPosition.xz, worldFaceNormal);
}

#endif