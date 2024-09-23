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

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color.rgb = max0(texture(colortex0, texcoord).rgb);
    float luminance = dot(color.rgb, vec3(0.2125, 0.7154, 0.0721));
    color.a = log2(luminance + 1e-6);
  }
#endif