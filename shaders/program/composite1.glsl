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
  const bool colortex3MipmapEnabled = true;

  uniform sampler2D colortex0;
  uniform sampler2D colortex3;

  uniform sampler2D depthtex0;

  in vec2 texcoord;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    float depth = texture(depthtex0, texcoord).r;
    color = texture(colortex0, texcoord);

    vec4 cloud = texture2DLod(colortex3, texcoord, 2);

    // prevent lack of clouds behind terrain bleeding through with mip
    const ivec2[4] offsets = ivec2[4](ivec2(2), ivec2(-2, 2), ivec2(2, -2), ivec2(-2));
    if(any(lessThan(textureGatherOffsets(depthtex0, texcoord, offsets, 0), vec4(1.0)))){

      cloud = texture(colortex3, texcoord);
    }
    color.rgb = mix(color.rgb, cloud.rgb, cloud.a);
  }
#endif