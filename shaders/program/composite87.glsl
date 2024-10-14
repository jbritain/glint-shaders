/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite87.glsl
    - SMAA Blending
*/

#include "/lib/settings.glsl"

#ifdef vsh
  #define SMAA_INCLUDE_VS
  #include "/lib/post/SMAA.glsl"

  out vec2 texcoord;
  out vec4 offset;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    SMAANeighborhoodBlendingVS(texcoord, offset);
  }
#endif

#ifdef fsh
  #define SMAA_INCLUDE_PS
  #include "/lib/post/SMAA.glsl"
  #include "/lib/post/tonemap.glsl"

  uniform sampler2D areaTex;
  uniform sampler2D searchTex;
  uniform sampler2D colortex0;
  uniform sampler2D colortex11;

  in vec2 texcoord;
  in vec4 offset;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;
  

  void main() {
    vec4 oldColor = texture(colortex0, texcoord);
    color = SMAANeighborhoodBlendingPS(texcoord, offset, colortex0, colortex11);
    color.rgb = gammaCorrect(color.rgb);

  }
#endif