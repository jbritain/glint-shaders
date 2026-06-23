/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

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

// FOURNIER FORAND FUNCTION FROM THE BLENDER SOURCE CODE
// Licensed under the GNU General Public License, Version 3

float fournierForandDelta(const float n, const float sinHthetaSqr) {
  const float nMinus1 = max(n - 1.0, 1e-6);
  const float denom = max(3 * pow2(nMinus1), 1e-6);
  const float u = 4 * sinHthetaSqr;
  return u / denom;
}

vec3 phaseFournierForandCoeffs(const float B, const float IOR) {
  const float d90 = fournierForandDelta(IOR, 0.5);
  const float d180 = fournierForandDelta(IOR, 1.0);
  const float v = -log(2 * B * (d90 - 1) + 1) / log(d90);
  const float denom = d180 - 1.0;
  const float coeffZ = abs(denom) < 1e-6 ? -v : (pow(d180, -v) - 1) / denom;
  return vec3(IOR, v, coeffZ);
}

float fournierForandImpl(
  float cosTheta,
  const float delta,
  const float powDeltaV,
  const float v,
  float sinHthetaSqr,
  const float pfCoeff
) {
  const float mDelta = 1 - delta;
  const float mPowDeltaV = 1 - powDeltaV;
  const float sinHthetaSqrSafe = max(sinHthetaSqr, 1e-6);

  float pf;
  if (abs(mDelta) < 1e-3) {
    /* Special case (first-order Taylor expansion) to avoid singularity at delta near 1.0 */
    pf = v * (v - 1 - (v + 1) / sinHthetaSqrSafe) * (1 / (8 * PI));
    pf +=
      v *
      (v + 1) *
      mDelta *
      (2 * (v - 1) - (2 * v + 1) / sinHthetaSqrSafe) *
      (1 / (24 * PI));
  } else {
    pf =
      (v * mDelta -
        mPowDeltaV +
        (delta * mPowDeltaV - v * mDelta) / sinHthetaSqrSafe) /
      (4 * PI * pow2(mDelta) * powDeltaV);
  }
  pf += pfCoeff * (3 * pow2(cosTheta) - 1);
  return pf;
}

float fournierForand(
  const float backScattering,
  const float IOR,
  float cosTheta
) {
  const float cosThetaClamped = clamp(cosTheta, -1.0, 1.0);
  const vec3 coeffs = phaseFournierForandCoeffs(backScattering, IOR);
  const float n = coeffs.x;
  const float v = coeffs.y;
  const float pfCoeff = coeffs.z * (1.0 / (16.0 * PI));
  const float sinHthetaSqr = max(0.5 * (1 - cosThetaClamped), 1e-6); /* sin^2(theta / 2)*/
  const float delta = fournierForandDelta(n, sinHthetaSqr);

  return fournierForandImpl(
    cosTheta,
    delta,
    pow(delta, v),
    v,
    sinHthetaSqr,
    pfCoeff
  );
}

#endif // PHASE_FUNCTIONS_GLSL
