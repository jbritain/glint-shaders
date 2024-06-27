#include "/lib/settings.glsl"

#ifdef vsh
  attribute vec2 mc_Entity;
  attribute vec3 at_tangent;

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 normal;
  out vec3 tangent;
  out float materialID;

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

  uniform float far;
  uniform float near;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in float materialID;
  in vec3 normal;
  in vec3 tangent;

  #include "/lib/tonemap.glsl"
  #include "/lib/util.glsl"

  /* DRAWBUFFERS:045 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 outNormal;
  layout(location = 2) out vec4 outLightmap;

  void main() {
    

    color = texture(gtexture, texcoord) * glcolor;

    bool isWater = floatCompare(materialID, 1.0);

    vec3 normal = normal;

    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(normal, tangent);
    normal = tbnMatrix * mappedNormal;

    outNormal.rgb = encodeNormal(normal);

    outNormal.a = 0.5; // set alpha of normal to indicate translucents on this pixel

    if(isWater){ // water
      color = vec4(0.215, 0.356, 0.533, 0.75);
      outNormal.a = 1.0; // set alpha of normal to 1.0 to indicate water
    }

    if (color.a < 0.1) {
      discard;
    }
    color.rgb = gammaCorrect(color.rgb);
    outLightmap = vec4(lmcoord, 0.0, 1.0);
    
  }
#endif