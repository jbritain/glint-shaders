#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 normal;
  out vec3 tangent;
  out float materialID;

  attribute vec3 at_tangent;
  attribute vec2 mc_Entity;

  void main() {
    gl_Position = ftransform();
    materialID = mc_Entity.x;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
    tangent = gl_NormalMatrix * at_tangent;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform float near;
  uniform float far;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in vec3 normal;
  in vec3 tangent;
  in float materialID;

  #include "/lib/util.glsl"
  #include "/lib/tonemap.glsl"

  

  /* DRAWBUFFERS:012 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 outNormal;
  layout(location = 2) out vec4 outLightmap;

  void main() {
    color = texture(gtexture, texcoord) * glcolor;
    //color *= texture(lightmap, lmcoord);

    vec3 normal = normal;

    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(normal, tangent);
    normal = tbnMatrix * mappedNormal;

    if (color.a < 0.1) {
      discard;
    }
    color.rgb = gammaCorrect(color.rgb);

    outNormal.rgb = encodeNormal(normal);

    outLightmap = vec4(lmcoord, 0.0, 1.0);
  }
#endif