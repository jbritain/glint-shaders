/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare1.glsl
    - Sky environment map
*/

#include "/lib/settings.glsl"
#define HIGH_CLOUD_SAMPLES
#define GENERATE_SKY_LUT

#ifdef vsh
  out vec2 texcoord;

  uniform vec3 cameraPosition;
  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform mat4 gbufferModelViewInverse;
  uniform ivec2 eyeBrightnessSmooth;
  uniform float far;



  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex9;
  uniform sampler2D colortex6;

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
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/uvmap.glsl"

  /* DRAWBUFFERS:9 */
  layout(location = 0) out vec4 color;

  void main() {

    vec3 dir = unmapSphere(texcoord);

    color.rgb = getSky(color, dir, false);

    vec3 skyLightColor;
    vec3 sunlightColor;
    getLightColors(sunlightColor, skyLightColor, vec3(0.0), vec3(0.0, 1.0, 0.0));


    vec3 cloudTransmittance;
    vec3 cloudScatter = getClouds(dir * far, 1.0, sunlightColor, skyLightColor, cloudTransmittance.rgb);

    color.rgb *= cloudTransmittance;
    color.rgb += cloudScatter;

    // if(isEyeInWater == 1){
    //   float distanceBelowSeaLevel = mix(128, max0(-1 * (cameraPosition.y - 63)), clamp01(dir.y));

    //   color.rgb *= exp(-clamp01(WATER_ABSORPTION + WATER_SCATTERING) * distanceBelowSeaLevel);
    // }
  }
#endif