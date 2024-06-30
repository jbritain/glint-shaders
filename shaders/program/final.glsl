#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }

#endif
//------------------------------------------------------------------
#ifdef fsh
  #define DEBUG_ENABLE
  #define DEBUG_TEX colortex8

  #ifdef DEBUG_ENABLE
  // uniform sampler2D DEBUG_TEX;
  #endif

  uniform sampler2D colortex0;
  uniform sampler2D colortex8;

  in vec2 texcoord;

  #include "/lib/tonemap.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    
    color = texture(colortex0, texcoord);
    color += texture(colortex8, texcoord / BLOOM_BLUR) * BLOOM_AMOUNT;
    color.rgb = tonemap(color.rgb);
    color.rgb = invGammaCorrect(color.rgb);

    #ifdef DEBUG_ENABLE
      color = texture(DEBUG_TEX, texcoord / BLOOM_BLUR);
    #endif
  }
#endif