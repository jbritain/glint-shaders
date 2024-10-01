#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/textures/blueNoise.glsl"
#include "/lib/atmosphere/common.glsl"
#include "/lib/atmosphere/sky.glsl"

#define CUMULUS_DENSITY 0.2
const float CUMULUS_COVERAGE = mix(0.08, 0.13, wetness);
#define CUMULUS_LOWER_HEIGHT 500.0
#define CUMULUS_UPPER_HEIGHT 700.0
#define CUMULUS_SAMPLES 50
#define CUMULUS_SUBSAMPLES 4

#define ALTOCUMULUS_LOWER_HEIGHT 1500.0
#define ALTOCUMULUS_UPPER_HEIGHT 1600.0
#define ALTOCUMULUS_DENSITY 0.1
const float ALTOCUMULUS_COVERAGE = mix(0.08, 0.13, wetness);
#define ALTOCUMULUS_SAMPLES 25
#define ALTOCUMULUS_SUBSAMPLES 4

#define CIRRUS_DENSITY 0.001
const float CIRRUS_COVERAGE = mix(0.2, 1.0, wetness);
#define CIRRUS_LOWER_HEIGHT 1900.0
#define CIRRUS_UPPER_HEIGHT 2000.0
#define CIRRUS_SAMPLES 5
#define CIRRUS_SUBSAMPLES 1

#define CLOUD_SHAPE_SCALE 2342
#define CLOUD_SHAPE_SCALE_2 7573
#define CLOUD_EROSION_SCALE 234.426

#define CLOUD_DISTANCE 10000.0

// blocks per second
#define CLOUD_SHAPE_SPEED 0.001
#define CLOUD_EROSION_SPEED 0.005

#define CLOUD_EXTINCTION_COLOR vec3(1.0)
#define CLOUD_DUAL_LOBE_WEIGHT 0.7
#define CLOUD_G 0.6

float getCloudDensity(vec3 pos){

  float coverage = 0;
  float densityFactor = 0;
  float heightDenseFactor = 1.0;

  if(pos.y >= CUMULUS_LOWER_HEIGHT && pos.y <= CUMULUS_UPPER_HEIGHT){
    coverage = CUMULUS_COVERAGE;
    densityFactor = CUMULUS_DENSITY;

    float cumulusCentreHeight = mix(CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, 0.3); // widest part of our cumulus clouds

    if(pos.y <= cumulusCentreHeight){
      heightDenseFactor = smoothstep(CUMULUS_LOWER_HEIGHT, cumulusCentreHeight, pos.y);
    } else {
      heightDenseFactor = 1.0 - smoothstep(cumulusCentreHeight, CUMULUS_UPPER_HEIGHT, pos.y);
    }

  } else if(pos.y >= ALTOCUMULUS_LOWER_HEIGHT && pos.y <= ALTOCUMULUS_UPPER_HEIGHT){
    coverage = ALTOCUMULUS_COVERAGE;
    densityFactor = ALTOCUMULUS_DENSITY;

    float cumulusCentreHeight = mix(ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, 0.3); // widest part of our cumulus clouds

    if(pos.y <= cumulusCentreHeight){
      heightDenseFactor = smoothstep(ALTOCUMULUS_LOWER_HEIGHT, cumulusCentreHeight, pos.y);
    } else {
      heightDenseFactor = 1.0 - smoothstep(cumulusCentreHeight, ALTOCUMULUS_UPPER_HEIGHT, pos.y);
    }

  } else if (pos.y >= CIRRUS_LOWER_HEIGHT && pos.y <= CIRRUS_UPPER_HEIGHT){
    coverage = CIRRUS_COVERAGE;
    densityFactor = CIRRUS_DENSITY;
  } else {
    return 0;
  }

  float shapeDensity = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  float shapeDensity2 = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE_2 + vec3(CLOUD_SHAPE_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  float erosionDensity = cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * worldTimeCounter, 0.0, 0.0)).r;
  
  float density = clamp01(shapeDensity2 - (1.0 - coverage));
  // density = mix(density, clamp01(shapeDensity - (1.0 - coverage) - 0.05), 0.3);
  density *= 10;
  density -= clamp01(erosionDensity - 0.6);

  density = mix(density, 0.0, sin(PI * (1.0 - heightDenseFactor) / 2));

  return clamp01(density * densityFactor);
}


float getTotalDensityTowardsLight(vec3 rayPos, float jitter, float lowerHeight, float upperHeight, int samples){
  vec3 a = rayPos;
  vec3 b = rayPos;

  bool goingDown = lightVector.y < 0;
  bool belowLayer = rayPos.y < lowerHeight;
  if(goingDown != belowLayer) return 0.0;

  if(!rayPlaneIntersection(rayPos, lightVector, lowerHeight, b)){ 
    rayPlaneIntersection(rayPos, lightVector, upperHeight, b);
  }

  if(b == rayPos) return 0.0; // this should never happen

  vec3 increment = (b - a) / float(samples);

  vec3 subRayPos = a;
  float totalDensity = 0.0;

  subRayPos += increment * jitter;

  for(int i = 0; i < samples; i++, subRayPos += increment){
    totalDensity += getCloudDensity(subRayPos) * length(increment);
  }

  return totalDensity;
}

// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateCloudLightEnergy(vec3 rayPos, float jitter, float costh, int samples){
  float totalDensity = getTotalDensityTowardsLight(rayPos, jitter, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, samples);
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, samples);
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, samples);

  vec3 powder = clamp01((1.0 - exp(-totalDensity * 2 * CLOUD_EXTINCTION_COLOR)));

  return multipleScattering(totalDensity, costh, CLOUD_G, CLOUD_EXTINCTION_COLOR, 32, CLOUD_DUAL_LOBE_WEIGHT) * mix(2.0 * powder, vec3(1.0), costh * 0.5 + 0.5);
}

vec3 marchCloudLayer(vec3 playerPos, float depth, vec3 sunlightColor, vec3 skyLightColor, inout vec3 totalTransmittance, float lowerHeight, float upperHeight, int samples, int subsamples){
  vec3 worldDir = normalize(playerPos);

  // we trace from a to b
  vec3 a;
  vec3 b;

  vec3 firstFogPoint = b;

  if(!rayPlaneIntersection(cameraPosition, worldDir, lowerHeight, a)){
    if(worldDir.y > 0 && cameraPosition.y >= lowerHeight && cameraPosition.y <= upperHeight){ // inside cloud, looking up
      a = cameraPosition;
    } else {
      return vec3(0.0);
    }
  }
  if(!rayPlaneIntersection(cameraPosition, worldDir, upperHeight, b)){
    if(worldDir.y < 0 && cameraPosition.y >= lowerHeight && cameraPosition.y <= upperHeight){ // inside cloud, looking down
      b = cameraPosition;
    } else {
      return vec3(0.0);
    }
  }

  worldDir = normalize(a - b);

  a -= cameraPosition;
  b -= cameraPosition;

  float mu = dot(worldDir, lightVector);

  if(length(a) > length(b)){ // for convenience, a will always be closer to the camera
    vec3 swap = a;
    a = b;
    b = swap;
  }

  if(length(playerPos) < length(b) && depth != 1.0){ // terrain in the way
    b = playerPos;

    if(b.y + cameraPosition.y < lowerHeight){ // neither the camera nor the terrain is in the cloud plane
      return vec3(0.0);
    }
  }

  a += cameraPosition;
  b += cameraPosition;
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  vec3 lightEnergy = vec3(0.0);

  float jitter = blueNoise(texcoord).r;
  rayPos += increment * jitter;

  vec3 scatter = vec3(0.0);

  for(int i = 0; i < samples; i++, rayPos += increment){

    if(length(rayPos.xz - cameraPosition.xz) > CLOUD_DISTANCE) break;

    float density = getCloudDensity(rayPos) * length(increment);
    density = mix(density, 0.0, smoothstep(CLOUD_DISTANCE * 0.8, CLOUD_DISTANCE, length(rayPos.xz - cameraPosition.xz)));

    if(density < 1e-6){
      continue;
    }

    vec3 transmittance = exp(-density * CLOUD_EXTINCTION_COLOR);

    if(firstFogPoint == b){
      firstFogPoint = rayPos;
    }

    float lightJitter = blueNoise(texcoord, i).r;

    vec3 lightEnergy = calculateCloudLightEnergy(rayPos, lightJitter, mu, subsamples);
    vec3 radiance = lightEnergy * sunlightColor + skyLightColor;
    vec3 integScatter = radiance * (1.0 - clamp01(transmittance)) / CLOUD_EXTINCTION_COLOR;

    totalTransmittance *= transmittance;
    scatter += integScatter * totalTransmittance;

    if(max3(totalTransmittance) < 0.01){
      break;
    }
  }

  scatter = getAtmosphericFog(vec4(scatter, 1.0), (firstFogPoint - cameraPosition)).rgb;
  return scatter;
}

vec3 getClouds(vec3 playerPos, float depth, vec3 sunlightColor, vec3 skyLightColor, out vec3 transmit){
  transmit = vec3(1.0);
  #ifndef CLOUDS
  return vec3(0.0);
  #endif

  vec3 scatter = vec3(0.0);

  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skyLightColor, transmit, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, CUMULUS_SAMPLES, CUMULUS_SUBSAMPLES);
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skyLightColor, transmit, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, ALTOCUMULUS_SAMPLES, ALTOCUMULUS_SUBSAMPLES);
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skyLightColor, transmit, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, CIRRUS_SAMPLES, CIRRUS_SUBSAMPLES);


  return scatter;
}

#endif