/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred4.glsl
    - Cloud generation
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

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  #include "/lib/util/blur.glsl"

  /* DRAWBUFFERS:08 */
  layout(location = 0) out vec4 color;



  void main() {
    color = texture(colortex0, texcoord);
    color.rgb += blur1(colortex8, texcoord, vec2(viewWidth, viewHeight)).rgb;
  }
#endif