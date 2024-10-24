/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite3.glsl
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
  uniform sampler2D colortex8;

  uniform sampler2D depthtex0;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/spaceConversions.glsl"


  void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

    vec4 fogData;

    float dist = length(viewPos);
    // prevent fog blurring over block edges
    if(length(vec2(dFdx(dist), dFdy(dist))) > 1.0){
      fogData = blur1(colortex8, texcoord, vec2(viewWidth, viewHeight));
    } else {
      fogData = blur13(colortex8, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0));
    }

    color = texture(colortex0, texcoord);

    color.rgb = color.rgb * fogData.a + fogData.rgb;
  }
#endif