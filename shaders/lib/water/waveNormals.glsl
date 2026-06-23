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

#ifndef WAVE_NORMALS_GLSL
#define WAVE_NORMALS_GLSL

#include "/lib/util/perlinNoise.glsl"

#define WAVE_INITIAL_AMPLITUDE 0.07
#define WAVE_INITIAL_WAVELENGTH 10.0
#define WAVE_AMPLITUDE_MULTIPLIER 0.8
#define WAVE_WAVELENGTH_MULTIPLIER 0.8
#define WAVE_OCTAVES 12
#define WAVE_STEEPNESS 2.0

const float waterRoughness = sqrt(
  sqrt(WAVE_STEEPNESS * WAVE_OCTAVES / (1.0 + WAVE_STEEPNESS * WAVE_OCTAVES))
);

const float totalWaveAmplitude =
  WAVE_INITIAL_AMPLITUDE *
  (1.0 - pow(WAVE_AMPLITUDE_MULTIPLIER, float(WAVE_OCTAVES))) /
  (1.0 - WAVE_AMPLITUDE_MULTIPLIER);

const float g = 9.8;

float gerstner(
  vec2 pos,
  vec2 dir,
  float wavelength,
  float amplitude,
  float t,
  float steepness
) {
  float k = TAU / wavelength;
  float omega = sqrt(g * k);
  vec2 K = normalize(dir) * k; // ensure dir is normalized

  return amplitude *
  pow(cos(mod(dot(K, pos) - omega * t, TAU)) * 0.5 + 0.5, steepness);
}

vec2 gerstnerDeriv(
  vec2 pos,
  vec2 dir,
  float wavelength,
  float amplitude,
  float t,
  float steepness
) {
  float k = TAU / wavelength;
  float omega = sqrt(g * k);
  vec2 K = normalize(dir) * k;

  float phase = dot(K, pos) - omega * t;
  float cosHalf = cos(phase) * 0.5 + 0.5;

  float scalar =
    amplitude * steepness * pow(cosHalf, steepness - 1.0) * (-sin(phase) * 0.5);

  return scalar * K;
}

float waveHeight(vec2 pos) {
  float noise = texture(
    perlinnoisetex,
    fract((pos + vec2(worldTimeCounter * 2.0 - 1.0) * 0.2) / 200.0)
  ).r;

  float height = 0.0;
  float wavelength = WAVE_INITIAL_WAVELENGTH;
  float amplitude = WAVE_INITIAL_AMPLITUDE;

  for (int i = 0; i < WAVE_OCTAVES; i++) {
    float r = mod(i * 11.23456, TAU);
    vec2 dir = vec2(sin(r), cos(r));
    height += gerstner(
      pos,
      dir,
      wavelength,
      amplitude,
      worldTimeCounter * 0.5 + noise * 10,
      WAVE_STEEPNESS
    );
    wavelength *= WAVE_WAVELENGTH_MULTIPLIER;
    amplitude *= WAVE_AMPLITUDE_MULTIPLIER;
  }

  return height;

}

vec2 waveHeightDeriv(vec2 pos) {
  float noise = texture(
    perlinnoisetex,
    fract((pos + vec2(worldTimeCounter * 2.0 - 1.0) * 0.2) / 200.0)
  ).r;

  vec2 grad = vec2(0.0);
  float wavelength = WAVE_INITIAL_WAVELENGTH;
  float amplitude = WAVE_INITIAL_AMPLITUDE;

  for (int i = 0; i < WAVE_OCTAVES; i++) {
    float r = mod(float(i * 11.23456), TAU);
    vec2 dir = vec2(sin(r), cos(r));
    grad += gerstnerDeriv(
      pos,
      dir,
      wavelength,
      amplitude,
      worldTimeCounter * 0.5 + noise * 10,
      WAVE_STEEPNESS
    );
    wavelength *= WAVE_WAVELENGTH_MULTIPLIER;
    amplitude *= WAVE_AMPLITUDE_MULTIPLIER;
  }

  return grad;
}

vec3 rotate(vec3 vector, vec3 from, vec3 to) {
  // where "from" and "to" are two unit vectors determining how far to rotate
  // adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

  float cosTheta = dot(from, to);
  if (abs(cosTheta) >= 0.9999) {
    return cosTheta < 0.0
      ? -vector
      : vector;
  }
  vec3 axis = normalize(cross(from, to));

  vec2 sc = vec2(sqrt(1.0 - cosTheta * cosTheta), cosTheta);
  return sc.y * vector +
  sc.x * cross(axis, vector) +
  (1.0 - sc.y) * dot(axis, vector) * axis;
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
// returned value is in world space
vec3 waveNormal(vec2 pos, vec3 worldFaceNormal, float heightmapFactor) {
  // if(abs(dot(worldFaceNormal, vec3(0.0, 1.0, 0.0))) <= 0.1){
  // return worldFaceNormal;
  // }

  vec2 deriv = waveHeightDeriv(pos);
  vec3 waveNormal = normalize(vec3(-deriv.x, 1.0, -deriv.y));

  // rotate to align with face normal since the normal calculation assumes a surface facing straight up
  waveNormal = rotate(waveNormal, vec3(0.0, 1.0, 0.0), worldFaceNormal);
  return normalize(waveNormal);
}

vec3 getWaterParallaxNormal(
  vec3 playerPos,
  vec3 worldNormal,
  float jitter,
  float heightmapFactor
) {
  #ifdef WATER_PARALLAX
  // we know no wave is ever more than WAVE_DEPTH above the surface
  // so we shift the ray forwards until it is WAVE_DEPTH above the surface
  float fractionalDistance;
  fractionalDistance =
    (abs(playerPos.y) - totalWaveAmplitude) / abs(playerPos.y);
  vec3 origin = playerPos * fractionalDistance;

  vec3 increment = (playerPos - origin) / float(WATER_PARALLAX_SAMPLES);

  bool intersect = false;

  vec3 rayPos = origin;

  rayPos += increment * jitter;

  for (int i = 0; i < WATER_PARALLAX_SAMPLES; i++) {
    float waveHeight = waveHeight(rayPos.xz + cameraPosition.xz) + playerPos.y;

    // turns out you can just build binary refinement into the loop this is goated
    bool intersect = playerPos.y < 0 == rayPos.y < waveHeight;
    if (intersect) {
      increment /= 2;
    }

    rayPos += increment * (intersect ? -1 : 1);

  }

  return waveNormal(rayPos.xz + cameraPosition.xz, worldNormal, 1.0);

  #endif

  return waveNormal(
    playerPos.xz + cameraPosition.xz,
    worldNormal,
    heightmapFactor
  );
}

#endif // WAVE_NORMALS_GLSL
