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

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/gbufferData.glsl"

  void main() {
    float depth = texture(depthtex0, texcoord).r;
    color = texture(colortex0, texcoord);

    if(depth == 1.0){
      return;
    }

    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    vec4 reflectedColor;
    
    reflectedColor = blur1(colortex8, texcoord, vec2(viewWidth, viewHeight));


    color.rgb += reflectedColor.rgb;

    if((isEyeInWater == 1) != materialIsWater(materialID)){
      color = getAtmosphericFog(color, eyePlayerPos);
    }
  }
#endif