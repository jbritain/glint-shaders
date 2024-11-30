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
    rayPos = reprojectScreen(rayPos);
  }

  vec3 rayDir;
  rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir);
  if(previousFrame){
    rayDir = reprojectScreen(rayDir);
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

    vec3 rayPos2 = rayPos + rayStep * 0.25;
    vec3 rayPos3 = rayPos + rayStep * 0.5;
    vec3 rayPos4 = rayPos + rayStep * 0.75;

    float depth = getDepth(rayPos.xy, previousFrame); // sample depth at ray position
    float depth2 = getDepth(rayPos2.xy, previousFrame);
    float depth3 = getDepth(rayPos3.xy, previousFrame);
    float depth4 = getDepth(rayPos4.xy, previousFrame);

    if(depth < rayPos.z && abs(depthLenience - (rayPos.z - depth)) < depthLenience && rayPos.z > handDepth){
      intersect = true;
      break;
    }
    if(clamp01(rayPos2) != rayPos2) return false; // we went offscreen
    if(depth2 < rayPos2.z && abs(depthLenience - (rayPos2.z - depth2)) < depthLenience && rayPos2.z > handDepth){
      
      intersect = true;
      rayPos = rayPos2;
      break;
    }
    if(clamp01(rayPos3) != rayPos3) return false; // we went offscreen
    if(depth3 < rayPos3.z && abs(depthLenience - (rayPos3.z - depth3)) < depthLenience && rayPos3.z > handDepth){
      
      intersect = true;
      rayPos = rayPos3;
      break;
    }
    if(clamp01(rayPos4) != rayPos4) return false; // we went offscreen
    if(depth4 < rayPos4.z && abs(depthLenience - (rayPos4.z - depth4)) < depthLenience && rayPos4.z > handDepth){
      intersect = true;
      rayPos = rayPos4;
      break;
    }
  }

  if(clamp01(rayPos) != rayPos) return false; // we went offscreen

  if(refine && intersect){
    binarySearch(rayPos, rayStep, previousFrame);
  }

  return intersect;
}
#endif