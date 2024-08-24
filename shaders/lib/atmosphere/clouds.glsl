#ifndef CLOUD_INCLUDE
#define CLOUD_INCLUDE

#include "/lib/textures/cloudNoise.glsl"

#define LOWER_PLANE_HEIGHT 128.0
#define UPPER_PLANE_HEIGHT 256.0

#define CLOUD_SHAPE_SCALE 1000
#define CLOUD_SHAPE_SCALE_2 2000
#define CLOUD_EROSION_SCALE 100
#define MIN_CLOUD_DENSITY 0.9

#define MARCH_LIMIT 1000.0
#define SUBMARCH_LIMIT 500.0

// blocks per second
#define CLOUD_SHAPE_SPEED 0.001
#define CLOUD_EROSION_SPEED 0.005

#define ABSORPTION 0.3
#define SUBMARCH_ABSORPTION 0.1
#define k 0.6
#define SAMPLES 30
#define SUBSAMPLES 10

float schlickPhase(float costh)
{
    return (1.0 - k * k) / (4.0 * PI * pow(1.0 - k * costh, 2.0));
}

float getDensity(vec3 pos){
  float shapeDensity = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * frameTimeCounter, 0.0, 0.0)).r;
  float shapeDensity2 = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE_2 + vec3(CLOUD_SHAPE_SPEED * frameTimeCounter, 0.0, 0.0)).r;
  float erosionDensity = cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * frameTimeCounter, 0.0, 0.0)).r;
  
  float density = clamp01(shapeDensity2 - 0.92);
  density = mix(density, clamp01(shapeDensity - 0.97), 0.3);
  density *= 10;
  density -= clamp01(erosionDensity - 0.6);

  float cloudCentreHeight = (LOWER_PLANE_HEIGHT + UPPER_PLANE_HEIGHT) / 2;
  float cloudPlaneHeight = (UPPER_PLANE_HEIGHT - LOWER_PLANE_HEIGHT);

  float densityFactor = abs(pos.y - cloudCentreHeight) / (cloudPlaneHeight / 2);
  density = mix(density, 0.0, densityFactor);

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
float subMarch(vec3 rayPos, float jitter){
  vec3 a = rayPos;
  vec3 b = rayPos;

  vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition); // what the fuck, why do I need to invert this

  if(!getCloudIntersection(rayPos, sunDir, UPPER_PLANE_HEIGHT, b)){ 
    getCloudIntersection(rayPos, sunDir, LOWER_PLANE_HEIGHT, b);
  }

  if(b == rayPos) return 0; // this should never happen

  b -= cameraPosition;

  if(length(b) > SUBMARCH_LIMIT){
    b = normalize(b) * SUBMARCH_LIMIT;
  }

  b += cameraPosition;

  vec3 increment = (b - a) / SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;

  subRayPos += increment * jitter;

  for(int i = 0; i < SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getDensity(subRayPos) * length(increment);
  }

  return exp(-totalDensity * SUBMARCH_ABSORPTION);
}

vec4 getClouds(vec3 playerPos, float depth, float jitter, vec3 sunlightColor, vec3 skyLightColor){
  vec3 worldDir = normalize(playerPos);

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

    if(b.y + cameraPosition.y < LOWER_PLANE_HEIGHT){ // neither the camera nor the terrain is in the cloud plane
      return vec4(0.0);
    }
  } else if(length(b) > MARCH_LIMIT){ // limit how far we can march
    b = normalize(b) * MARCH_LIMIT;
  }

  a += cameraPosition;
  b += cameraPosition;
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / SAMPLES;

  float transmittance = 1.0;
  vec3 lightEnergy = vec3(0.0);

  rayPos += increment * jitter;

  for(int i = 0; i < SAMPLES; i++, rayPos += increment){
    float density = getDensity(rayPos) * length(increment);

    density = mix(density, 0.0, smoothstep(MARCH_LIMIT * 0.5, MARCH_LIMIT, length(rayPos - cameraPosition)));

    if(density > 0){
      float lightTransmittance = subMarch(rayPos, jitter);

      float phase = schlickPhase(dot(worldDir, normalize(mat3(gbufferModelViewInverse) * sunPosition)));

      lightEnergy += density * length(increment) * transmittance * lightTransmittance * phase;
      transmittance *= exp(-density * length(increment) * ABSORPTION);

      if(transmittance < 0.01){
        break;
      }
    }
  }

  // made up lighting calculations that look decent ish
  vec3 ambientColor = mix(skyLightColor, sunlightColor, 0.2);
  vec3 cloudColor = lightEnergy * sunlightColor * 0.005 * ambientColor + skyLightColor;

  // transmittance = mix(1.0, transmittance, pow2(smoothstep(0.0, 0.3, worldDir.y)));

  return vec4(cloudColor, 1.0 - transmittance);
}

#endif