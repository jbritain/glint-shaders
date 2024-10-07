/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/final.glsl
    - Bloom blending
    - Anti Aliasing
    - Tonemapping
    - Debug rendering
*/

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
  uniform sampler2D colortex0;
  uniform sampler2D colortex3;

  uniform sampler2D depthtex0;

  uniform sampler2D debugtex;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform sampler2D watermarktex;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/post/FXAA.glsl"
  #include "/lib/textures/blueNoise.glsl"

  layout(location = 0) out vec4 color;

  void main() {
    
    color = texture(colortex0, texcoord);

    color.rgb = FXAA311(color.rgb);

    vec3 bloom = texture(colortex3, texcoord).rgb;

    #ifdef BLOOM
    color.rgb = mix(color.rgb, bloom, 0.01 * BLOOM_STRENGTH);
    #endif

    #ifdef WATERMARK
    ivec2 watermarkCoord = ivec2(vec2(2 * gl_FragCoord.x, viewHeight) - gl_FragCoord.xy);
    watermarkCoord.x -= (int(viewWidth) - 300);
    watermarkCoord.y -= (int(viewHeight) - 200);
    vec4 watermark = texelFetch(watermarktex, watermarkCoord, 0);
    color.rgb = mix(color.rgb, bloom.rgb, watermark.a);
    #endif

    color.rgb = tonemap(color.rgb);

    color.rgb = setSaturationLevel(color.rgb, SATURATION);

    color.rgb = invGammaCorrect(color.rgb);

    #ifdef DEBUG_ENABLE
    color = texture(debugtex, texcoord);
    #endif


  }
#endif