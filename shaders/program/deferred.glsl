/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred.glsl
    - Reflective shadow map global illumination
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

#ifdef vsh
  out vec2 texcoord;

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

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

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

  void main() {
    outGI = texture(colortex10, texcoord);
    vec2 texcoord = texcoord * 2.0;
    if(clamp01(texcoord) != texcoord){
      return;
    }
    #ifdef GLOBAL_ILLUMINATION
    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    dhOverride(depth, viewPos, false);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    if(depth == 1.0){
      return;
    }

    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    vec3 previousFeetPlayerPos = feetPlayerPos + (cameraPosition - previousCameraPosition);
    vec3 previousViewPos = (gbufferPreviousModelView * vec4(previousFeetPlayerPos, 1.0)).xyz;
    vec3 previousScreenPos = previousViewSpaceToPreviousScreenSpace(previousViewPos);
    // previousScreenPos.z = texture(colortex4, texcoord).a;
    // previousViewPos = previousScreenSpaceToPreviousViewSpace(previousScreenPos);
    // previousFeetPlayerPos = (gbufferPreviousModelViewInverse * vec4(previousViewPos, 1.0)).xyz;

    vec3 GI = SSGI(viewPos, faceNormal);
    outGI.rgb = GI;

    
    // outGI.rgb = reflectShadowMap(faceNormal, feetPlayerPos, sunlightColor);
    #endif

  }
#endif