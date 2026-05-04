/*
    Copyright (c) 2024 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef UPSAMPLE_GLSL
#define UPSAMPLE_GLSL

// DEPTH WEIGHT AND UPSAMPLER BY BALINT

float depthWeight(vec3 p1, vec3 p2, vec2 grad){
    const float DEPTH_WEIGHT_PARAM = 64.0;
    if (p1.z == p2.z)
    {
        return 1.0;
    }
    float expectedDepthDifference = dot(grad, p2.xy - p1.xy);
    float depthDifference = p2.z - p1.z;
    return exp(-abs((depthDifference - expectedDepthDifference) / (expectedDepthDifference + 0.01)) * DEPTH_WEIGHT_PARAM);
}

const uvec2 OFFSETS[] = {
    uvec2(0, 0),
    uvec2(1, 0),
    uvec2(0, 1),
    uvec2(1, 1)
};

vec4 upsample(
  sampler2D undersampled,
  uvec2 pixelCoord,
  float depth,
  int scalingFactor
) {
  vec2 grad = vec2(dFdx(depth), dFdy(depth));

  vec3 centrePos = vec3(vec2(pixelCoord) + 0.5 / resolution, depth);

  uvec2 downscaled = pixelCoord / scalingFactor;
  uvec2 rounded = downscaled * scalingFactor;
  vec2 fractional = fract(vec2(pixelCoord) / scalingFactor);
  float interpolationWeights[] = {
    (1.0 - fractional.x) * (1.0 - fractional.y),
    fractional.x * (1.0 - fractional.y),
    (1.0 - fractional.x) * fractional.y,
    fractional.x * fractional.y,
  };

  float totalWeight = 0.0;
  vec4 color = vec4(0.0);
  for(int i = 0; i < 4; i++){
    uvec2 samplePos = rounded + OFFSETS[i] * scalingFactor;
    vec3 sampleScreenPos = vec3((samplePos + 0.5 / resolution), texelFetch(depthtex0, ivec2(samplePos), 0).r);

    float weight = depthWeight(centrePos, sampleScreenPos, grad) * interpolationWeights[i];
    color += texelFetch(undersampled, ivec2(downscaled + OFFSETS[i]), 0) * weight;
    totalWeight += weight;
  }

  if(totalWeight == 0.0){
    return vec4(0.0);
  }

  return color / totalWeight;
}

#endif // UPSAMPLE_GLSL
