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

#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

#ifndef NEUTRON_STAR_GLSL
#define NEUTRON_STAR_GLSL

const float pulsarRadius = 100;
const float pulsarDistance = 1e4;
const float pulsarAngularRadius = pulsarRadius / pulsarDistance;
const float pulsarSolidAngle = TAU * (1.0 - cos(pulsarAngularRadius));

const float pulsarConeRadius = 10000;
const float pulsarConeLength = 200000;

const vec3 pulsarLuminance = vec3(0.15, 0.3, 1.0) * 1.6e6;
const vec3 pulsarIlluminance = pulsarLuminance * pulsarSolidAngle;

const vec3 pulsarRadiationLuminance = vec3(0.15, 0.3, 1.0) * 50;

// infinite cylinder with base point "cb", normalized axis "ca" and radius "cr"
vec2 cylIntersect(vec3 ro, vec3 rd, vec3 cb, vec3 ca, float cr) {
  vec3 oc = ro - cb;
  float card = dot(ca, rd);
  float caoc = dot(ca, oc);
  float a = 1.0 - card * card;
  float b = dot(oc, rd) - caoc * card;
  float c = dot(oc, oc) - caoc * caoc - cr * cr;
  float h = b * b - a * c;
  if (h < 0.0) return vec2(-1.0); //no intersection
  h = sqrt(h);
  return vec2(-b - h, -b + h) / a;
}

float getPulsarDensity(vec3 pos, vec3 pulsarPos, vec3 axis, float axisDot) {
  float distanceAlongAxis = abs(dot(pos, axis) - axisDot);

  float t = dot(pos - pulsarPos, axis) / dot(axis, axis);
  vec3 closest = pulsarPos + t * axis;
  float distanceToAxis = length(pos - closest);

  vec3 pointOnAxisPlane = pos - distanceAlongAxis * axis;

  float steppingPoint = mix(
    0,
    pulsarConeRadius,
    distanceAlongAxis / pulsarConeLength
  );

  return (1.0 -
    smoothstep(steppingPoint * 0.8, steppingPoint, distanceToAxis)) *
  pow3(1.0 - linearstep(0.0, pulsarConeLength, distanceAlongAxis));
}

#define PULSAR_SAMPLES 16

#ifdef fsh
vec3 getPulsar(vec3 dir, bool includeStar) {
  float dirDot = dot(dir, worldLightDir);
  if (dirDot < 0.0) {
    return vec3(0.0);
  }

  vec3 pulsarPos = worldLightDir * pulsarDistance;
  vec3 pulsarAxis = normalize(
    cross(worldLightDir, normalize(vec3(1.0, 0.5, 0.0)))
  );
  pulsarAxis = rotate(
    pulsarAxis,
    worldLightDir,
    dirDot + frameTimeCounter * 0.01
  );

  vec2 intersection = cylIntersect(vec3(0.0), dir, pulsarPos, pulsarAxis, 1000);

  if (intersection.x <= 0.0 || intersection.y <= 0.0 || isbad(intersection)) {
    return vec3(0.0);
  }

  vec3 start = dir * intersection.x;
  vec3 end = dir * intersection.y;

  vec3 luminance = vec3(0.0);

  if (dirDot > cos(pulsarAngularRadius) && includeStar) {
    luminance += pulsarLuminance;
  }

  vec3 rayPos = start;
  vec3 rayStep = (end - start) / (PULSAR_SAMPLES - 1);
  float stepLength = length(rayStep);

  rayPos += blueNoise(gl_FragCoord.xy, frameCounter).r * rayStep;

  float axisDot = dot(pulsarPos, pulsarAxis);

  for (int i = 0; i < PULSAR_SAMPLES - 1; i++) {
    float density =
      getPulsarDensity(rayPos, pulsarPos, pulsarAxis, axisDot) * stepLength;

    luminance += density * pulsarRadiationLuminance;
    rayPos += rayStep;
  }

  return luminance;
}
#else
vec3 getPulsar(vec3 dir, bool includeStar) {
  return vec3(0.0);
}
#endif

#endif // NEUTRON_STAR_GLSL
