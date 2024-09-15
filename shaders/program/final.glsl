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
  const bool colortex0MipmapEnabled = true;;

  uniform sampler2D colortex0;
  uniform sampler2D colortex3;

  uniform sampler2D depthtex0;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/postProcessing/tonemap.glsl"
  #include "/lib/postProcessing/FXAA.glsl"

  layout(location = 0) out vec4 color;

  void main() {
    
    color = texture(colortex0, texcoord);

    color.rgb = FXAA311(color.rgb);

    vec3 bloom = texture(colortex3, texcoord).rgb;

    color.rgb = mix(color.rgb, bloom, 0.01 * BLOOM_STRENGTH);

    color.rgb = tonemap(color.rgb);

    color.rgb = setSaturationLevel(color.rgb, 1.2);

    color.rgb = invGammaCorrect(color.rgb);
  }
#endif