#ifndef SUBSURFACE_SCATTERING_GLSL
#define SUBSURFACE_SCATTERING_GLSL

#include "/lib/util/phaseFunctions.glsl"

vec3 getSubsurfaceScattering(
  vec3 albedo,
  float factor,
  float blockerDistance,
  float shadow,
  vec3 playerDir,
  vec3 playerNormal
) {
  if (factor < 0.01) {
    return vec3(0.0);
  }

  blockerDistance = max(blockerDistance * 255, 0.01);

  float VoL = dot(playerDir, worldLightDir);

  float phase = mix(henyeyGreenstein(0.4, VoL), isotropicPhase, 0.1);

  vec3 scatter =
    SUBSURFACE_SCATTERING_STRENGTH *
    phase *
    vec3(factor) *
    vec3(exp(-blockerDistance / (albedo / max(0.1, sqrt(luminance(albedo))))));

  return scatter;
}

#endif // SUBSURFACE_SCATTERING_GLSL
