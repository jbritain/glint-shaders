#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"
#include "/lib/atmosphere/common.glsl"

vec3 kCamera = vec3(0.0, 128 + cameraPosition.y + ATMOSPHERE.bottom_radius, 0.0);

vec3 getSky(vec4 color, vec3 dir, bool includeSun){
  if(!hasSkylight){
    return vec3(0.0);
  }

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

  sunlightColor = GetSunAndSkyIrradiance(
		kCamera, sunVector, skyLightColor
  );

  vec3 transmit;
  // #ifdef GENERATE_SKY_LUT
  skyLightColor = GetSkyRadiance(kCamera, vec3(0.0, 1.0, 0.0), 0.0, sunVector, transmit);
  // #else
  // skyLightColor = (texelFetch(colortex9, ivec2(0), 8).rgb + texelFetch(colortex9, ivec2(0, 1), 8).rgb) / 2.0;
  // #endif

  if(sunVector != lightVector) {
    vec3 moonColor = vec3(0.62, 0.65, 0.74);
    sunlightColor += getSky(vec4(moonColor * 0.05, 1.0), -sunVector, false);
  }
  
}

vec4 getAtmosphericFog(vec4 color, vec3 playerPos){
  #ifndef ATMOSPHERE_FOG
  return color;
  #endif

  vec3 transmit = vec3(1.0);

  vec3 dir = normalize(playerPos);

  vec3 fog = GetSkyRadianceToPoint(kCamera, kCamera + playerPos, 0.0, normalize(mat3(gbufferModelViewInverse) * sunPosition), transmit) * EBS.y;

  return vec4(color.rgb * transmit + fog, color.a);
}
#endif