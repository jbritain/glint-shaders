#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec4 getFog(vec4 color, vec3 playerPos){
  #ifndef FOG
  return color;
  #endif

  vec3 kCamera = vec3(0.0, 128.0 + cameraPosition.y + ATMOSPHERE.bottom_radius, 0.0);

  vec3 transmit = vec3(1.0);

  // vec3 fog = GetSkyRadianceToPoint(
  //   kCamera,
  //   kCamera + playerPos,
  //   0.0,
  //   sunVector,
  //   transmit
  // );

  vec3 dir = normalize(playerPos);
  dir.y = abs(dir.y);

  vec3 fog = GetSkyRadiance(
    kCamera, dir, 0.0, sunVector, transmit
  );

  float visibilityDistance = mix(150000, 4000, wetness);
  float extinctionCoefficient = 3.912 / visibilityDistance;
  transmit = vec3(exp(-extinctionCoefficient * length(playerPos)));

  color.rgb = mix(color.rgb, fog, 1.0 - transmit);

  return color;
}

#endif