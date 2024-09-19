#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/textures/blueNoise.glsl"

#define CLOUD_LOWER_PLANE_HEIGHT 192.0
#define CLOUD_UPPER_PLANE_HEIGHT 256.0

#define CLOUD_SHAPE_SCALE 1000
#define CLOUD_SHAPE_SCALE_2 2000
#define CLOUD_EROSION_SCALE 100

#define CLOUD_MARCH_LIMIT 1000.0
#define CLOUD_SUBMARCH_LIMIT 500.0

// blocks per second
#define CLOUD_SHAPE_SPEED 0.001
#define CLOUD_EROSION_SPEED 0.005

#define CLOUD_ABSORPTION 0.9
#define CLOUD_K 0.65
#define CLOUD_SAMPLES 50
#define CLOUD_SUBSAMPLES 4

vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

float schlickPhase(float costh)
{
    return (1.0 - CLOUD_K * CLOUD_K) / (4.0 * PI * pow(1.0 - CLOUD_K * costh, 2.0));
}

float getDensity(vec3 pos){

  float coverage = mix(0.1, 0.2, wetness);

  float shapeDensity = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  float shapeDensity2 = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE_2 + vec3(CLOUD_SHAPE_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  float erosionDensity = cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  
  float density = clamp01(shapeDensity2 - (1.0 - coverage));
  density = mix(density, clamp01(shapeDensity - (1.0 - coverage) - 0.05), 0.3);
  density *= 10;
  density -= clamp01(erosionDensity - 0.6);
  
  float cumulusCentreHeight = mix(CLOUD_LOWER_PLANE_HEIGHT, CLOUD_UPPER_PLANE_HEIGHT, 0.3); // widest part of our cumulus clouds

  float heightDenseFactor;

  if(pos.y <= cumulusCentreHeight){
    heightDenseFactor = smoothstep(CLOUD_LOWER_PLANE_HEIGHT, cumulusCentreHeight, pos.y);
  } else {
    heightDenseFactor = 1.0 - smoothstep(cumulusCentreHeight, CLOUD_UPPER_PLANE_HEIGHT, pos.y);
  }
  density = mix(density, 0.0, 1.0 - heightDenseFactor);

  return density * 0.7 + wetness * 0.3;
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

  if(!getCloudIntersection(rayPos, sunDir, CLOUD_UPPER_PLANE_HEIGHT, b)){ 
    getCloudIntersection(rayPos, sunDir, CLOUD_LOWER_PLANE_HEIGHT, b);
  }

  if(b == rayPos) return 0; // this should never happen

  b -= cameraPosition;

  if(length(b) > CLOUD_SUBMARCH_LIMIT){
    b = normalize(b) * CLOUD_SUBMARCH_LIMIT;
  }

  b += cameraPosition;

  vec3 increment = (b - a) / CLOUD_SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;

  float jitter = blueNoise(texcoord, 0).g;

  subRayPos += increment * jitter;

  for(int i = 0; i < CLOUD_SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getDensity(subRayPos) * length(increment);
    if(totalDensity >= 1.0){
      break;
    }
  }

  return clamp01(exp(-totalDensity * CLOUD_ABSORPTION)) * clamp01((1.0 - exp(-totalDensity * 2)));
}

vec4 getClouds(vec3 playerPos, float depth, vec3 sunlightColor, vec3 skyLightColor){
  #ifndef CLOUDS
  return vec4(0.0);
  #endif

  vec3 worldDir = normalize(playerPos);

  // we trace from a to b
  vec3 a;
  vec3 b;

  if(!getCloudIntersection(cameraPosition, worldDir, CLOUD_LOWER_PLANE_HEIGHT, a)){
    if(worldDir.y > 0 && cameraPosition.y >= CLOUD_LOWER_PLANE_HEIGHT && cameraPosition.y <= CLOUD_UPPER_PLANE_HEIGHT){ // inside cloud, looking up
      a = cameraPosition;
    } else {
      return vec4(0.0);
    }
  }
  if(!getCloudIntersection(cameraPosition, worldDir, CLOUD_UPPER_PLANE_HEIGHT, b)){
    if(worldDir.y < 0 && cameraPosition.y >= CLOUD_LOWER_PLANE_HEIGHT && cameraPosition.y <= CLOUD_UPPER_PLANE_HEIGHT){ // inside cloud, looking down
      b = cameraPosition;
    } else {
      return vec4(0.0);
    }
  }

  a -= cameraPosition;
  b -= cameraPosition;

  if(length(a) > length(b)){ // for convenience, a will always be closer to the camera
    vec3 swap = a;
    a = b;
    b = swap;
  }

  if(length(playerPos) < length(b) && depth != 1.0){ // terrain in the way
    b = playerPos;

    if(b.y + cameraPosition.y < CLOUD_LOWER_PLANE_HEIGHT){ // neither the camera nor the terrain is in the cloud plane
      return vec4(0.0);
    }
  } if(length(b) > CLOUD_MARCH_LIMIT){ // limit how far we can march
    b = normalize(b) * CLOUD_MARCH_LIMIT;
  }

  a += cameraPosition;
  b += cameraPosition;

  int samples = int(mix(CLOUD_SAMPLES, CLOUD_SAMPLES * 2, sin(PI * 0.5 *abs(worldDir.y))));
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  float totalTransmittance = 1.0;
  vec3 lightEnergy = vec3(0.0);

  float jitter = blueNoise(texcoord, 0).r;
  rayPos += increment * jitter;

  vec3 scatter = vec3(0.0);

  float phase = schlickPhase(dot(worldDir, sunDir));

  for(int i = 0; i < samples; i++, rayPos += increment){
    float density = getDensity(rayPos) * length(increment);

    // density = mix(density, 0.0, smoothstep(CLOUD_MARCH_LIMIT * 0.5, CLOUD_MARCH_LIMIT, length(rayPos - cameraPosition)));
    float transmittance = exp(-density * CLOUD_ABSORPTION);

    if(density < 1e-6){
      continue;
    }

    float lightTransmittance = subMarch(rayPos);
    vec3 luminance = sunlightColor * 10 * phase * lightTransmittance + skyLightColor * 5; // I do not like these numbers but they are what they are
    luminance /= 2.0;
    vec3 integScatter = luminance * (1.0 - clamp01(transmittance)) / CLOUD_ABSORPTION;

    totalTransmittance *= transmittance;
    scatter += integScatter * totalTransmittance;

    if(totalTransmittance < 0.01){
      break;
    }
  }
  return vec4(scatter, 1.0 - totalTransmittance);
}

#endif