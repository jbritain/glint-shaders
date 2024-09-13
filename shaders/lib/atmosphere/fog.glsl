#ifndef FOG_INCLUDE
#define FOG_INCLUDE

#include "/lib/atmosphere/sky.glsl"

vec4 getFog(vec4 color, vec3 playerPos){
  #ifndef FOG
  return color;
  #endif

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