#include "/lib/settings.glsl"

#ifdef vsh

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 faceNormal;
  out vec3 faceTangent;
  flat out int materialID;
  out vec3 viewPos;

  attribute vec3 at_tangent;
  attribute vec2 mc_Entity;

  void main() {
    gl_Position = ftransform();
    materialID = int(mc_Entity.x + 0.5);
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

  uniform sampler2DShadow shadowtex0;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2D shadowcolor0;

  uniform sampler2D colortex0;
  uniform sampler2D colortex4;

  uniform float alphaTestRef;
  uniform float frameTimeCounter;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float far;

  uniform int frameCounter;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in vec3 faceTangent;
  in vec3 faceNormal;
  flat in int materialID;
  in vec3 viewPos;

  #include "/lib/util.glsl"
  #include "/lib/postProcessing/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/atmosphere/fog.glsl"


  vec3 getMappedNormal(vec2 texcoord, vec3 faceNormal, vec3 faceTangent){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(faceNormal, faceTangent);
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:0123 */
  layout(location = 0) out vec4 color; // shaded colour
  layout(location = 1) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 2) out vec4 outData2; // mapped normal, specular map data

  void main() {
    vec3 faceNormal = faceNormal;

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = gammaCorrect(color.rgb);

    if(water(materialID)){
      color = WATER_COLOR;
      faceNormal = mat3(gbufferModelView) * waveNormal(eyePlayerPos.xz + cameraPosition.xz, 0.01, 0.2);
    }

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord, faceNormal, faceTangent);
    #else
      vec3 mappedNormal = faceNormal;
    #endif

    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * faceNormal));
    outData1.w = pack2x8F(lightmap);

    vec4 specularData = texture(specular, texcoord);

    Material material;
    if(water(materialID)) {
      material = waterMaterial;
    } else {
      material = materialFromSpecularMap(color.rgb, specularData);
    }

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);

    vec3 sunlightColor = getSky(mat3(gbufferModelViewInverse) * normalize(shadowLightPosition), true);
    vec3 sunlight = getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, mappedNormal, faceNormal, material.sss) * SUNLIGHT_STRENGTH * sunlightColor;
    color.rgb = shadeDiffuse(color.rgb, lightmap, sunlight);
    color = shadeSpecular(color, lightmap, mappedNormal, viewPos, material, sunlight);

    color = getFog(color, eyePlayerPos);
  }
#endif