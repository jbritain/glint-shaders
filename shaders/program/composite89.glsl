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
  uniform sampler2D colortex5;

  uniform int frameCounter;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex2;

  in vec2 texcoord;

  /* DRAWBUFFERS:04 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 previousFrameData1;

  void main() {
    previousFrameData1.rgb = texture(colortex0, texcoord).rgb;
    previousFrameData1.a = texture(depthtex0, texcoord).r;

    color = texture(colortex0, texcoord);
    vec4 hand = texture(colortex5, texcoord);
    color.rgb = mix(color.rgb, hand.rgb, hand.a);

    color.rgb *= pow(2, EXPOSURE);

  }
#endif