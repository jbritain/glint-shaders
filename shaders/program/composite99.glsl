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

  /* DRAWBUFFERS:40 */
  layout(location = 0) out vec4 previousFrameData;
  layout(location = 1) out vec4 color;

  void main() {
    // color = vec4(texture(colortex4, texcoord).rgb - texture(colortex0, texcoord).rgb, 1.0);
    previousFrameData.rgb = texture(colortex0, texcoord).rgb;
    previousFrameData.a = texture(depthtex0, texcoord).r;

  }
#endif