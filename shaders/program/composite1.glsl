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
  uniform sampler2D colortex0;
  uniform sampler2D colortex3;

  uniform sampler2D depthtex0;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  #include "/lib/util/blur.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    float depth = texture(depthtex0, texcoord).r;
    color = texture(colortex0, texcoord);

    vec4 cloud;

    if(depth == 1.0){
      cloud = blur13(colortex3, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0));
    } else {
      cloud = texture(colortex3, texcoord);
    }


    color.rgb = mix(color.rgb, cloud.rgb, cloud.a);
  }
#endif