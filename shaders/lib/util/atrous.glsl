#ifndef ATROUS_GLSL
#define ATROUS_GLSL

/*

"Edge-Avoiding À-Trous Wavelet Transform for fast Global
Illumination Filtering"

https://jo.dreggn.org/home/2010_atrous.pdf
*/

#include "/lib/material/material.glsl"

const float atrousKernel[25] = float[25](
  1.0 / 256.0,
  4.0 / 256.0,
  6.0 / 256.0,
  4.0 / 256.0,
  1.0 / 256.0,
  4.0 / 256.0,
  16.0 / 256.0,
  24.0 / 256.0,
  16.0 / 256.0,
  4.0 / 256.0,
  6.0 / 256.0,
  24.0 / 256.0,
  36.0 / 256.0,
  24.0 / 256.0,
  6.0 / 256.0,
  4.0 / 256.0,
  16.0 / 256.0,
  24.0 / 256.0,
  16.0 / 256.0,
  4.0 / 256.0,
  1.0 / 256.0,
  4.0 / 256.0,
  6.0 / 256.0,
  4.0 / 256.0,
  1.0 / 256.0
);

const vec2 atrousOffsets[25] = vec2[25](
  vec2(-2.0, -2.0),
  vec2(-1.0, -2.0),
  vec2(0.0, -2.0),
  vec2(1.0, -2.0),
  vec2(2.0, -2.0),
  vec2(-2.0, -1.0),
  vec2(-1.0, -1.0),
  vec2(0.0, -1.0),
  vec2(1.0, -1.0),
  vec2(2.0, -1.0),
  vec2(-2.0, 0.0),
  vec2(-1.0, 0.0),
  vec2(0.0, 0.0),
  vec2(1.0, 0.0),
  vec2(2.0, 0.0),
  vec2(-2.0, 1.0),
  vec2(-1.0, 1.0),
  vec2(0.0, 1.0),
  vec2(1.0, 1.0),
  vec2(2.0, 1.0),
  vec2(-2.0, 2.0),
  vec2(-1.0, 2.0),
  vec2(0.0, 2.0),
  vec2(1.0, 2.0),
  vec2(2.0, 2.0)
);

vec3 atrousGetNormal(vec2 uv) {
  return unpackGbuffer(texture(colortex1, uv).rgb).geometryNormal;
}

vec3 atrousGetPosition(vec2 uv) {
  float depth = texture(depthtex0, uv).r;
  return screenSpaceToViewSpace(vec3(uv, depth));
}

vec3 atrous(
  sampler2D colorMap,
  vec2 sampleUV,
  float c_phi,
  float n_phi,
  float p_phi,
  float stepwidth
) {
  vec3 sum = vec3(0.0);
  vec2 step = rcp(textureSize(colorMap, 0)); // resolution
  vec3 cval = texture2D(colorMap, sampleUV).rgb;
  vec3 nval = atrousGetNormal(sampleUV);
  vec3 pval = atrousGetPosition(sampleUV);
  float cum_w = 0.0;
  for (int i = 0; i < 25; i++) {
    vec2 uv = sampleUV + atrousOffsets[i] * step * stepwidth;
    vec3 ctmp = texture2D(colorMap, uv).rgb;
    vec3 t = cval - ctmp;

    float dist2 = dot(t, t);
    float c_w = min(exp(-dist2 / c_phi), 1.0);
    vec3 ntmp = atrousGetNormal(uv);
    t = nval - ntmp;
    dist2 = max(dot(t, t) / (stepwidth * stepwidth), 0.0);
    float n_w = min(exp(-dist2 / n_phi), 1.0);
    vec3 ptmp = atrousGetPosition(uv);
    t = pval - ptmp;
    dist2 = dot(t, t);
    float p_w = min(exp(-dist2 / p_phi), 1.0);
    float weight = c_w * n_w * p_w;
    sum += ctmp * weight * atrousKernel[i];
    cum_w += weight * atrousKernel[i];
  }
  return sum / cum_w;
}

#endif // ATROUS_GLSL
