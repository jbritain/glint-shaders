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
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  
  uniform sampler2D colortex0;
  uniform sampler2D colortex11;
  uniform sampler2D depthtex0;

  uniform float near;
  uniform float far;

  uniform float viewWidth;
  uniform float viewHeight;

  float linearizeDepth(float depth, float far, float near) {
	  return far * near / (far + (near - far) * depth);
  }

  #include "/lib/post/SMAA/SMAANeighborhoodBlending.glsl"

  in vec2 texcoord;


  /* RENDERTARGETS: 0 */
  layout(location = 0) out vec4 color;
  
  void main() {
    #ifdef SMAA
    color.rgb = SMAANeighborhoodBlending(colortex0, colortex11, texcoord, vec2(viewWidth, viewHeight));
    #else
    color = texture(colortex0, texcoord);
    #endif
  }
#endif