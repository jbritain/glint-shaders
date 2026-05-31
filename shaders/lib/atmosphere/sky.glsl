/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/util/misc.glsl"
#include "/lib/atmosphere/pulsar.glsl"
#include "/lib/util/misc.glsl"

vec3 sampleGalaxy(vec3 dir) {
  float theta = atan(dir.z, dir.x);

  theta = mod(theta, 2 * PI);

  float phi = acos(dir.y);

  vec2 uv = vec2(theta / (2 * PI), phi / PI);
  return texture(startex, uv).rgb;
}

#if defined WORLD_THE_NETHER
vec3 getSky(vec3 dir, bool includeSun) {
  return sRGBToLinear(fogColor);
}
#elif defined WORLD_THE_END
vec3 getSky(vec3 dir, bool includeSun) {
  return getPulsar(dir, includeSun) + sampleGalaxy(dir);
}
#else
#include "/lib/atmosphere/atmosphere.glsl"

// TODO: moon phases

vec3 getMoon(vec3 dir) {
  float VoL = dot(dir, worldMoonDir);

  if (VoL <= cos(moonAngularRadius)) {
    return vec3(0.0);
  }

  vec3 moonPos = worldMoonDir * moonDistance;
  vec3 intersectPos =
    dir * raySphereIntersect(vec3(0.0), dir, moonPos, moonRadius);
  vec3 normal = normalize(intersectPos - moonPos);

  float lat = atan(normal.x, normal.z) / TAU + 0.5;
  float lon = asin(normal.y) / PI + 0.5;

  vec3 sunPhaseDir = rotate(
    worldSunDir,
    cross(worldMoonDir, vec3(1.0, 0.0, 0.0)),
    float(moonPhase) * TAU / 8
  );

  float phase = dot(sunPhaseDir, -dir); // 1.0 at full moon
  float hapkeApprox = mix(1.0, 2.5, pow(max(0.0, phase), 2.0));

  return max(0.0, dot(normal, sunPhaseDir)) *
  hapkeApprox *
  pow(texture(moontex, vec2(lat, lon)).rgb, vec3(1.0 / 2.2)) *
  moonLuminance /
  PI;
}

vec3 getSky(vec3 dir, bool includeSun) {
  vec3 transmittance = getValFromTLUT(
    sunTransmittanceLUTTex,
    tLUTRes,
    atmospherePos,
    dir
  );
  vec3 sky = getValFromSkyLUT(dir);

  if (includeSun) {
    if (dot(dir, worldSunDir) > cos(sunAngularRadius)) {
      sky += sunLuminance * transmittance;
    }
    sky += getMoon(dir) * transmittance;
  }
  sky += sampleGalaxy(dir) * transmittance;

  return sky;
}
#endif

#endif
