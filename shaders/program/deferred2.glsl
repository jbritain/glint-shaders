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
  uniform sampler2D colortex3;

  uniform float viewWidth;
  uniform float viewHeight;

  #include "/lib/util/blur.glsl"

  in vec2 texcoord;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;

    vec4 cloudColor;

    if(depth == 1.0){
      cloudColor = blur13(colortex3, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0));
    } else {
      cloudColor = texture(colortex3, texcoord);
    }

    color.rgb = mix(color.rgb, cloudColor.rgb, cloudColor.a);
    
  }
#endif