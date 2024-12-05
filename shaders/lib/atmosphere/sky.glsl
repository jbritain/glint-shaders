/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/util.glsl"

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"
#include "/lib/atmosphere/common.glsl"


#ifdef WORLD_THE_END
#include "/lib/atmosphere/endSky.glsl"
#endif

layout(std430, binding = 1) buffer frameData {
  vec3 averageSkyColor;
};

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

  // #ifdef BORDER_FOG
  // // override sky color below horizon
  // if(dir.y < 0.0){
  //   vec3 tempDir = dir;
  //   tempDir.y = clamp01(tempDir.y);
  //   tempDir = normalize(tempDir);
  //   vec3 tempTransmit;
  //   radiance = GetSkyRadiance(kCamera, tempDir, 0.0, sunVector, tempTransmit);
  // }
  // #endif

  if(includeSun && dot(dir, sunVector) > cos(ATMOSPHERE.sun_angular_radius)){
    radiance += transmit * GetSolarRadiance();
  }

  return color.rgb * transmit + radiance;
}

vec3 getSky(vec3 dir, bool includeSun){

  return getSky(vec4(0.0), dir, includeSun);
}

void getLightColors(out vec3 sunlightColor, out vec3 skyLightColor, vec3 feetPlayerPos, vec3 worldFaceNormal){
  sunlightColor = vec3(0.0);
  skyLightColor = vec3(0.0);

  #ifdef WORLD_OVERWORLD
  sunlightColor = GetSunAndSkyIrradiance(
		kCamera + feetPlayerPos, worldFaceNormal, sunVector, skyLightColor
  );
  vec3 transmit;
  skyLightColor = averageSkyColor * PI;

  if(sunVector != lightVector) {
    vec3 moonColor = vec3(0.62, 0.65, 0.74) * vec3(0.5, 0.5, 1.0);
    sunlightColor += getSky(vec4(moonColor * 0.05, 1.0), -sunVector, false);
  }
  #elif defined WORLD_THE_END
  sunlightColor = vec3(0.8, 0.7, 1.0);
  #endif
}

vec4 getAtmosphericFog(vec4 color, vec3 playerPos, vec3 transmit){
  #ifndef ATMOSPHERE_FOG
  return color;
  #endif

  #ifndef WORLD_OVERWORLD
  return color;
  #endif

  vec3 dir = normalize(playerPos);

  // playerPos = mix(playerPos, playerPos * vec3(10000.0, 1.0, 10000.0), smoothstep(0.8 * far, far, length(playerPos)));

  vec3 fog = GetSkyRadianceToPoint(kCamera, kCamera + playerPos, 0.0, normalize(mat3(gbufferModelViewInverse) * sunPosition), transmit) * EBS.y;

  return vec4(color.rgb * transmit + fog, color.a);
}

vec4 getAtmosphericFog(vec4 color, vec3 playerPos){
  vec3 transmit;
  return getAtmosphericFog(color, playerPos, transmit);
}

vec4 getBorderFog(vec4 color, vec3 playerPos){
  #ifndef BORDER_FOG
  return color;
  #endif

  #ifndef WORLD_OVERWORLD
  return color;
  #endif
  
  float distFactor = smoothstep(0.8 * far, far, length(playerPos.xz));
  distFactor = pow2(distFactor);

  vec3 fog = getSky(normalize(playerPos), false);

  color = mix(color, vec4(fog, 1.0), distFactor);
  return color;
}
#endif