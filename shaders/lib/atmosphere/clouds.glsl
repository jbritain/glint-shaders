#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"

#define LOWER_PLANE_HEIGHT 128.0
#define UPPER_PLANE_HEIGHT 256.0

#define CLOUD_SHAPE_SCALE vec3(1000, 500, 1000)
#define CLOUD_EROSION_SCALE 100
#define MIN_CLOUD_DENSITY 0.9

// blocks per second
#define CLOUD_SHAPE_SPEED 0.005
#define CLOUD_EROSION_SPEED 0.01

#define ABSORPTION 0.1
#define SUBMARCH_ABSORPTION 0.1
#define k 0.65

#define SAMPLES 20
#define SUBSAMPLES 5

float schlickPhase(float costh)
{
    return (1.0 - k * k) / (4.0 * PI * pow(1.0 - k * costh, 2.0));
}

float getDensity(vec3 pos){
  float shapeDensity = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * frameTimeCounter, 0.0, 0.0)).r;
  float erosionDensity = cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * frameTimeCounter, 0.0, 0.0)).r;
  
  float density = clamp01(shapeDensity - 0.95) * 10;
  density *= clamp01(erosionDensity - 0.6) * 0.5 + 0.5;

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


// march from a ray position towards the sun to calculate how much light makes it there
float subMarch(vec3 rayPos){
  vec3 a = rayPos;
  vec3 b = rayPos;

  vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

  if(!getCloudIntersection(rayPos, sunDir, UPPER_PLANE_HEIGHT, b)){ 
    getCloudIntersection(rayPos, sunDir, LOWER_PLANE_HEIGHT, b);
  }

  if(b == rayPos) return 0; // this should never happen

  vec3 increment = (b - a) / SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;

  for(int i = 0; i < SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getDensity(subRayPos) * length(increment);
  }

  return exp(-totalDensity * SUBMARCH_ABSORPTION);
}

vec4 getClouds(vec3 worldDir, float jitter, vec3 sunlightColor, vec3 skyLightColor){
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
  
  // march from lower to upper intersection
  vec3 rayPos = a;
  vec3 increment = (b - a) / SAMPLES;

  float transmittance = 1.0;
  vec3 lightEnergy = vec3(0.0);

  rayPos += increment * jitter;

  for(int i = 0; i < SAMPLES; i++, rayPos += increment){
    float density = getDensity(rayPos) * length(increment);

    density = mix(density, 0.0, sqrt(clamp01(length(rayPos.xz - cameraPosition.xz) / 8000))); // distance fadeout

    if(density > 0){
      float lightTransmittance = subMarch(rayPos);

      float phase = schlickPhase(dot(worldDir, normalize(mat3(gbufferModelViewInverse) * shadowLightPosition)));

      lightEnergy += density * length(increment) * transmittance * lightTransmittance * phase;
      transmittance *= exp(-density * length(increment) * ABSORPTION);

      if(transmittance < 0.01){
        break;
      }
    }
  }

  vec3 cloudColor = lightEnergy * sunlightColor * 0.01 + skyLightColor;

  return vec4(cloudColor, 1.0 - transmittance);
}

#endif