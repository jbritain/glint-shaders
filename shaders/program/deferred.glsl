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

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/postProcessing/tonemap.glsl"
  #include "/lib/atmosphere/sky.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);
  }
#endif