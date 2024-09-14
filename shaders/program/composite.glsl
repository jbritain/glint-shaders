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

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform int worldTime;

  uniform vec3 cameraPosition;

  uniform float wetness;
  uniform int isEyeInWater;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/atmosphere/fog.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/water/waterFog.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    float translucentDepth = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex1, texcoord).r;

    vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
    vec3 opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;
    
    vec4 translucent = texture(colortex3, texcoord);

    bool inWater = isEyeInWater == 1;
    bool waterMask = water(materialID);

    if(waterMask == inWater && opaqueDepth != 1.0){
      color = getFog(color, opaqueEyePlayerPos);
    }

    if(inWater && !waterMask){
      color = waterFog(color, vec3(0.0), opaqueViewPos);
    }

    color.rgb = mix(color.rgb, translucent.rgb, translucent.a);
  }
#endif