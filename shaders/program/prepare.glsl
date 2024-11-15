/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare.glsl
    - Cloud shadow map
*/

#include "/lib/settings.glsl"
#define HIGH_CLOUD_SAMPLES
#define GENERATE_SKY_LUT

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
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

  #include "/lib/util.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/atmosphere/clouds.glsl"

  void marchCloudLayerShadow(inout vec3 totalTransmittance, vec3 playerOrigin, float lowerHeight, float upperHeight, int samples){
    vec3 worldDir = lightVector;

    samples = int(ceil(mix(samples * 0.75, float(samples), worldDir.y)));

    // we trace from a to b
    vec3 a;
    vec3 b;

    vec3 worldOrigin = playerOrigin + cameraPosition;

    if(!raySphereIntersectionPlanet(worldOrigin, worldOrigin.y <= lowerHeight ? worldDir : -worldDir, lowerHeight, a)){
      totalTransmittance = vec3(1.0);
      return;
    }
    if(!raySphereIntersectionPlanet(worldOrigin, worldOrigin.y <= upperHeight ? worldDir : -worldDir, upperHeight, b)){
      totalTransmittance = vec3(1.0);
    }
    
    vec3 rayPos = a;
    vec3 increment = (b - a) / samples;

    float jitter = blueNoise(texcoord).r;
    rayPos += increment * jitter;

    for(int i = 0; i < samples; i++, rayPos += increment){

      float density = getCloudDensity(rayPos) * length(increment);
      // density = mix(density, 0.0, smoothstep(CLOUD_DISTANCE * 0.8, CLOUD_DISTANCE, length(rayPos.xz - cameraPosition.xz)));

      if(density < 1e-6){
        continue;
      }

      vec3 transmittance = exp(-density * CLOUD_EXTINCTION_COLOR);
      totalTransmittance *= transmittance;

      if(max3(totalTransmittance) < 0.01){
        break;
      }
  }
}

  /* DRAWBUFFERS:6 */
  layout(location = 0) out vec4 color;

  void main() {
    color = vec4(1.0);

    #if !defined WORLD_OVERWORLD || !defined CLOUD_SHADOWS
    return;
    #endif

    vec3 shadowScreenPos = vec3(texcoord, 1.0);
    vec3 shadowNDCPos = shadowScreenPos * 2.0 - 1.0;
    vec4 shadowHomPos = shadowProjectionInverse * vec4(shadowNDCPos, 1.0);
    shadowHomPos.xy /= (shadowDistance / far);
    vec3 shadowViewPos = shadowHomPos.xyz / shadowHomPos.w;

    vec3 feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
    vec3 rayPos;

    vec3 totalTransmittance = vec3(1.0);

    #ifdef VANILLA_CLOUDS
    marchCloudLayerShadow(totalTransmittance, feetPlayerPos, VANILLA_CLOUD_LOWER_HEIGHT, VANILLA_CLOUD_UPPER_HEIGHT, VANILLA_CLOUD_SAMPLES);
    #endif
    #ifdef CUMULUS_CLOUDS
    marchCloudLayerShadow(totalTransmittance, feetPlayerPos, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, CUMULUS_SAMPLES);
    #endif
    #ifdef ALTOCUMULUS_CLOUDS
    marchCloudLayerShadow(totalTransmittance, feetPlayerPos, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, ALTOCUMULUS_SAMPLES);
    #endif
    #ifdef CIRRUS_CLOUDS
    marchCloudLayerShadow(totalTransmittance, feetPlayerPos, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, CIRRUS_SAMPLES);
    #endif

    color.rgb = totalTransmittance;
    color.a = 1.0;
  }
#endif