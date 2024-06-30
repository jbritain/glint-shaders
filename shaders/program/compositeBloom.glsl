#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    #ifdef BLOOM_FIRST
    texcoord *= BLOOM_BLUR;
    #endif
  }
#endif

#ifdef fsh

  #ifdef BLOOM
  #include "/lib/blur.glsl"
  
  uniform sampler2D colortex0;
  uniform sampler2D colortex8;
  uniform vec2 resolution;
  in vec2 texcoord;

  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 color;

  #ifdef BLOOM_HORIZONTAL
    vec2 dir = vec2(1.0, 0.0);
  #else
    vec2 dir = vec2(0.0, 1.0);
  #endif

  void main() {

    #ifdef BLOOM_FIRST
    #define sampleTex colortex0
    #else
    #define sampleTex colortex8
    #endif

    color = BLUR(sampleTex, texcoord, resolution, dir);
  }
  #else
  void main(){
    discard;
  }
  #endif
#endif