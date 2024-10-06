#ifndef CLOUD_NOISE_INCLUDE
#define CLOUD_NOISE_INCLUDE

uniform sampler3D cloudshapenoisetex;
uniform sampler3D clouderosionnoisetex;

#define CLOUD_TYPE_CUMULUS 1.0
#define CLOUD_TYPE_STRATOCUMULUS 0.5
#define CLOUD_TYPE_STRATUS 0.0

#define CUMULUS_LOWER_HEIGHT 500.0
#define CUMULUS_UPPER_HEIGHT 700.0
#define CUMULUS_SAMPLES 25
#define CUMULUS_SUBSAMPLES 4

#define STRATOCUMULUS_LOWER_HEIGHT 1500.0
#define STRATOCUMULUS_UPPER_HEIGHT 1700.0
#define STRATOCUMULUS_SAMPLES 6
#define STRATOCUMULUS_SUBSAMPLES 4

#define STRATUS_LOWER_HEIGHT 1900.0
#define STRATUS_UPPER_HEIGHT 2100.0
#define STRATUS_SAMPLES 1
#define STRATUS_SUBSAMPLES 1

struct CloudWeather {
  float cloudType;
  float coverage;
  float precipitation;
};

float getRelativeHeight(float y, float cloudType){
  if(cloudType == CLOUD_TYPE_CUMULUS){
    return smoothstep(CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, y);
  } else if(cloudType == CLOUD_TYPE_STRATOCUMULUS){
    return smoothstep(STRATOCUMULUS_LOWER_HEIGHT, STRATOCUMULUS_UPPER_HEIGHT, y) * 0.5;
  } else if(cloudType == CLOUD_TYPE_STRATUS){
    return smoothstep(STRATUS_LOWER_HEIGHT, STRATUS_UPPER_HEIGHT, y) * 0.1;
  }
}

float cloudHeightDensity(vec3 p, CloudWeather weather){
  float density = 1.0;

  float relativeHeight = getRelativeHeight(p.y, weather.cloudType);

  if(relativeHeight <= 0.1){
    density = smoothstep(0.0, 0.1, relativeHeight);
  } else if (relativeHeight >= 0.7){
    density = smoothstep(0.8, 1.0, relativeHeight);
  } else {
    density = 1.0;
  }

  return density;
}

float cloudDensitySample(vec3 p, CloudWeather weather){
  float heightGradient = cloudHeightDensity(p, weather);

  vec4 lowFrequencyNoise = texture(cloudshapenoisetex, p / 4000.0);
  float lowFrequencyFBM = (
    lowFrequencyNoise.g * 0.625 +
    lowFrequencyNoise.b * 0.25 +
    lowFrequencyNoise.a * 0.125
  );

  float cloud = remap(lowFrequencyNoise.r, lowFrequencyFBM - 1.0, 1.0, 0.0, 1.0);

  if(cloud == 0.0){
    return 0.0;
  }

  cloud *= cloudHeightDensity(p, weather);
  
  cloud = remap(cloud, 1.0 - weather.coverage, 1.0, 0.0, 1.0);
  cloud *= weather.coverage;

  vec4 highFrequencyNoise = texture(clouderosionnoisetex, p / 100);
  float highFrequencyFBM = clamp01(
    highFrequencyNoise.r * 0.625 +
    highFrequencyNoise.g * 0.25 +
    highFrequencyNoise.b * 0.125
  );

  float relativeHeight = getRelativeHeight(p.y, weather.cloudType);

  float highFrequencyNoiseModifier = 0.35 * exp(-weather.coverage * 0.75) * mix(highFrequencyFBM, 1.0 - highFrequencyFBM, clamp01(relativeHeight * 10.0));

  cloud = remap(cloud, highFrequencyNoiseModifier, 1.0, 0.0, 1.0);
  // cloud = cloud * highFrequencyNoiseModifier * (1.0 - cloud);

  return clamp01(cloud);
}

#endif