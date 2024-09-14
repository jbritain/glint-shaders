#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec4 getFog(vec4 color, vec3 playerPos){
  #ifndef FOG
  return color;
  #endif

  vec3 kCamera = vec3(0.0, 128.0 + cameraPosition.y + ATMOSPHERE.bottom_radius + 10000, 0.0);

  vec3 transmit = vec3(1.0);

  // vec3 fog = GetSkyRadianceToPoint(
  //   kCamera,
  //   kCamera + playerPos,
  //   0.0,
  //   sunVector,
  //   transmit
  // );

  vec3 dir = normalize(playerPos);

  vec3 fog = GetSkyRadiance(
    kCamera, dir, 0.0, sunVector, transmit
  );

  float visibilityDistance = 150000.0;
  float extinctionCoefficient = 3.912 / visibilityDistance;
  float extinction = exp(-extinctionCoefficient * length(playerPos));

  extinction = mix(extinction, 0.0, smoothstep(far * 0.8, far, length(playerPos)));

  transmit = vec3(extinction);

  color.rgb = mix(color.rgb, fog, 1.0 - transmit);
  color.a = (1.0 - (1.0 - color.a) * (extinction));

  return color;
}

#endif