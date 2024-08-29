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

    const ivec2 offsets[4] = ivec2[](
      ivec2(CLOUD_BLUR_RADIUS_THRESHOLD, 0.0),
      ivec2(0.0, CLOUD_BLUR_RADIUS_THRESHOLD),
      ivec2(-1.0 * CLOUD_BLUR_RADIUS_THRESHOLD, 0.0),
      ivec2(0.0, -1.0 * CLOUD_BLUR_RADIUS_THRESHOLD)
    );

    vec4 cloudColor;

    float depth = texture(depthtex0, texcoord).r;
    if(depth == 1.0 && all(equal(textureGatherOffsets(depthtex0, texcoord, offsets), vec4(1.0)))){
      cloudColor = blur13(colortex3, texcoord, vec2(viewWidth, viewHeight), vec2(0.0, 1.0));
    } else {
      cloudColor = texture(colortex3, texcoord);
    }

    color.rgb = mix(color.rgb, cloudColor.rgb, cloudColor.a);
    
  }
#endif