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

#include "/lib/atmosphere/common.glsl"
#include "/lib/atmosphere/hillaireCommon.glsl"
#include "/lib/util/uvmap.glsl"


#ifdef WORLD_THE_END
#include "/lib/atmosphere/endSky.glsl"
#endif

vec3 getValFromSkyLUT(vec3 rayDir) {
  float height = atmospherePos.y;
  vec3 up = vec3(0.0, 1.0, 0.0);
  
  float horizonAngle = safeacos(sqrt(height * height - groundRadiusMM * groundRadiusMM) / height);
  float altitudeAngle = horizonAngle - acos(dot(rayDir, up)); // Between -PI/2 and PI/2
  float azimuthAngle; // Between 0 and 2*PI
  if (abs(altitudeAngle) > (0.5*PI - .0001)) {
    // Looking nearly straight up or down.
    azimuthAngle = 0.0;
  } else {
    vec3 right = vec3(1.0, 0.0, 0.0);
    vec3 forward = vec3(0.0, 0.0, -1.0);
    
    vec3 projectedDir = normalize(rayDir - up*(dot(rayDir, up)));
    float sinTheta = dot(projectedDir, right);
    float cosTheta = dot(projectedDir, forward);
    azimuthAngle = atan(sinTheta, cosTheta) + PI;
  }
  
  // Non-linear mapping of altitude angle. See Section 5.3 of the paper.
  float v = 0.5 + 0.5*sign(altitudeAngle)*sqrt(abs(altitudeAngle)*2.0/PI);
  vec2 uv = vec2(azimuthAngle / (2.0*PI), v);
  
  return texture(skyViewLUTTex, uv).rgb;
}

vec3 sun(vec3 rayDir){
  const float minSunCosTheta = cos(sunAngularRadius);

  float cosTheta = dot(rayDir, sunVector);
  if (cosTheta >= minSunCosTheta) return sunRadiance;

  return vec3(0.0);
}

vec3 getSky(vec4 color, vec3 dir, bool includeSun){
  #ifdef WORLD_THE_END
    return endSky(dir, includeSun);
  #endif

  #ifndef WORLD_OVERWORLD
    return vec3(0.0);
  #endif

  vec3 skyColor = getValFromSkyLUT(dir);

  vec3 sunColor = sun(dir) * float(includeSun);

  if (length(sunColor) > 0.0) {
    if (rayIntersectSphere(atmospherePos, dir, groundRadiusMM) >= 0.0) {
      sunColor *= 0.0;
    } else {
      // If the sun value is applied to this pixel, we need to calculate the transmittance to obscure it.
      sunColor *= getValFromTLUT(sunTransmittanceLUTTex, tLUTRes, atmospherePos, sunVector);
    }
  } else {
    if (color.rgb != vec3(0.0)){
      skyColor += color.rgb * getValFromTLUT(sunTransmittanceLUTTex, tLUTRes, atmospherePos, dir);
    }
  }

  skyColor += sunColor;

  return skyColor;
}

vec3 getSky(vec3 dir, bool includeSun){
  return getSky(vec4(0.0), dir, includeSun);
}

void getLightColors(out vec3 sunlightColor, out vec3 skyLightColor, vec3 feetPlayerPos, vec3 worldFaceNormal){


  #ifdef WORLD_OVERWORLD
    sunlightColor = getValFromTLUT(sunTransmittanceLUTTex, tLUTRes, atmospherePos, sunVector) * sunIrradiance;
    // skyLightColor
    vec2 skyUV = mapSphere(worldFaceNormal);
    #ifdef GENERATE_SKY_LUT
    skyLightColor = getSky(worldFaceNormal, false) * PI;
    #else
    skyLightColor = texture(colortex12, skyUV).rgb;
    #endif
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

  // #ifndef WORLD_OVERWORLD
  return color;
  // #endif

  // vec3 dir = normalize(playerPos);

  // // playerPos = mix(playerPos, playerPos * vec3(10000.0, 1.0, 10000.0), smoothstep(0.8 * far, far, length(playerPos)));

  // vec3 fog = GetSkyRadianceToPoint(kCamera, kCamera + playerPos, 0.0, normalize(mat3(gbufferModelViewInverse) * sunPosition), transmit) * EBS.y;

  // return vec4(color.rgb * transmit + fog, color.a);
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