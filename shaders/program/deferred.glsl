/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred.glsl
    - Global illumination
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

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
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex4;
  uniform sampler2D colortex6;
  uniform sampler2D colortex9;
  uniform sampler2D colortex10;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex2;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;
  uniform sampler2D shadowcolor2;

  uniform sampler2D noisetex;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;

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

  in vec2 texcoord;

  



  /* RENDERTARGETS: 10 */
  layout(location = 0) out vec4 outGI;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/lighting/shadowBias.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/util/dh.glsl"
  #include "/lib/lighting/SSGI.glsl"
  #include "/lib/util/blur.glsl"

  void main() {
    #ifdef GLOBAL_ILLUMINATION
    vec2 texcoord = texcoord * rcp(GI_RESOLUTION);
    if(clamp01(texcoord) != texcoord){
      return;
    }
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    dhOverride(depth, viewPos, false);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    if(depth == 1.0){
      return;
    }

    GbufferData gbufferData;
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord), gbufferData);

    vec3 reprojectedScreenPos = reprojectScreen(vec3(texcoord, depth));
    vec3 previousScreenPos = vec3(reprojectedScreenPos.xy, texture(colortex4, texcoord).a);

    vec3 reprojectedViewPos = previousScreenSpaceToPreviousViewSpace(reprojectedScreenPos);
    vec3 previousViewPos = previousScreenSpaceToPreviousViewSpace(previousScreenPos);

    float acceptPreviousFrame = float(distance(reprojectedViewPos, previousViewPos) <= 1.0);
    acceptPreviousFrame -= float(clamp01(previousScreenPos.xy) != previousScreenPos.xy);
    acceptPreviousFrame = clamp01(acceptPreviousFrame);

    outGI = texture(colortex10, previousScreenPos.xy) * acceptPreviousFrame;
    outGI.rgb = mix(outGI.rgb, SSGI(viewPos, gbufferData.mappedNormal, gbufferData.lightmap), 1.0 / (outGI.a + 1.0));
    outGI.a += 1.0;

    outGI.a = min(outGI.a, 60.0);

    #endif

  }
#endif