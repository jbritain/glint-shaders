#ifndef AURORA_INCLUDE
#define AURORA_INCLUDE

#define AURORA_LOWER_HEIGHT 10000
#define AURORA_UPPER_HEIGHT 11000
#define AURORA_SAMPLES 10

#include "/lib/textures/cloudNoise.glsl"
#include "/lib/atmosphere/common.glsl"

float getAuroraDensity(vec3 worldPos){
  if(worldPos.y > AURORA_UPPER_HEIGHT || worldPos.y < AURORA_LOWER_HEIGHT) return 0;

  float density1 = texture(clouderosionnoisetex, vec3(worldPos.x / 32000, 0.001 * worldTimeCounter, worldPos.z / 32000)).r;
  float density2 = texture(clouderosionnoisetex, vec3((worldPos.x + 1257 * 0.001 * worldTimeCounter) / 32000, 0.01 * worldTimeCounter, (worldPos.z + 1896 * 0.01 * worldTimeCounter) / 32000)).r;

  return step(0.95, 1.0 - abs(density1 - density2));
}

//takes player space positions
vec3 getAurora(vec3 worldDir){
  vec3 a;
  vec3 b;

  if(!rayPlaneIntersection(cameraPosition, worldDir, AURORA_LOWER_HEIGHT, a)){
    if(worldDir.y > 0 && cameraPosition.y >= AURORA_LOWER_HEIGHT && cameraPosition.y <= AURORA_UPPER_HEIGHT){ // inside cloud, looking up
      a = cameraPosition;
    } else {
      return vec3(0.0);
    }
  }
  if(!rayPlaneIntersection(cameraPosition, worldDir, AURORA_UPPER_HEIGHT, b)){
    if(worldDir.y < 0 && cameraPosition.y >= AURORA_LOWER_HEIGHT && cameraPosition.y <= AURORA_UPPER_HEIGHT){ // inside cloud, looking down
      b = cameraPosition;
    } else {
      return vec3(0.0);
    }
  }

  vec3 increment = (b - a) / AURORA_SAMPLES;
  float jitter = blueNoise(texcoord, frameCounter).r;

  vec3 rayPos = a;
  rayPos += increment * jitter;

  vec3 totalLight;

  for(int i = 0; i < AURORA_SAMPLES; i++, rayPos += increment){
    totalLight += length(increment) * getAuroraDensity(rayPos) * vec3(0.0, 1e-4, 0.0);
  }

  return totalLight;
}

#endif