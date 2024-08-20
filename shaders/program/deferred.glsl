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
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;

  in vec2 texcoord;

  uint materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  #include "/lib/util/gbufferData.glsl"

  void main() {
    color = vec4(0.0);

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));
    
  }
#endif