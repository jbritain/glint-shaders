/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/volumetricFilter.glsl
    - Applies bilateral filter to any volumetric effects stored in colortexes 7 and 8

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

  uniform float far;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/bilateralFilter.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);

    vec3 cloudScatter = bilateral(colortex7, texcoord).rgb;
    vec3 cloudTransmittance = bilateral(colortex8, texcoord).rgb;

    color.rgb = color.rgb * cloudTransmittance + cloudScatter;
  }
#endif