// https://www.shadertoy.com/view/4dfGDH

#ifndef BILATERAL_INCLUDE
#define BILATERAL_INCLUDE

// how much neighbouring pixels contribute
#define BILATERAL_SIGMA 5.0

// edge sensitivity
#define BILATERAL_BSIGMA 0.1

// sample radius
#define BILATERAL_MSIZE 15

#include "/lib/util/spaceConversions.glsl"

float normpdf(in float x, in float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

float normpdf3(in vec3 v, in float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

vec3 bilateral(sampler2D image, vec2 coord){
  const int kSize = (BILATERAL_MSIZE-1)/2;

  float kernel[BILATERAL_MSIZE];

  vec3 color;

  float Z = 0.0;
  for (int j = 0; j <= kSize; ++j){
    kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), BILATERAL_SIGMA);
  }

  vec3 c = texture(image, coord).rgb;
  vec3 cc;
  float factor;
  float bZ = 1.0/normpdf(0.0, BILATERAL_BSIGMA);
  //read out the texels
  for (int i=-kSize; i <= kSize; ++i)
  {
    for (int j=-kSize; j <= kSize; ++j)
    {
      vec2 sampleCoord = coord + (vec2(float(i),float(j))) / vec2(viewWidth, viewHeight);

      cc = texture(image, sampleCoord).rgb;
      factor = normpdf3(cc-c, BILATERAL_BSIGMA)*bZ*kernel[kSize+j]*kernel[kSize+i];
      Z += factor;
      color += factor*cc;

    }
  }

  return color/Z;
}

#endif