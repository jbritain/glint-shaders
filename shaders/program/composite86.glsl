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
  #define SMAA_INCLUDE_VS
  #include "/lib/post/SMAA.glsl"

  out vec2 texcoord;
  out vec2 pixcoord;
  out vec4 offset[3];

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
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
  in vec2 pixcoord;
  in vec4 offset[3];

  /* RENDERTARGETS: 11,0 */
  layout(location = 0) out vec4 blendWeight;
  layout(location = 1) out vec4 color;
  

  void main() {
    color = texture(colortex0, texcoord);
    color.rgb = invGammaCorrect(color.rgb);
    blendWeight = SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, colortex11, areaTex, searchTex, vec4(0.0));
    // show(blendWeight);
  }
#endif