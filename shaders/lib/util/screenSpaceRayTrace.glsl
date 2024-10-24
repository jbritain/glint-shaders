/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef SCREEN_SPACE_RAY_TRACE_INCLUDE
#define SCREEN_SPACE_RAY_TRACE_INCLUDE

#include "/lib/util/spaceConversions.glsl"
#include "/lib/util/reproject.glsl"
#include "/lib/util.glsl"

#define BINARY_REFINEMENTS 6
#define BINARY_REDUCTION 0.5
#define THICKNESS 0.5

const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;

float getDepth(vec2 pos, bool previousFrame){
  if(previousFrame){
    return texelFetch(colortex4, ivec2(pos * vec2(viewWidth, viewHeight)), 0).a;
  } else {
    return texelFetch(depthtex2, ivec2(pos * vec2(viewWidth, viewHeight)), 0).r;
  }
  
}

void binarySearch(inout vec3 rayPos, vec3 rayDir, bool previousFrame){
  vec3 lastGoodPos = rayPos; // stores the last position we know was inside, in case we accidentally step back out
  for (int i = 0; i < BINARY_REFINEMENTS; i++){
    float depth = getDepth(rayPos.xy, previousFrame);
    float intersect = sign(depth - rayPos.z);
    lastGoodPos = intersect == 1.0 ? rayPos : lastGoodPos; // update last good pos if still inside
    
    rayPos += intersect * rayDir; // goes back if we're in geometry and forward if we're not
    rayDir *= BINARY_REDUCTION; // scale down the ray
  }
  rayPos = lastGoodPos;
}

// traces through screen space to find intersection point
// thanks, belmu!!
// https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
bool rayIntersects(vec3 viewOrigin, vec3 viewDir, int maxSteps, float jitter, bool refine, out vec3 rayPos, bool previousFrame){

  if(viewDir.z > 0.0 && viewDir.z >= -viewOrigin.z){
    return false;
  }

  rayPos = viewSpaceToScreenSpace(viewOrigin);
  if(previousFrame){
    rayPos = reproject(rayPos);
  }

  vec3 rayDir;
  rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir);
  if(previousFrame){
    rayDir = reproject(rayDir);
  }
  
  rayDir -= rayPos;
  rayDir = normalize(rayDir);

  float rayLength = min3(abs(sign(rayDir) - rayPos) / max(abs(rayDir), 0.00001));
  float stepLength = rayLength * rcp(float(maxSteps));

  vec3 rayStep = rayDir * stepLength;
  rayPos += rayStep * jitter + length(vec2(rcp(viewWidth), rcp(viewHeight))) * rayDir;

  float depthLenience = max(abs(rayStep.z) * 3.0, 0.02 / pow2(viewOrigin.z)); // Provided by DrDesten

  bool intersect = false;

  for(int i = 0; i < maxSteps; ++i, rayPos += rayStep){
    if(clamp01(rayPos) != rayPos) return false; // we went offscreen

    float depth = getDepth(rayPos.xy, previousFrame); // sample depth at ray position

    if(depth < rayPos.z && abs(depthLenience - (rayPos.z - depth)) < depthLenience && rayPos.z > handDepth){
      intersect = true;
      break;
    }
  }

  if(refine && intersect){
    binarySearch(rayPos, rayDir, previousFrame);
  }

  return intersect;
}
#endif