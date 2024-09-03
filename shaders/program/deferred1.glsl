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

  uniform sampler2D colortex5;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float near;
  uniform float far;

  #include "/lib/util/blur.glsl"
  #include "/lib/util.glsl"

  in vec2 texcoord;

  /* DRAWBUFFERS:5 */
  layout(location = 0) out vec4 cloudColor;

  void main() {
    // sample within this radius and check if the depth is the sky or not. It must all be sky to blur, we can't blur on top of terrain.
    const ivec2 offsets[4] = ivec2[](
      ivec2(CLOUD_BLUR_RADIUS_THRESHOLD, 0.0),
      ivec2(0.0, CLOUD_BLUR_RADIUS_THRESHOLD),
      ivec2(-1.0 * CLOUD_BLUR_RADIUS_THRESHOLD, 0.0),
      ivec2(0.0, -1.0 * CLOUD_BLUR_RADIUS_THRESHOLD)
    );

    float depth = texture(depthtex0, texcoord).r;
    if(depth == 1.0 && all(equal(textureGatherOffsets(depthtex0, texcoord, offsets), vec4(1.0)))){
      cloudColor = blur13(colortex5, texcoord, vec2(viewWidth, viewHeight), vec2(1.0, 0.0));
    } else {
      cloudColor = texture(colortex5, texcoord);
    }
  }
#endif