/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef PHASE_FUNCTIONS_GLSL
#define PHASE_FUNCTIONS_GLSL

const float isotropicPhase = 1.0 / (4.0 * PI);

float henyeyGreenstein(float g, float costh) {
  return (1.0 - g * g) /
  (4.0 * PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0 / 2.0));
}

float dualHenyeyGreenstein(float g1, float g2, float costh, float weight) {
  return mix(henyeyGreenstein(g1, costh), henyeyGreenstein(g2, costh), weight);
}

float draine(float g, float cosTheta, float a) {
  return (1 - g * g) *
  (1 + a * cosTheta * cosTheta) /
  (4.0 *
    (1 + a * (1 + 2 * g * g) / 3.0) *
    PI *
    pow(1 + g * g - 2 * g * cosTheta, 1.5));
}

float hgDraine(const float d, float cosTheta) {
  const float g_hg = exp(-0.0990567 / (d - 1.67154));
  const float g_d = exp(-2.20679 / (d + 3.91029) - 0.428934);
  const float a = exp(3.62489 - 8.29288 / (d + 5.52825));
  const float w = exp(-0.599085 / (d - 0.641583) - 0.665888);

  return mix(henyeyGreenstein(g_hg, cosTheta), draine(g_d, cosTheta, a), w);
}

#endif // PHASE_FUNCTIONS_GLSL
