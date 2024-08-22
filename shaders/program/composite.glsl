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

  uniform sampler2D depthtex0;

  uniform sampler2DShadow shadowtex0;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2D shadowcolor0;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec3 cameraPosition;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/util/materialIDs.glsl"

  void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    if(depth == 1.0){
      return;
    }

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));
    
    Material material;

    // color.rgb = vec3(water(materialID));

    if(water(materialID)) {
      material = waterMaterial;
    } else {
      material = materialFromSpecularMap(albedo, specularData);
    }

    color.rgb = shadeSpecular(color.rgb, lightmap, mappedNormal, viewPos, material);
    // color.rgb = vec3(water(materialID));

  }
#endif