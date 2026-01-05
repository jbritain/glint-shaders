/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef PHASE_FUNCTIONS_GLSL
#define PHASE_FUNCTIONS_GLSL

float henyeyGreenstein(float g, float costh) {
  return (1.0 - g * g) /
  (4.0 * PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0 / 2.0));
}

const float isotropicPhase = 1.0 / 4.0 * PI;

float dualHenyeyGreenstein(float g1, float g2, float costh, float weight) {
  return mix(henyeyGreenstein(g1, costh), henyeyGreenstein(g2, costh), weight);
}

#endif // PHASE_FUNCTIONS_GLSL