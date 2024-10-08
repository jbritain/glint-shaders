#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"
#include "/lib/atmosphere/common.glsl"

#ifdef WORLD_THE_END
#include "/lib/atmosphere/endSky.glsl"
#endif

vec3 kCamera = vec3(0.0, 128 + cameraPosition.y + ATMOSPHERE.bottom_radius, 0.0);

vec3 getSky(vec4 color, vec3 dir, bool includeSun){
  #ifdef WORLD_THE_END
    return endSky(dir, includeSun);
  #endif

  #ifndef WORLD_OVERWORLD
    return vec3(0.0);
  #endif

  // return vec3(0.0);
  vec3 transmit = vec3(1.0);
  vec3 radiance = GetSkyRadiance(
    kCamera, dir, 0.0, sunVector, transmit
  );

  if(includeSun && dot(dir, sunVector) > cos(ATMOSPHERE.sun_angular_radius)){
    radiance += transmit * GetSolarRadiance();
  }

  return color.rgb * transmit + radiance;
}

vec3 getSky(vec3 dir, bool includeSun){

  return getSky(vec4(0.0), dir, includeSun);
}

void getLightColors(out vec3 sunlightColor, out vec3 skyLightColor){
  sunlightColor = vec3(0.0);
  skyLightColor = vec3(0.0);

  #ifdef WORLD_OVERWORLD
  sunlightColor = GetSunAndSkyIrradiance(
		kCamera, sunVector, skyLightColor
  );

  vec3 transmit;
  skyLightColor = GetSkyRadiance(kCamera, vec3(0.0, 1.0, 0.0), 0.0, sunVector, transmit);

  if(sunVector != lightVector) {
    vec3 moonColor = vec3(0.62, 0.65, 0.74);
    sunlightColor += getSky(vec4(moonColor * 0.05, 1.0), -sunVector, false);
  }
  #elif defined WORLD_THE_END
  sunlightColor = vec3(0.8, 0.7, 1.0);
  #endif
}

vec4 getAtmosphericFog(vec4 color, vec3 playerPos){
  #ifndef ATMOSPHERE_FOG
  return color;
  #endif

  #ifndef WORLD_OVERWORLD
  return color;
  #endif

  vec3 transmit = vec3(1.0);

  vec3 dir = normalize(playerPos);

  vec3 fog = GetSkyRadianceToPoint(kCamera, kCamera + playerPos, 0.0, normalize(mat3(gbufferModelViewInverse) * sunPosition), transmit) * EBS.y;

  return vec4(color.rgb * transmit + fog, color.a);
}
#endif