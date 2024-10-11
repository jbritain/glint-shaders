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
  uniform sampler2D colortex8;

  uniform sampler2D depthtex0;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  in vec2 texcoord;

  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 fogData;

  #include "/lib/util.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/spaceConversions.glsl"


  void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

    float dist = length(viewPos);
    // prevent fog blurring over block edges
    if(length(vec2(dFdx(dist), dFdy(dist))) > 1.0){
      fogData = texture(colortex8, texcoord);
      return;
    }

    fogData = blur13(colortex8, texcoord, vec2(viewWidth, viewHeight), vec2(1.0, 0.0));
  }
#endif