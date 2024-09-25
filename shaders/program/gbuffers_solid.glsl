#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out mat3 tbnMatrix;
  flat out int materialID;
  out vec3 viewPos;

  uniform int worldTime;
  uniform int worldDay;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;

  in vec4 at_tangent;
  in vec2 mc_Entity;
  in vec3 at_midBlock;

  #include "/lib/util.glsl"
  #include "/lib/misc/sway.glsl"

  void main() {
    materialID = int(mc_Entity.x + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    tbnMatrix[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
    tbnMatrix[2] = normalize(gl_NormalMatrix * gl_Normal);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * at_tangent.w);

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    worldPos = getSway(materialID, worldPos, at_midBlock);
    feetPlayerPos = worldPos - cameraPosition;
    viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;

    gl_Position = gbufferProjection * vec4(viewPos, 1.0);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;

  uniform float alphaTestRef;

  uniform vec3 cameraPosition;

  uniform mat4 gbufferModelViewInverse;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in mat3 tbnMatrix;
  flat in int materialID;
  in vec3 viewPos;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"

  vec3 getMappedNormal(vec2 texcoord){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:12 */
  layout(location = 0) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 1) out vec4 outData2; // mapped normal, specular map data

  void main() {
    vec4 color;
    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord);
    #else
      vec3 mappedNormal = faceNormal;
    #endif


    // encode gbuffer data
    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * tbnMatrix[2]));
    outData1.w = pack2x8F(lightmap);

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, texcoord);
    #else
    vec4 specularData= vec4(0.0);
    #endif

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);
  }
#endif