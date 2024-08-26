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
  uniform sampler2D colortex3;
  uniform sampler2D colortex4;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;

  uniform sampler2DShadow shadowtex0;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2D shadowcolor0;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;

  uniform float near;
  uniform float far;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec3 cameraPosition;

  uniform int frameCounter;
  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:03 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 cloudColor;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/blur.glsl"

  void main() {
    color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;

    if(depth == 1.0){
      cloudColor = blur13(colortex3, texcoord, vec2(viewWidth, viewHeight), vec2(1.0, 0.0));
    } else {
      cloudColor = texture(colortex3, texcoord);
    }

    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    if(depth == 1.0){
      return;
    }

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));
    
    Material material;

    if(water(materialID)) {
      material = waterMaterial;
    } else {
      material = materialFromSpecularMap(albedo, specularData);
    }

    color.rgb = shadeSpecular(color.rgb, lightmap, mappedNormal, viewPos, material);

    // we use positive Y to hide the horizon line
    vec3 fog = getSky(normalize(vec3(eyePlayerPos.x, abs(eyePlayerPos.y), eyePlayerPos.z)), false);

    float fogFactor = length(eyePlayerPos) / far;
    fogFactor = clamp01(fogFactor - 0.2) / (1.0 - 0.2);
    fogFactor = pow(fogFactor, 3.0);
    fogFactor = clamp01(fogFactor);

    color.rgb = mix(color.rgb, fog, fogFactor);

  }
#endif