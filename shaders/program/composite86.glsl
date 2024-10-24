/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite86.glsl
    - SMAA Blending Weight Calculation
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
  uniform sampler2D depthtex0;
  uniform sampler2D colortex11;

  uniform sampler2D areaTex;
  uniform sampler2D searchTex;

  uniform float near;
  uniform float far;

  uniform float viewWidth;
  uniform float viewHeight;

  float linearizeDepth(float depth, float far, float near) {
	  return far * near / (far + (near - far) * depth);
  }

  #include "/lib/post/SMAA/SMAABlendingWeightCalculation.glsl"

  in vec2 texcoord;


  /* RENDERTARGETS: 11 */
  layout(location = 0) out vec4 blendWeights;
  
  void main() {
    #ifdef SMAA
    blendWeights = SMAABlendingWeightCalculation(colortex11, areaTex, searchTex, texcoord, vec2(viewWidth, viewHeight));
    #endif
  }
#endif