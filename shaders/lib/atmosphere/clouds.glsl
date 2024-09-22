#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/textures/blueNoise.glsl"
#include "/lib/atmosphere/common.glsl"
#include "/lib/atmosphere/sky.glsl"

float getCloudDensity(vec3 pos){

  float coverage = mix(0.09, 0.2, wetness);

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

  return clamp01(density * mix(0.2, 1.0, wetness));
}




// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateCloudLightEnergy(vec3 rayPos, float jitter, float costh){
  vec3 a = rayPos;
  vec3 b = rayPos;

  if(!rayPlaneIntersection(rayPos, lightVector, CLOUD_UPPER_PLANE_HEIGHT, b)){ 
    rayPlaneIntersection(rayPos, lightVector, CLOUD_LOWER_PLANE_HEIGHT, b);
  }

  if(b == rayPos) return vec3(0.0); // this should never happen

  if(distance(a, b) > CLOUD_SUBMARCH_LIMIT){
    b = a + normalize(b - a) * CLOUD_SUBMARCH_LIMIT;
  }

  vec3 increment = (b - a) / CLOUD_SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;

  subRayPos += increment * jitter;

  for(int i = 0; i < CLOUD_SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getCloudDensity(subRayPos) * length(increment);
    if(totalDensity >= 1.0){
      break;
    }
  }

  return multipleScattering(totalDensity, costh, CLOUD_G, CLOUD_EXTINCTION_COLOR, 32, CLOUD_DUAL_LOBE_WEIGHT) * clamp01((1.0 - exp(-totalDensity * 2)));
}

vec4 getClouds(vec4 color, vec3 playerPos, float depth, vec3 sunlightColor, vec3 skyLightColor){
  #ifndef CLOUDS
  return color;
  #endif

  vec3 worldDir = normalize(playerPos);

  // we trace from a to b
  vec3 a;
  vec3 b;

  vec3 firstFogPoint = b;

  if(!rayPlaneIntersection(cameraPosition, worldDir, CLOUD_LOWER_PLANE_HEIGHT, a)){
    if(worldDir.y > 0 && cameraPosition.y >= CLOUD_LOWER_PLANE_HEIGHT && cameraPosition.y <= CLOUD_UPPER_PLANE_HEIGHT){ // inside cloud, looking up
      a = cameraPosition;
    } else {
      return color;
    }
  }
  if(!rayPlaneIntersection(cameraPosition, worldDir, CLOUD_UPPER_PLANE_HEIGHT, b)){
    if(worldDir.y < 0 && cameraPosition.y >= CLOUD_LOWER_PLANE_HEIGHT && cameraPosition.y <= CLOUD_UPPER_PLANE_HEIGHT){ // inside cloud, looking down
      b = cameraPosition;
    } else {
      return color;
    }
  }

  a -= cameraPosition;
  b -= cameraPosition;

  float mu = clamp01(dot(worldDir, lightVector));

  if(length(a) > length(b)){ // for convenience, a will always be closer to the camera
    vec3 swap = a;
    a = b;
    b = swap;
  }

  if(length(playerPos) < length(b) && depth != 1.0){ // terrain in the way
    b = playerPos;

    if(b.y + cameraPosition.y < CLOUD_LOWER_PLANE_HEIGHT){ // neither the camera nor the terrain is in the cloud plane
      return color;
    }
  } 
  
  if(distance(a, b) > CLOUD_MARCH_LIMIT){ // limit how far we can march
    b = a + normalize(b - a) * CLOUD_MARCH_LIMIT;
  }

  a += cameraPosition;
  b += cameraPosition;

  int samples = int(mix(CLOUD_SAMPLES, CLOUD_SAMPLES * 2, sin(PI * 0.5 *abs(worldDir.y))));
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  vec3 totalTransmittance = vec3(1.0);
  vec3 lightEnergy = vec3(0.0);

  float jitter = blueNoise(texcoord, frameCounter).r;
  rayPos += increment * jitter;

  vec3 scatter = vec3(0.0);

  for(int i = 0; i < samples; i++, rayPos += increment){
    float density = getCloudDensity(rayPos) * length(increment);
    // density = mix(density, 0.0, smoothstep(CLOUD_MARCH_LIMIT * 0.5, CLOUD_MARCH_LIMIT, length(rayPos - cameraPosition)));

    vec3 transmittance = exp(-density * CLOUD_EXTINCTION_COLOR);

    if(density < 1e-6){
      continue;
    }

    if(firstFogPoint == b){
      firstFogPoint = rayPos;
    }

    float lightJitter = blueNoise(texcoord, frameCounter + i).r;

    vec3 lightEnergy = calculateCloudLightEnergy(rayPos, lightJitter, mu);
    vec3 radiance = lightEnergy * sunlightColor + skyLightColor;
    vec3 integScatter = radiance * (1.0 - clamp01(transmittance)) / CLOUD_EXTINCTION_COLOR;

    totalTransmittance *= transmittance;
    scatter += integScatter * totalTransmittance;

    if(max3(totalTransmittance) < 0.01){
      break;
    }
  }

  scatter = getAtmosphericFog(vec4(scatter, 1.0), firstFogPoint - cameraPosition).rgb;

  color.rgb = color.rgb * totalTransmittance;
  color.rgb += scatter;
  return color;
}

#endif