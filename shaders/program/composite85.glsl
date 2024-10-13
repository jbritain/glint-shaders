/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite85.glsl
    - SMAA Edge Detection
*/

#include "/lib/settings.glsl"

#ifdef vsh
  #define SMAA_INCLUDE_VS
  #include "/lib/post/SMAA.glsl"

  out vec2 texcoord;
  out vec4 offset[3];

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    SMAAEdgeDetectionVS(texcoord, offset);
  }
#endif

#ifdef fsh
  #define SMAA_INCLUDE_PS
  #include "/lib/post/SMAA.glsl"

  in vec2 texcoord;
  in vec4 offset[3];

  uniform sampler2D colortex0;
  uniform sampler2D colortex1;

  /* RENDERTARGETS: 11 */
  layout(location = 0) out vec4 edges;
  

  void main() {
    edges.rg = SMAAColorEdgeDetectionPS(texcoord, offset, colortex0
    #ifdef SMAA_PREDICATION
    , colortex1
    #endif
    );
  }
#endif