/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite2.glsl
    - Cloud fog blur and blend
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

  uniform float near;
  uniform float far;

  uniform int isEyeInWater;
  uniform vec3 fogColor;
  uniform float fogDensity;
  uniform float fogStart;
  uniform float fogEnd;

  in vec2 texcoord;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/bilateralFilter.glsl"


  void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

    vec4 fogData = bilateralFilterDepth(colortex8, depthtex0, texcoord, 5, 10, 1.0, 0);

    color = texture(colortex0, texcoord);

    color.rgb = color.rgb * fogData.a + fogData.rgb;

    // if(isEyeInWater > 1){
      color.rgb = mix(color.rgb, fogColor, smoothstep(fogStart, fogEnd, length(viewPos)));
    // }
  }
#endif