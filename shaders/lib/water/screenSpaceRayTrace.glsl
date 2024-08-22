#ifndef SCREEN_SPACE_RAY_TRACE_INCLUDE
#define SCREEN_SPACE_RAY_TRACE_INCLUDE

#include "/lib/util/spaceConversions.glsl"

#define BINARY_REFINEMENTS 4
#define BINARY_REDUCTION 0.5

void binarySearch(inout vec3 rayPos, vec3 rayDir){
  for (int i = 0; i < BINARY_REFINEMENTS; i++){
    rayPos += sign(texture(depthtex0, rayPos.xy).r - rayPos.z) * rayDir; // goes back if we're in geometry and forward if we're not
    rayDir *= BINARY_REDUCTION; // scale down the ray
  }
}

// traces through view space to find intersection point
// thanks, belmu!!
// https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3#file-raytracer-glsl-L31
bool traceRay(vec3 viewOrigin, vec3 viewDir, int maxSteps, float jitter, bool refine, out vec3 rayPos){
  rayPos = viewSpaceToScreenSpace(viewOrigin);
  vec3 rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir) - rayPos;
  rayDir *= min3((sign(rayDir) - rayPos) / rayDir); // set length of ray to trace to the nearest screen edge (I think)
  rayDir *= rcp(maxSteps); // split ray up into our steps

  bool intersect = false;

  rayPos += rayDir * jitter;

  for(int i = 0; i < maxSteps && !intersect; i++, rayPos += rayDir){
    if(clamp01(rayPos.xy) != rayPos.xy) return false; // we went offscreen

    float depth = texture(depthtex0, rayPos.xy).r; // sample depth at ray position

    intersect = rayPos.z > depth; // check if our ray is inside geometry
  }

  if(refine && intersect){
    binarySearch(rayPos, rayDir);
  }

  return intersect;
}
#endif