/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/volumetricUpscale.glsl
    - Upscales any volumetric effects stored in colortexes 7 and 8 to full resolution

    **THIS PROGRAM RUNS MULTIPLE TIMES**
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
  uniform sampler2D depthtex0;

  uniform sampler2D colortex0;
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  in vec2 texcoord;

  /* DRAWBUFFERS:78 */
  layout(location = 0) out vec4 cloudScatter;
  layout(location = 1) out vec4 cloudTransmittance;

  void main() {
    cloudScatter.rgb = texture(colortex7, texcoord * VOLUMETRIC_RESOLUTION).rgb;
    cloudTransmittance.rgb = texture(colortex8, texcoord * VOLUMETRIC_RESOLUTION).rgb;
  }
#endif