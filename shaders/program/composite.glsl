/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite.glsl
    - Refraction
    - Translucent blending
    - Water fog
    - Atmospheric fog
*/

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
  uniform sampler2D colortex9;

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
  uniform float aspectRatio;

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
  #include "/lib/water/waterFog.glsl"
  #include "/lib/util/screenSpaceRaytrace.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/spheremap.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"

  // Kneemund's Border Attenuation
  float kneemundAttenuation(vec2 pos, float edgeFactor) {
    pos *= 1.0 - pos;
    return 1.0 - quinticStep(edgeFactor, 0.0, min2(pos));
  }

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
    
    vec4 translucent = texture(colortex3, texcoord);

    bool inWater = isEyeInWater == 1;
    bool waterMask = materialIsWater(materialID);

    #ifdef REFRACTION

    if(waterMask){
      vec3 dir = normalize(opaqueEyePlayerPos);

      // the actual refracted ray direction
      vec3 refractedDir = normalize(refract(dir, mat3(gbufferModelViewInverse) * mappedNormal, inWater ? 1.33 : (1.0 / 1.33))); // refracted ray in view space

      float waterDepth = distance(opaqueEyePlayerPos, translucentEyePlayerPos);

      // the refracted offset we use for terrain
      // method from BSL
      vec2 refractDir = mappedNormal.xy - faceNormal.xy;
      refractDir *= vec2(1.0 / aspectRatio, 1.0) * (gbufferProjection[1][1] / 1.37) / max(length(opaqueEyePlayerPos), 8.0); // sorcery
      vec3 refractedCoord = vec3(texcoord + refractDir, 0.0);
      refractedCoord.z = texture(depthtex2, refractedCoord.xy).r;

      bool refract = clamp01(refractedCoord.xy) == refractedCoord.xy; // don't refract offscreen

      refract = refract && (
        inWater ? refractedCoord.z < translucentDepth : refractedCoord.z > translucentDepth
      );

      if(refract){ // don't refract stuff that's not underwater
        vec2 refractedDecode1y = unpack2x8F(texture(colortex1, refractedCoord.xy).y);
        int refractedMaterialID = int(refractedDecode1y.y * 255 + 0.5) + 10000;
        refract = materialIsWater(refractedMaterialID);
      }

      refract = refract && (refractedCoord.z >= translucentDepth); // another check for it being underwater


      if(refract && refractedCoord.z != 1.0){
        // refractedCoord.xy = mix(texcoord, refractedCoord.xy, kneemundAttenuation(refractedCoord.xy, 0.03));
        color = texture(colortex0, refractedCoord.xy);
        refractedCoord.z = texture(depthtex2, refractedCoord.xy).r;
        opaqueViewPos = screenSpaceToViewSpace(refractedCoord);
        opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;
      } else if (inWater && refractedCoord.z == 1.0){
        vec2 refractedSkyUV = mapSphere(refractedDir);
        color.rgb = texture(colortex9, refractedSkyUV).rgb;
      }
    }
    #endif

    if(waterMask == inWater && opaqueDepth != 1.0){
      color = getAtmosphericFog(color, opaqueEyePlayerPos);
    }

    if(inWater && !waterMask){ // water fog when camera and object are underwater
      color.rgb = getWaterFog(color.rgb, vec3(0.0), opaqueEyePlayerPos, sunlightColor, skyLightColor);
    } else if(inWater && waterMask){ // water fog when only camera is underwater
      color.rgb = getWaterFog(color.rgb, vec3(0.0), translucentEyePlayerPos, sunlightColor, skyLightColor);
      translucent.rgb = getWaterFog(translucent.rgb, vec3(0.0), translucentEyePlayerPos, sunlightColor, skyLightColor);
    } else if(!inWater && waterMask){ // water fog when only object is underwater
      color.rgb = getWaterFog(color.rgb, translucentEyePlayerPos, opaqueEyePlayerPos, sunlightColor, skyLightColor);
    }

    color.rgb = mix(color.rgb, translucent.rgb, clamp01(translucent.a));
  }
#endif