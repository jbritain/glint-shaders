#ifndef HILLAIRE_ATMOSPHERE_INCLUDE
#define HILLAIRE_ATMOSPHERE_INCLUDE

#include "/lib/atmosphere/common.glsl"

uniform sampler2D colortex12;

const vec2 tLUTRes = vec2(256.0, 64.0);
const vec2 msLUTRes = vec2(32.0, 32.0);
const vec2 skyLUTRes = vec2(256.0, 256.0);

const float groundRadiusMM = earthRadius / 1e6;
const float atmosphereRadiusMM = atmosphereRadius  / 1e6;

const vec3 groundAlbedo = vec3(0.3);

// These are per megameter.
const vec3 rayleighScatteringBase = vec3(5.802, 13.558, 33.1);
const float rayleighAbsorptionBase = 0.0;

const float mieScatteringBase = 3.996;
const float mieAbsorptionBase = 4.4;

const vec3 ozoneAbsorption = vec3(0.650, 1.881, .085);

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

void getScatteringValues(const in vec3 pos, out vec3 rayleighScattering, out float mieScattering, out vec3 extinction) {
    float altitudeKM = (length(pos) - groundRadiusMM) * 1000.0;
    // Note: Paper gets these switched up.
    float rayleighDensity = exp(-altitudeKM / 8.0);
    float mieDensity = exp(-altitudeKM / 1.2);
    
    rayleighScattering = rayleighScatteringBase * rayleighDensity;
    
    mieScattering = mieScatteringBase * mieDensity;
    
    extinction = rayleighScattering + rayleighAbsorptionBase + mieScattering + mieAbsorptionBase + ozoneAbsorption;
}

uniform sampler3D scatteringtex;
uniform sampler3D transmissiontex;

vec3 getAtmosLUT_UV(const in float sunCosZenithAngle, const in float elevation) {
    vec3 uv;
    uv.x = 0.5 + 0.5*sunCosZenithAngle;
    uv.y = (elevation - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM);
    uv.z = 0.0;

    return uv;
}

vec3 getValFromTLUT(const in vec3 pos, const in vec3 sunDir) {
    float height = length(pos);
    vec3 up = pos / height;

    float sunCosZenithAngle = dot(sunDir, up);
    vec3 uv = getAtmosLUT_UV(sunCosZenithAngle, height);
    
    return textureLod(transmissiontex, uv, 0).rgb;
}

vec3 getValFromMultiScattLUT(const in vec3 pos, const in vec3 sunDir) {
    float height = length(pos);
    vec3 up = pos / height;

    float sunCosZenithAngle = dot(sunDir, up);
    vec3 uv = getAtmosLUT_UV(sunCosZenithAngle, height);
    
    return textureLod(scatteringtex, uv, 0).rgb;
}

float safeacos(const float x) {
    return acos(clamp(x, -1.0, 1.0));
}

vec3 getValFromSkyLUT(const in vec3 localViewDir) {
    float height = kCamera.y / 1e6;

    const vec3 up = vec3(0.0, 1.0, 0.0);

    float horizonAngle = safeacos(sqrt(height * height - groundRadiusMM * groundRadiusMM) / height);
    float altitudeAngle = horizonAngle - acos(dot(localViewDir, up)); // Between -PI/2 and PI/2
    float azimuthAngle; // Between 0 and 2*PI

    if (abs(altitudeAngle) > (0.5*PI - 0.0001)) {
        // Looking nearly straight up or down.
        azimuthAngle = 0.0;
    } else {
        vec3 right = vec3(1.0, 0.0, 0.0);
        vec3 forward = vec3(0.0, 0.0, -1.0);

        vec3 projectedDir = normalize(localViewDir - up*(dot(localViewDir, up)));
        float sinTheta = dot(projectedDir, right);
        float cosTheta = dot(projectedDir, forward);
        azimuthAngle = atan(sinTheta, cosTheta) + PI;
    }
    
    // Non-linear mapping of altitude angle. See Section 5.3 of the paper.
    float v = 0.5 + 0.5 * sign(altitudeAngle) * sqrt(abs(altitudeAngle) * 2.0 / PI);
    vec2 uv = vec2(azimuthAngle / TAU, v);
    
    return textureLod(colortex12, uv, 0).rgb;
}

#endif