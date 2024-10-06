/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred1.glsl
    - Global illumination filtering - horizontal
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
  uniform sampler2D colortex10;

  uniform float viewWidth;
  uniform float viewHeight;


  in vec2 texcoord;


  /* RENDERTARGETS: 10 */
  layout(location = 0) out vec4 outGI;

  #include "/lib/util/blur.glsl"

  void main() {
    outGI.rgb = blur13(colortex10, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0)).rgb;
    outGI.a = texture(colortex10, texcoord).a;
  }
#endif