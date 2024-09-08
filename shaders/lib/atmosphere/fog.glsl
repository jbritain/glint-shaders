#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec4 getFog(vec4 color, vec3 playerPos){
  // vec3 fog = getSky(normalize(playerPos), false);
  // float fogFactor = length(playerPos) / far;
  // fogFactor = clamp01(fogFactor - FOG_START) / (1.0 - FOG_START);
  // fogFactor = pow(fogFactor, FOG_POWER);
  // fogFactor = clamp01(fogFactor);
  // color = mix(color, vec4(fog, 1.0), fogFactor);
  // return color;

  vec3 kCamera = vec3(0.0, ATMOSPHERE.bottom_radius + cameraPosition.y + 128, 0.0);

  vec3 transmit;

  vec3 fog = GetSkyRadianceToPoint(
    kCamera,
    kCamera + playerPos,
    0.0,
    sunVector,
    transmit
  );

  color.rgb = color.rgb * transmit + fog;

  return color;
}

#endif