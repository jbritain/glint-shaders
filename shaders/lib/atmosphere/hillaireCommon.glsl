#ifndef HILLAIRE_COMMON_INCLUDE
#define HILLAIRE_COMMON_INCLUDE

#include "/lib/atmosphere/common.glsl"

uniform sampler2D skyViewLUTTex;
uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;

const vec3 sunIrradiance = vec3(1.0, 0.949, 0.937) * 12.6;
const vec3 sunRadiance = sunIrradiance / sunAngularRadius;

// Units are in megameters.
const float groundRadiusMM = 6.360;
const float atmosphereRadiusMM = 6.460;

vec3 atmospherePos = vec3(0.0, groundRadiusMM + (cameraPosition.y + 200) * 1e-6, 0.0);

const vec2 tLUTRes = vec2(256.0, 64.0);
const vec2 msLUTRes = vec2(32.0, 32.0);
// Doubled the vertical skyViewLUT res from the paper, looks way
// better for sunrise.
const vec2 skyViewLUTRes = vec2(200.0, 200.0);

const vec3 groundAlbedo = vec3(0.3);

// These are per megameter.
const vec3 rayleighScatteringBase = vec3(5.802, 13.558, 33.1);
const float rayleighAbsorptionBase = 0.0;

const float mieScatteringBase = 3.996;
const float mieAbsorptionBase = 4.4;

const vec3 ozoneAbsorptionBase = vec3(0.650, 1.881, .085);

float getMiePhase(float cosTheta) {
  const float g = 0.8;
  const float scale = 3.0/(8.0*PI);
  
  float num = (1.0-g*g)*(1.0+cosTheta*cosTheta);
  float denom = (2.0+g*g)*pow((1.0 + g*g - 2.0*g*cosTheta), 1.5);
  
  return scale*num/denom;
}

float getRayleighPhase(float cosTheta) {
  const float k = 3.0/(16.0*PI);
  return k*(1.0+cosTheta*cosTheta);
}

void getScatteringValues(vec3 pos, 
             out vec3 rayleighScattering, 
             out float mieScattering,
             out vec3 extinction) {
  float altitudeKM = (length(pos)-groundRadiusMM)*1000.0;
  // Note: Paper gets these switched up.
  float rayleighDensity = exp(-altitudeKM/8.0);
  float mieDensity = exp(-altitudeKM/1.2);
  
  rayleighScattering = rayleighScatteringBase*rayleighDensity;
  float rayleighAbsorption = rayleighAbsorptionBase*rayleighDensity;
  
  mieScattering = mieScatteringBase*mieDensity;
  float mieAbsorption = mieAbsorptionBase*mieDensity;
  
  vec3 ozoneAbsorption = ozoneAbsorptionBase*max(0.0, 1.0 - abs(altitudeKM-25.0)/15.0);
  
  extinction = rayleighScattering + rayleighAbsorption + mieScattering + mieAbsorption + ozoneAbsorption;
}

float safeacos(const float x) {
  return acos(clamp(x, -1.0, 1.0));
}

// From https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
float rayIntersectSphere(vec3 ro, vec3 rd, float rad) {
  float b = dot(ro, rd);
  float c = dot(ro, ro) - rad*rad;
  if (c > 0.0f && b > 0.0) return -1.0;
  float discr = b*b - c;
  if (discr < 0.0) return -1.0;
  // Special case: inside sphere, use far discriminant
  if (discr > b*b) return (-b + sqrt(discr));
  return -b - sqrt(discr);
}

/*
 * Same parameterization here.
 */
vec3 getValFromTLUT(sampler2D tex, vec2 bufferRes, vec3 pos, vec3 sunDir) {
  float height = length(pos);
  vec3 up = pos / height;
	float sunCosZenithAngle = dot(sunDir, up);
  vec2 uv = vec2(tLUTRes.x*clamp(0.5 + 0.5*sunCosZenithAngle, 0.0, 1.0),
           tLUTRes.y*max(0.0, min(1.0, (height - groundRadiusMM)/(atmosphereRadiusMM - groundRadiusMM))));
  uv /= bufferRes;
  return texture(tex, uv).rgb;
}
vec3 getValFromMultiScattLUT(sampler2D tex, vec2 bufferRes, vec3 pos, vec3 sunDir) {
  float height = length(pos);
  vec3 up = pos / height;
	float sunCosZenithAngle = dot(sunDir, up);
  vec2 uv = vec2(msLUTRes.x*clamp(0.5 + 0.5*sunCosZenithAngle, 0.0, 1.0),
           msLUTRes.y*max(0.0, min(1.0, (height - groundRadiusMM)/(atmosphereRadiusMM - groundRadiusMM))));
  uv /= bufferRes;
  return texture(tex, uv).rgb;
}

#endif