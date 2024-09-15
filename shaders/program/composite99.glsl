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
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex3;
  uniform sampler2D colortex4;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;

  in vec2 texcoord;

  /* DRAWBUFFERS:43 */
  layout(location = 0) out vec4 previousFrameData1;
  layout(location = 1) out vec4 bloomColor;

  void main() {
    previousFrameData1.rgb = texture(colortex0, texcoord).rgb;
    previousFrameData1.a = texture(depthtex0, texcoord).r;

    bloomColor = texture(colortex3, texcoord / 2);

  }
#endif