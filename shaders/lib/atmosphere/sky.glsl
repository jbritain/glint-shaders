#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"

vec3 getSky(vec4 color, vec3 dir, bool includeSun){
  if(!hasSkylight){
    return vec3(0.0);
  }

  // return vec3(0.0);
  vec3 transmit = vec3(1.0);
  vec3 kCamera = vec3(0.0, (128 + cameraPosition.y) + ATMOSPHERE.bottom_radius, 0.0);
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
  vec3 kCamera = vec3(0.0, 128 + cameraPosition.y + ATMOSPHERE.bottom_radius, 0.0);

  sunlightColor = GetSunAndSkyIrradiance(
		kCamera, sunVector, skyLightColor
  );

  vec3 transmit;
  skyLightColor = GetSkyRadiance(kCamera, vec3(0.0, 1.0, 0.0), 0.0, sunVector, transmit);

  if(worldTime > 12785 && worldTime < 23215){
    sunlightColor += vec3(0.01, 0.01, 0.02);
  }
  
}
#endif