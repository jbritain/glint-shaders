#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 faceNormal;
  out vec3 faceTangent;
  flat out uint materialID;
  out vec3 viewPos;

  attribute vec3 at_tangent;
  attribute vec2 mc_Entity;

  void main() {
    gl_Position = ftransform();
    materialID = uint(mc_Entity.x - 10000 + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    faceNormal = gl_NormalMatrix * gl_Normal;
    faceTangent = gl_NormalMatrix * at_tangent;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;

  uniform float alphaTestRef;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in vec3 faceTangent;
  in vec3 faceNormal;
  flat in uint materialID;
  in vec3 viewPos;

  #include "/lib/util.glsl"
  #include "/lib/postProcessing/tonemap.glsl"
  #include "/lib/util/packing.glsl"

  vec3 getMappedNormal(vec2 texcoord, vec3 faceNormal, vec3 faceTangent){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(faceNormal, faceTangent);
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:12 */
  layout(location = 1) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 2) out vec4 outData2; // mapped normal, specular map data

  void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord, faceNormal, faceTangent);
    #else
      vec3 mappedNormal = faceNormal;
    #endif


    outData1.x = pack2x8F(color.rg);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(faceNormal));
    outData1.w = pack2x8F(lightmap);

    vec4 specularData = texture(specular, texcoord);

    outData2.x = pack2x8F(encodeNormal(mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);
  }
#endif