/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef MISC_GLSL
#define MISC_GLSL

// https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
mat3 generateTBN(vec3 n) {
  mat3 tbn;
  tbn[2] = n;
  if (n.z < -0.9) {
    tbn[0] = vec3(0.0, -1, 0);
    tbn[1] = vec3(-1, 0, 0);
  } else {
    float a = 1.0 / (1.0 + n.z);
    float b = -n.x * n.y * a;
    tbn[0] = vec3(1.0 - n.x * n.x * a, b, -n.x);
    tbn[1] = vec3(b, 1.0 - n.y * n.y * a, -n.y);
  }
  return tbn;
}

// by Zombye
// https://discord.com/channels/237199950235041794/525510804494221312/1118170604160421918
// https://ggx-research.github.io/publication/2023/06/09/publication-ggx.html
vec3 SampleVNDFGGX(
  vec3 viewerDirection, // Direction pointing towards the viewer, oriented such that +Z corresponds to the surface normal
  vec2 alpha, // Roughness parameter along X and Y of the distribution
  vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
  // Transform viewer direction to the hemisphere configuration
  viewerDirection = normalize(
    vec3(alpha * viewerDirection.xy, viewerDirection.z)
  );

  // Sample a reflection direction off the hemisphere
  float phi = TAU * xy.x;
  float cosTheta = fma(1.0 - xy.y, 1.0 + viewerDirection.z, -viewerDirection.z);
  float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
  vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

  // Evaluate halfway direction
  // This gives the normal on the hemisphere
  vec3 halfway = reflected + viewerDirection;

  // Transform the halfway direction back to hemiellispoid configuation
  // This gives the final sampled normal
  return normalize(vec3(alpha * halfway.xy, halfway.z));
}

// https://www.shadertoy.com/view/MtVGWz
//note: refitting weights to a +
//      (from https://advances.realtimerendering.com/s2016/Filmic%20SMAA%20v7.pptx , p 92 )
vec4 catmullRom5(sampler2D tex, vec2 uv) {
  vec2 texsiz = vec2(textureSize(tex, 0).xy);
  vec4 rtMetrics = vec4(1.0 / texsiz.xy, texsiz.xy);

  vec2 position = rtMetrics.zw * uv;
  vec2 centerPosition = floor(position - 0.5) + 0.5;
  vec2 f = position - centerPosition;
  vec2 f2 = f * f;
  vec2 f3 = f * f2;

  const float c = 0.4; //note: [0;1] ( SMAA_FILMIC_REPROJECTION_SHARPNESS / 100.0 )
  vec2 w0 = -c * f3 + 2.0 * c * f2 - c * f;
  vec2 w1 = (2.0 - c) * f3 - (3.0 - c) * f2 + 1.0;
  vec2 w2 = -(2.0 - c) * f3 + (3.0 - 2.0 * c) * f2 + c * f;
  vec2 w3 = c * f3 - c * f2;

  vec2 w12 = w1 + w2;
  vec2 tc12 = rtMetrics.xy * (centerPosition + w2 / w12);
  vec4 centerColor = texture(tex, vec2(tc12.x, tc12.y));

  vec2 tc0 = rtMetrics.xy * (centerPosition - 1.0);
  vec2 tc3 = rtMetrics.xy * (centerPosition + 2.0);
  vec4 color =
    vec4(texture(tex, vec2(tc12.x, tc0.y))) * (w12.x * w0.y) +
    vec4(texture(tex, vec2(tc0.x, tc12.y))) * (w0.x * w12.y) +
    vec4(centerColor) * (w12.x * w12.y) +
    vec4(texture(tex, vec2(tc3.x, tc12.y))) * (w3.x * w12.y) +
    vec4(texture(tex, vec2(tc12.x, tc3.y))) * (w12.x * w3.y);
  return color;
}

#endif // MISC_GLSL
