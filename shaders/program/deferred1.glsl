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
  uniform sampler2D colortex8;

  uniform float viewWidth;
  uniform float viewHeight;


  in vec2 texcoord;


  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 outGI;

  #include "/lib/util/blur.glsl"

  void main() {
    outGI = blur13(colortex8, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0));
  }
#endif