/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite2.glsl
    - Cloud fog blur
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
  uniform sampler2D colortex0;
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex8;

  uniform sampler2D depthtex0;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform vec3 cameraPosition;
  uniform ivec2 eyeBrightnessSmooth;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int isEyeInWater;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 reflectedColor;

  #include "/lib/util.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/gbufferData.glsl"

  void main() {
    // TODO: how the fuck do I denoise reflections
    reflectedColor = texture(colortex8, texcoord);
  }
#endif