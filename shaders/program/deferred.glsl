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
  uniform sampler2D colortex0;
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;

  uniform sampler2D depthtex0;

  uniform sampler2DShadow shadowtex0;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2D shadowcolor0;

  uniform sampler2D noisetex;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec3 cameraPosition;

  uniform float frameTimeCounter;

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
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/noise.glsl"

  void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    vec3 sunlightColor = getSky(mat3(gbufferModelViewInverse) * normalize(sunPosition), true);
    vec3 skyLightColor = getSky(vec3(0, 1, 0), false);
    cloudColor = getClouds(eyePlayerPos, depth, sunlightColor, skyLightColor);
    

    if(depth == 1.0){
      color.rgb = getSky(normalize(eyePlayerPos), true);
    } else {
      decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));
      color.rgb = albedo;

      color.rgb = shadeDiffuse(color.rgb, eyePlayerPos + gbufferModelViewInverse[3].xyz, lightmap, mappedNormal, faceNormal);
    }
  }
#endif