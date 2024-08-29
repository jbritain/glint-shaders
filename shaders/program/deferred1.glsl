#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D depthtex0;

  uniform sampler2D colortex3;

  uniform float viewWidth;
  uniform float viewHeight;

  #include "/lib/util/blur.glsl"

  in vec2 texcoord;

  /* DRAWBUFFERS:3 */
  layout(location = 0) out vec4 cloudColor;

  void main() {
    float depth = texture(depthtex0, texcoord).r;
    if(depth == 1.0){
      cloudColor = blur13(colortex3, texcoord, vec2(viewWidth, viewHeight), vec2(1.0, 0.0));
    } else {
      cloudColor = texture(colortex3, texcoord);
    }
  }
#endif