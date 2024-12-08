/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred4.glsl
    - Clouds
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
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;
  uniform sampler2D colortex9;

  uniform sampler2D depthtex2;

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



  /* DRAWBUFFERS:70 */
  layout(location = 0) out vec4 cloudData;
  layout(location = 1) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/dh.glsl"
  #include "/lib/atmosphere/aurora.glsl"


  void main() {

    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    dhOverride(depth, viewPos, false);
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(colortex0, texcoord);
    
    vec3 skyLightColor;
    vec3 sunlightColor;
    getLightColors(sunlightColor, skyLightColor, eyePlayerPos, vec3(0.0, 1.0, 0.0));

    vec3 cloudTransmittance = vec3(1.0);

    vec3 cloudScatter = getClouds(eyePlayerPos, depth, sunlightColor, skyLightColor, cloudTransmittance);

    vec3 screenPos = vec3(texcoord, depth);
    vec3 previousScreenPos = reprojectScreen(screenPos);
    previousScreenPos.z = texture(colortex4, previousScreenPos.xy).a;

    if(clamp01(previousScreenPos.xy) == previousScreenPos.xy && depth == previousScreenPos.z && lightningBoltPosition == vec4(0.0)){
      vec4 previousCloudData = texture(colortex7, previousScreenPos.xy);

      cloudScatter.rgb = mix(previousCloudData.rgb, cloudScatter.rgb, CLOUD_BLEND);
      cloudTransmittance.rgb = mix(vec3(previousCloudData.a), cloudTransmittance, CLOUD_BLEND);
    }

    // if(depth == 1.0){
    //   color.rgb += getAurora(normalize(eyePlayerPos));
    // }


    color.rgb = color.rgb * cloudTransmittance.rgb + cloudScatter.rgb;

    cloudData.rgb = cloudScatter;
    cloudData.a = mean(cloudTransmittance);

    vec3 p;
  }
#endif