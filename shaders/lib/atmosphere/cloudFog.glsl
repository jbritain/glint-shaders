/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/textures/cloudNoise.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/textures/blueNoise.glsl"
#include "/lib/atmosphere/common.glsl"
#include "/lib/lighting/getSunlight.glsl"
#include "/lib/atmosphere/clouds.glsl"

#define FOG_MARCH_LIMIT far
#define FOG_SUBMARCH_LIMIT 150.0

#define FOG_EXTINCTION vec3(0.8, 0.8, 1.0)
#define FOG_SAMPLES 5
#define FOG_SUBSAMPLES 4
#define FOG_DUAL_LOBE_WEIGHT 0.7
#define FOG_G 0.85

#define FOG_LOWER_HEIGHT 63
float FOG_UPPER_HEIGHT = mix(103.0, CUMULUS_LOWER_HEIGHT, wetness);

#define FOG_EXTINCTION_COLOR vec3(0.8, 0.8, 1.0)

float getFogDensity(vec3 pos){
  float fogFactor = 0.0;
  if(worldTime < 2000){
    fogFactor = 1.0 - smoothstep(0, 2000, worldTime) * 0.8;
  } else if (worldTime > 12000){
    fogFactor = smoothstep(12000, 14000, worldTime) * 0.8;
  }
  fogFactor += 0.2;
  
  fogFactor += wetness;
  
  
  float heightFactor = 1.0 - pow2(smoothstep(FOG_LOWER_HEIGHT, FOG_UPPER_HEIGHT, pos.y));

  fogFactor *= 0.01;

  fogFactor *= heightFactor;

  fogFactor = mix(fogFactor, fogFactor * 2.0, thunderStrength);

  // float distanceFactor = smoothstep(far / 2, far, length(pos.xz - cameraPosition.xz));

  // fogFactor = mix(fogFactor, 0.1 * heightFactor, distanceFactor);

  

  return fogFactor;
}


// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateFogLightEnergy(vec3 rayPos, float jitter, float costh){
  vec3 a = rayPos;
  vec3 b = rayPos;

  vec4 shadowClipPos = getShadowClipPos(rayPos - cameraPosition);
  vec3 sunlight = computeShadow(shadowClipPos, 0.1, lightVector, 2, true);

  if(sunlight == vec3(0.0)){
    return vec3(0.0);
  }

  if(!rayPlaneIntersection(rayPos, lightVector, FOG_LOWER_HEIGHT, b)){ 
    rayPlaneIntersection(rayPos, lightVector, FOG_UPPER_HEIGHT, b);
  }

  if(b == rayPos) return vec3(0.0); // this should never happen


  if(distance(a, b) > FOG_SUBMARCH_LIMIT){
    b = a + normalize(b - a) * FOG_SUBMARCH_LIMIT;
  }

  vec3 increment = (b - a) / FOG_SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;


  subRayPos += increment * jitter;

  for(int i = 0; i < FOG_SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getFogDensity(subRayPos) * length(increment);
  }

  return max0(multipleScattering(totalDensity, costh, -FOG_G, FOG_G, FOG_EXTINCTION, 1, FOG_DUAL_LOBE_WEIGHT, 0.9, 0.8, 0.1) * clamp01((1.0 - exp(-totalDensity * 2))) * sunlight);
}

vec3 getCloudFog(vec3 a, vec3 b, float depth, vec3 sunlightColor, vec3 skyLightColor, out vec3 transmit){
  transmit = vec3(1.0);
  #ifndef CLOUD_FOG
  return vec3(0.0);
  #endif

  if(getFogDensity(vec3(0.0, FOG_LOWER_HEIGHT, 0.0)) == 0.0){
    return vec3(0.0);
  }

  vec3 worldDir = normalize(b - a);

  float mu = clamp01(dot(worldDir, lightVector));

  vec3 oldB = b + cameraPosition;

  if(distance(a, b) > FOG_MARCH_LIMIT){ // limit how far we can march
    b = a + normalize(b - a) * FOG_MARCH_LIMIT;
  }
  a += cameraPosition;
  b += cameraPosition;

  if(depth == 1.0 && worldDir.y > 0.0 && b.y > FOG_UPPER_HEIGHT){
    // we need to shift B towards A so that the y is equal to the upper height
    float distanceAboveFog = abs(b.y - FOG_UPPER_HEIGHT);

    vec3 scaleDir = -worldDir;
    scaleDir /= scaleDir.y; // make the y component 1.0

    b += scaleDir * distanceAboveFog;
  }

  int samples = FOG_SAMPLES;
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  vec3 totalTransmittance = vec3(1.0);
  vec3 lightEnergy = vec3(0.0);

  float jitter = blueNoise(texcoord).r;
  rayPos += increment * jitter;

  vec3 scatter = vec3(0.0);

  for(int i = 0; i < samples; i++, rayPos += increment){
    float density = 0;


    density = getFogDensity(rayPos) * length(increment);
    // density = mix(density, 0.0, smoothstep(CLOUD_MARCH_LIMIT * 0.5, CLOUD_MARCH_LIMIT, length(rayPos - cameraPosition)));

    vec3 transmittance = exp(-density * FOG_EXTINCTION);

    if(density < 1e-6){
      continue;
    }

    float lightJitter = blueNoise(texcoord, i + 1).r;

    vec3 lightEnergy = calculateFogLightEnergy(rayPos, lightJitter, mu);
    vec3 radiance = lightEnergy * sunlightColor + skyLightColor * EBS.y;

    if(lightningBoltPosition != vec4(0.0)){
      vec3 worldLightningPos = lightningBoltPosition.xyz + cameraPosition;
      worldLightningPos.y = rayPos.y; // lightning is a column

      float lightningDistance = distance(rayPos, worldLightningPos);
      float potentialEnergy = pow(1.0 - clamp01(lightningDistance / 100.0), 12.0);
      float pseudoAttenuation = (1.0 - clamp01(density * 5.0));
      radiance += pseudoAttenuation * potentialEnergy * vec3(1.0, 1.0, 2.0);
    }

     vec3 integScatter = (radiance - radiance * clamp01(transmittance)) / FOG_EXTINCTION;

    totalTransmittance *= transmittance;
    scatter += integScatter * totalTransmittance;

    if(max3(totalTransmittance) < 0.01){
      break;
    }

    
  }
  transmit = totalTransmittance;
  return max0(scatter);
}

#endif