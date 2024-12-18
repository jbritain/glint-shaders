/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare2.glsl
    - Sky irradiance map
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex9;
  

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowProjection;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec4 lightningBoltPosition;

  uniform int worldTime;
  uniform int worldDay;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float far;
  uniform float wetness;
  uniform float thunderStrength;
  uniform int isEyeInWater;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform ivec2 eyeBrightnessSmooth;

  uniform bool hasSkylight;

  uniform sampler2D noisetex;


  in vec2 texcoord;

  /* RENDERTARGETS: 12 */
  layout(location = 0) out vec3 color;

  #include "/lib/util.glsl"
  #include "/lib/atmosphere/hillaireAtmosphere.glsl"

  const int numScatteringSteps = 40;

vec3 raymarchScattering(const in vec3 pos, const in vec3 rayDir, const in vec3 sunDir, const in float tMax) {
  const int numScatteringSteps = 32;

  float cosTheta = dot(rayDir, sunDir);
  float miePhaseValue = getMiePhase(cosTheta);
  float rayleighPhaseValue = getRayleighPhase(-cosTheta);
  
  float t = 0.0;
  vec3 lum = vec3(0.0);
  vec3 transmittance = vec3(1.0);

  for (float i = 0.0; i < numScatteringSteps; i += 1.0) {
    float newT = ((i + 0.3) / numScatteringSteps) * tMax;
    float dt = newT - t;
    t = newT;
        
    vec3 newPos = pos + t*rayDir;
        
    vec3 rayleighScattering, extinction;
    float mieScattering;
    getScatteringValues(newPos, rayleighScattering, mieScattering, extinction);
        
    vec3 sampleTransmittance = exp(-dt*extinction);

    vec3 sunTransmittance = getValFromTLUT(newPos, sunDir);
    vec3 psiMS = getValFromMultiScattLUT(newPos, sunDir);
        
    vec3 rayleighInScattering = rayleighScattering * (rayleighPhaseValue*sunTransmittance + psiMS);
    vec3 mieInScattering = mieScattering * (miePhaseValue*sunTransmittance + psiMS);
    vec3 inScattering = (rayleighInScattering + mieInScattering);

    // Integrated scattering within path segment.
    vec3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

    lum += scatteringIntegral * transmittance;
    
    transmittance *= sampleTransmittance;
  }

  return lum;
}

  void main() {
    float u = texcoord.x;
    float v = texcoord.y;

    float azimuthAngle = (u - 0.5)*2.0*PI;
    // Non-linear mapping of altitude. See Section 5.3 of the paper.
    float adjV;
    if (v < 0.5) {
      float coord = 1.0 - 2.0*v;
      adjV = -coord*coord;
    } else {
      float coord = v*2.0 - 1.0;
      adjV = coord*coord;
    }
    
    float height = length(kCamera);
    vec3 up = kCamera / height;
    float horizonAngle = safeacos(sqrt(height * height - groundRadiusMM * groundRadiusMM) / height) - 0.5*PI;
    float altitudeAngle = adjV*0.5*PI - horizonAngle;
    
    float cosAltitude = cos(altitudeAngle);
    vec3 rayDir = vec3(cosAltitude*sin(azimuthAngle), sin(altitudeAngle), -cosAltitude*cos(azimuthAngle));
    
    float atmoDist = rayIntersectSphere(kCamera / 1e6, rayDir, atmosphereRadiusMM);
    float groundDist = rayIntersectSphere(kCamera / 1e6, rayDir, groundRadiusMM);
    float tMax = (groundDist < 0.0) ? atmoDist : groundDist;
    vec3 lum = raymarchScattering(kCamera / 1e6, rayDir, sunVector, tMax);
    color = lum;
    show(color);
  }
#endif