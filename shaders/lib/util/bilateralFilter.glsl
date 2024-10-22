/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/


#ifndef BILATERAL_INCLUDE
#define BILATERAL_INCLUDE

#include "/lib/util/spaceConversions.glsl"

float gaussWeight(float x, float sigma){
  return exp(-pow2(x) / (2.0 * pow2(sigma))) / (2.0 * PI * pow2(sigma));
}

vec4 bilateralFilter(sampler2D image, vec2 coord, float sigmaS, float sigmaL){
  const float factorS = -rcp(2.0 * pow2(sigmaS));
  const float factorL = -rcp(2.0 * pow2(sigmaL));

  vec2 off1 = vec2(1.411764705882353);
  vec2 off2 = vec2(3.2941176470588234);
  vec2 off3 = vec2(5.176470588235294);

  float weightSum = 0.0;
  vec4 sampleSum = vec4(0.0);
  float halfSize = sigmaS / 2.0;

  float luminance = getLuminance(texture(image, coord).rgb);

  for (float x = -halfSize; x <= halfSize; x++) {
    for (float y = -halfSize;  y <= halfSize; y++){
      vec2 offset = vec2(x, y);

      vec4 offsetSample = texture(image, coord + offset / vec2(viewWidth, viewHeight));

      float distS = length(offset);
      float distL = abs(getLuminance(offsetSample.rgb) - luminance);

      float weightS = exp(factorS * pow2(distS));
      float weightL = exp(factorL * pow2(distL));
      float weight = weightS * weightL * gaussWeight(distS, halfSize / 2);

      weightSum += weight;
      sampleSum += offsetSample * weight;
    }
  }

  return sampleSum / weightSum;
}

vec4 bilateralFilterDepth(sampler2D image, sampler2D depthtex, vec2 coord, float sigmaS, float sigmaL, float scale){
  const float factorS = -rcp(2.0 * pow2(sigmaS));
  const float factorL = -rcp(2.0 * pow2(sigmaL));

  vec2 off1 = vec2(1.411764705882353);
  vec2 off2 = vec2(3.2941176470588234);
  vec2 off3 = vec2(5.176470588235294);

  float weightSum = 0.0;
  vec4 sampleSum = vec4(0.0);
  float halfSize = sigmaS / 2.0;

  float depth = linearizeDepth(texture(depthtex, coord / scale).r, near, far) / far;

  for (float x = -halfSize; x <= halfSize; x++) {
    for (float y = -halfSize;  y <= halfSize; y++){
      vec2 offset = vec2(x, y);

      float offsetSampleDepth = linearizeDepth(texture(depthtex, coord / scale).r, near, far) / far;
      if(offsetSampleDepth == 1.0){
        continue;
      }

      vec4 offsetSample = texture(image, coord + offset / vec2(viewWidth, viewHeight));


      float distS = length(offset);
      float distL = abs(offsetSampleDepth - depth);


      float weightS = exp(factorS * pow2(distS));
      float weightL = exp(factorL * pow2(distL));
      float weight = weightS * weightL * gaussWeight(distS, halfSize / 2);

      weightSum += weight;
      sampleSum += offsetSample * weight;
    }
  }

  return sampleSum / weightSum;
}

#endif