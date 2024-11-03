/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred1.glsl
    - Global illumination filtering
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"


#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  const bool colortex10MipmapEnabled = true;

  uniform sampler2D colortex10;
  uniform sampler2D depthtex0;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float near;
  uniform float far;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;


  in vec2 texcoord;

  const bool colortex4MipmapEnabled = true;


  /* RENDERTARGETS: 10 */
  layout(location = 0) out vec4 outGI;

  #include "/lib/util/blur.glsl"
  #include "/lib/util/bilateralFilter.glsl"

  void main() {
    #ifdef GLOBAL_ILLUMINATION
    outGI.a = texture(colortex10, texcoord).a;

    if(max2(texcoord) > GI_RESOLUTION){
      return;
    }

    outGI.rgb = bilateralFilterDepth(colortex10, depthtex0, texcoord, 10, 10, GI_RESOLUTION, 4).rgb;
    #endif
  }
#endif