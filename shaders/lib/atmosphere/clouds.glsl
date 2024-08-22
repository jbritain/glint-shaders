#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"

#define LOWER_PLANE_HEIGHT 128.0
#define UPPER_PLANE_HEIGHT 160.0

#define CLOUD_SHAPE_SCALE 1
#define CLOUD_EROSION_SCALE 100
#define MIN_CLOUD_DENSITY 0.9

// blocks per second
#define CLOUD_SHAPE_SPEED 1
#define CLOUD_EROSION_SPEED 0.01

#define ABSORPTION 1.0

#define SAMPLES 10

float getDensity(vec3 pos){
  float density = clamp01(cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * frameTimeCounter, 0.0, 0.0)).r);
  density *= clamp01(cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * frameTimeCounter, 0.0, 0.0)).r - 0.8) * 0.2;
  // density = clamp01(density - MIN_CLOUD_DENSITY);
  return density;
}

bool getCloudIntersection(vec3 O, vec3 D, float height, inout vec3 point){
  vec3 N = vec3(0.0, sign(O.y - height), 0.0); // plane normal vector
  vec3 P = vec3(0.0, height, 0.0); // point on the plane

  float NoD = dot(N, D);
  if(NoD == 0.0){
    return false;
  }

  float t = dot(N, P - O)/NoD;
  if(t < 0){
    return false;
  }


  point = O + t*D;
  return true;
}

vec4 getClouds(vec3 worldDir, float jitter){
  // we trace from a to b
  vec3 a;
  vec3 b;

  if(!getCloudIntersection(cameraPosition, worldDir, LOWER_PLANE_HEIGHT, a)){
    if(worldDir.y > 0 && cameraPosition.y >= LOWER_PLANE_HEIGHT && cameraPosition.y <= UPPER_PLANE_HEIGHT){ // inside cloud, looking up
      a = cameraPosition;
    } else {
      return vec4(0.0);
    }
  }
  if(!getCloudIntersection(cameraPosition, worldDir, UPPER_PLANE_HEIGHT, b)){
    if(worldDir.y < 0 && cameraPosition.y >= LOWER_PLANE_HEIGHT && cameraPosition.y <= UPPER_PLANE_HEIGHT){ // inside cloud, looking down
      a = cameraPosition;
    } else {
      return vec4(0.0);
    }
  }

  vec3 cloudColor = vec3(5.0);
  
  // march from lower to upper intersection
  vec3 rayPos = a;
  vec3 increment = (b - a) / SAMPLES;

  float totalDensity = 0.0;

  rayPos += increment * jitter;

  for(int i = 0; i < SAMPLES; i++, rayPos += increment){
    totalDensity += getDensity(rayPos) * length(increment);
  }

  totalDensity = clamp01(totalDensity);
  float transmittance = 1 - exp(-totalDensity);

  return vec4(cloudColor, transmittance);
}

#endif