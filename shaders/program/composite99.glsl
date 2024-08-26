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
  uniform sampler2D colortex4;

  uniform sampler2D depthtex0;

  in vec2 texcoord;

  /* DRAWBUFFERS:4 */
  layout(location = 0) out vec4 previousFrameData;

  void main() {
    previousFrameData.rgb = texture(colortex0, texcoord).rgb;
    previousFrameData.a = texture(depthtex0, texcoord).a;

  }
#endif