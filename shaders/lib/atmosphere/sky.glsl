#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"

const vec3 SUN_VECTOR = normalize(mat3(gbufferModelViewInverse) * sunPosition);

vec3 getSky(vec3 dir, bool includeSun){
  vec3 transmit = vec3(1.0);
  vec3 kCamera = vec3(0.0, ATMOSPHERE.bottom_radius + cameraPosition.y + 128, 0.0);
  vec3 radiance = GetSkyRadiance(
    kCamera, dir, 0.0, SUN_VECTOR, transmit
  );

  if(includeSun && dot(dir, SUN_VECTOR) > cos(ATMOSPHERE.sun_angular_radius)){
    radiance += transmit * GetSolarRadiance();
  }

  return radiance * 0.5;
}

vec3 getSky(vec3 dir, vec3 pos, bool includeSun){
  vec3 kCamera = vec3(0.0, ATMOSPHERE.bottom_radius + cameraPosition.y + 128, 0.0);

  vec3 transmit = vec3(1.0);

  vec3 radiance = GetSkyRadianceToPoint(
		kCamera,
		kCamera + pos,
		0.0,
		SUN_VECTOR,
		transmit
  );

  if(includeSun && dot(dir, SUN_VECTOR) > cos(ATMOSPHERE.sun_angular_radius)){
		radiance += transmit * GetSolarRadiance();
  }

	return radiance * 0.5;
}

void getLightColors(out vec3 sunlightColor, out vec3 skyLightColor){
  vec3 kCamera = vec3(0.0, ATMOSPHERE.bottom_radius + cameraPosition.y + 128, 0.0);

  sunlightColor = GetSunAndSkyIrradiance(
		kCamera, SUN_VECTOR, skyLightColor
  );
}
#endif