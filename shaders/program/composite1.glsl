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
  uniform sampler2D colortex6;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex2;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowProjection;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform int worldTime;
  uniform int worldDay;

  uniform vec3 cameraPosition;

  uniform float far;
  uniform float wetness;
  uniform int isEyeInWater;

  uniform int frameCounter;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform ivec2 eyeBrightnessSmooth;

  uniform vec3 previousCameraPosition;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/atmosphere/sky.glsl"

  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    color = texture(colortex0, texcoord);
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    float translucentDepth = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex2, texcoord).r;

    vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
    vec3 opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;

    vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
    vec3 translucentEyePlayerPos = mat3(gbufferModelViewInverse) * translucentViewPos;
    
    if(isEyeInWater == 0.0){
      color = getCloudFog(color, vec3(0.0), translucentEyePlayerPos, translucentDepth, sunlightColor, skyLightColor);
    }
    
  }
#endif