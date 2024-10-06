#ifndef CLOUD_NOISE_INCLUDE
#define CLOUD_NOISE_INCLUDE

uniform sampler3D cloudshapenoisetex;
uniform sampler3D clouderosionnoisetex;
uniform sampler2D weathertex;

#define CLOUD_BOTTOM_LAYER

#define CLOUD_BOTTOM_LOWER_HEIGHT 700.0
#define CLOUD_BOTTOM_UPPER_HEIGHT 1200.0

#define CLOUD_BOTTOM_SAMPLES 25
#define CLOUD_BOTTOM_SUBSAMPLES 6

struct CloudWeather {
  float cloudType;
  float coverage;
  float precipitation;
};

float getRelativeHeight(float y, float cloudType){
  return smoothstep(CLOUD_BOTTOM_LOWER_HEIGHT, CLOUD_BOTTOM_UPPER_HEIGHT, y);
}

float cloudHeightDensity(vec3 p, CloudWeather weather){
  float density = 1.0;

  float relativeHeight = getRelativeHeight(p.y, weather.cloudType);

  relativeHeight = remap(relativeHeight, 0.0, 1.0, 0.0, max(weather.cloudType, 1.0));

  // gradient
  if(relativeHeight <= 0.1){
    density = smoothstep(0.0, 0.1, relativeHeight);
  } else if (relativeHeight >= 0.7){
    density = smoothstep(0.8, 1.0, relativeHeight);
  } else {
    density = 1.0;
  }

  return density;
}

float cloudDensitySample(vec3 p){
  vec3 weatherData = texture(weathertex, p.xz / 4000).rgb;
  CloudWeather weather = CloudWeather(weatherData.b, weatherData.r, weatherData.g);

  weather.coverage = mix(weather.coverage, 1.0, weather.precipitation);

  // weather.coverage = 0.5;

  // weather.cloudType = 1.0;

  float heightGradient = cloudHeightDensity(p, weather);

  vec4 lowFrequencyNoise = texture(cloudshapenoisetex, p / 4000.0);
  float lowFrequencyFBM = (
    lowFrequencyNoise.g * 0.625 +
    lowFrequencyNoise.b * 0.25 +
    lowFrequencyNoise.a * 0.125
  );

  float cloud = clamp01(remap(lowFrequencyNoise.r, lowFrequencyFBM - 1.0, 1.0, 0.0, 1.0));

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
  cloud = cloud * highFrequencyNoiseModifier * (1.0 - cloud);

  return clamp01(cloud);
}

#endif