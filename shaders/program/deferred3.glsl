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

  uniform sampler2D colortex0;
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  in vec2 texcoord;

  #include "/lib/util/bilateralFilter.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;

    vec3 cloudScatter;
    vec3 cloudTransmittance;

    if(depth == 1.0){
      cloudScatter = bilateral(colortex7, texcoord).rgb;
      cloudTransmittance = bilateral(colortex8, texcoord).rgb;
    } else {
      cloudScatter = texture(colortex7, texcoord).rgb;
      cloudTransmittance = texture(colortex8, texcoord).rgb;
    }


    // 

    color.rgb = color.rgb * cloudTransmittance + cloudScatter;
  }
#endif