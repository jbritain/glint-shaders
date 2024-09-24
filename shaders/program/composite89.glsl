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

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float frameTime;

  in vec2 texcoord;

  #ifdef AUTO_EXPOSURE
  const bool colortex0MipmapEnabled = true;

  layout(std430, binding = 0) buffer frameData {
    float averageLuminanceSmooth;
  };
  #endif

  #include "/lib/util.glsl"

  /* DRAWBUFFERS:04 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 previousFrameData1;

  void main() {
    previousFrameData1.rgb = texture(colortex0, texcoord).rgb;
    previousFrameData1.a = texture(depthtex0, texcoord).r;

    color = texture(colortex0, texcoord);

    vec4 hand = texture(colortex5, texcoord);
    color.rgb = mix(color.rgb, hand.rgb, hand.a);

    #ifdef AUTO_EXPOSURE
    int maxMipLevel = int(floor(log2(max(viewWidth, viewHeight))));

    float averageLuminance = textureLod(colortex0, vec2(0.5), maxMipLevel).a;
    averageLuminance = exp2(averageLuminance);

    averageLuminanceSmooth = mix(averageLuminance, averageLuminanceSmooth, clamp01(exp2(frameTime * -0.001)));
    averageLuminanceSmooth = max(averageLuminanceSmooth, 0.0001);

    float exposure = rcp(9.6 * averageLuminanceSmooth);

    exposure = clamp(exposure, 0.001, 100.0);


    color *= exposure;

    // color.rgb = vec3(averageLuminance);
    #else
    color.rgb *= pow2(float(EXPOSURE) / 10.0);
    #endif

  }
#endif