/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite1.glsl
    - Cloud fog
*/

#include "/lib/settings.glsl"

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
  uniform sampler2D colortex0;
  uniform sampler2D colortex4;
  uniform sampler2D colortex6;
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;
  uniform sampler2D colortex9;

  uniform sampler2D shadowtex0;
  uniform sampler2D shadowtex1;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;

  uniform sampler2D depthtex0;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec4 lightningBoltPosition;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float frameTimeCounter;
  uniform int worldTime;
  uniform int worldDay;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform float wetness;
  uniform float thunderStrength;

  uniform float near;
  uniform float far;

  uniform int isEyeInWater;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform ivec2 eyeBrightnessSmooth;

  uniform sampler2D noisetex;

  in vec2 texcoord;



  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 fogData;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"
  #include "/lib/util/dh.glsl"


  void main() {
    // TODO: VOLUMETRIC FOG BEHIND TRANSLUCENTS
    if(isEyeInWater != 0){
      fogData.a = 1.0;
      return;
    }

    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    dhOverride(depth, viewPos, false);
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    vec3 skyLightColor;
    vec3 sunlightColor;
    getLightColors(sunlightColor, skyLightColor, eyePlayerPos, vec3(0.0, 1.0, 0.0));

    vec3 fogTransmittance = vec3(1.0);

    vec3 fogScatter = hasSkylight ? getCloudFog(vec3(0.0), eyePlayerPos, depth, sunlightColor, skyLightColor, fogTransmittance) : vec3(0.0);

    fogData.rgb = fogScatter;
    fogData.a = min3(fogTransmittance);

  }
#endif