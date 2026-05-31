/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef SCREEN_SPACE_RAYTRACE_GLSL
#define SCREEN_SPACE_RAYTRACE_GLSL

#define BINARY_REFINEMENTS 4
#define BINARY_REDUCTION 0.5

const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;

float getDepth(vec2 pos, sampler2D depthBuffer, int component) {
  return texelFetch(
    depthBuffer,
    ivec2(pos * vec2(viewWidth, viewHeight)),
    0
  )[component];
}

void binarySearch(
  inout vec3 rayPos,
  vec3 rayDir,
  sampler2D depthBuffer,
  int component
) {
  vec3 lastGoodPos = rayPos; // stores the last position we know was inside, in case we accidentally step back out
  for (int i = 0; i < BINARY_REFINEMENTS; i++) {
    float depth = getDepth(rayPos.xy, depthBuffer, component);
    float intersect = sign(depth - rayPos.z);
    lastGoodPos = intersect == 1.0 && depth < 1.0 ? rayPos : lastGoodPos; // update last good pos if still inside

    rayPos += intersect * rayDir; // goes back if we're in geometry and forward if we're not
    rayDir *= BINARY_REDUCTION; // scale down the ray
  }
  rayPos = lastGoodPos;
}

// traces through screen space to find intersection point
// thanks, belmu!!
// https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
bool rayIntersects(
  vec3 viewOrigin,
  vec3 viewDir,
  int maxSteps,
  float jitter,
  bool refine,
  out vec3 rayPos,
  sampler2D depthBuffer,
  int component,
  mat4 projection
) {
  if (viewDir.z > 0.0 && viewDir.z >= -viewOrigin.z) {
    return false;
  }

  vec2 res = textureSize(depthBuffer, 0).xy;

  rayPos = viewSpaceToScreenSpace(viewOrigin, projection);
  vec3 rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir, projection);

  float startZ = rayPos.z;

  rayDir -= rayPos;
  rayDir = normalize(rayDir);

  vec3 r = abs(sign(rayDir) - rayPos) / max(abs(rayDir), 0.00001);
  float rayLength = minVec3(r);
  float stepLength = rayLength * rcp(float(maxSteps));

  vec3 rayStep = rayDir * stepLength;
  rayPos +=
    rayStep * jitter + length(vec2(rcp(viewWidth), rcp(viewHeight))) * rayDir;

  float depthLenience = max(abs(rayStep.z) * 3.0, 0.02 / pow2(viewOrigin.z)); // Provided by DrDesten

  bool intersect = false;

  for (int i = 0; i < maxSteps; ++i) {
    if (clamp01(rayPos) != rayPos) return false; // we went offscreen

    float depth0 = getDepth(rayPos.xy, depthBuffer, component);
    float depth1 = getDepth(
      rayPos.xy + rayStep.xy * 0.25,
      depthBuffer,
      component
    );
    float depth2 = getDepth(
      rayPos.xy + rayStep.xy * 0.5,
      depthBuffer,
      component
    );
    float depth3 = getDepth(
      rayPos.xy + rayStep.xy * 0.75,
      depthBuffer,
      component
    );

    intersect =
      depth0 < rayPos.z &&
      abs(depthLenience - (rayPos.z - depth0)) < depthLenience &&
      rayPos.z > handDepth &&
      depth0 < 1.0;

    if (intersect) {
      break;
    }

    rayPos += rayStep * 0.25;

    intersect =
      depth1 < rayPos.z &&
      abs(depthLenience - (rayPos.z - depth1)) < depthLenience &&
      rayPos.z > handDepth &&
      depth1 < 1.0;

    if (intersect) {
      break;
    }

    rayPos += rayStep * 0.25;

    intersect =
      depth2 < rayPos.z &&
      abs(depthLenience - (rayPos.z - depth2)) < depthLenience &&
      rayPos.z > handDepth &&
      depth2 < 1.0;

    if (intersect) {
      break;
    }

    rayPos += rayStep * 0.25;

    intersect =
      depth3 < rayPos.z &&
      abs(depthLenience - (rayPos.z - depth3)) < depthLenience &&
      rayPos.z > handDepth &&
      depth3 < 1.0;

    if (intersect) {
      break;
    }

    rayPos += rayStep * 0.25;

  }

  if (refine && intersect) {
    binarySearch(rayPos, rayStep, depthBuffer, component);
  }

  rayPos.xy = (floor(rayPos.xy * res) + 0.5) / res;

  return intersect;
}

#endif // SCREEN_SPACE_RAYTRACE_GLSL
