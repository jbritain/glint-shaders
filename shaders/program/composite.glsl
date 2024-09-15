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


  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowProjection;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform int worldTime;

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
  #include "/lib/atmosphere/fog.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/water/waterFog.glsl"
  #include "/lib/util/screenSpaceRaytrace.glsl"
  #include "/lib/textures/blueNoise.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    color = texture(colortex0, texcoord);
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    float translucentDepth = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex1, texcoord).r;

    vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
    vec3 opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;

    vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
    vec3 translucentEyePlayerPos = mat3(gbufferModelViewInverse) * translucentViewPos;
    
    vec4 translucent = texture(colortex3, texcoord);

    bool inWater = isEyeInWater == 1;
    bool waterMask = materialIsWater(materialID);

    #ifdef REFRACTION

    // this is cheating at refraction
    // instead of actually tracing the refracted ray we just step a little bit
    if(waterMask){
      vec3 dir = normalize(translucentViewPos);
      vec3 refracted = normalize(refract(dir, mappedNormal, inWater ? 1.33 : (1.0 / 1.33))); // refracted ray in view space


      vec3 refractedPos = translucentViewPos;
      refractedPos += refracted * REFRACTION_AMOUNT; // that's right we're gonna cheat
      vec2 refractedCoord = viewSpaceToScreenSpace(refractedPos).xy;

      refractedCoord = mix(refractedCoord, texcoord, smoothstep(0.95, 1.0, max2(abs(0.5 - refractedCoord)) * 2.0));

      if(clamp01(refractedCoord) != refractedCoord || texture(depthtex1, refractedCoord).r < translucentDepth){
        refractedCoord = texcoord;
      }

      color.rgb = texture(colortex0, refractedCoord).rgb;
      opaqueDepth = texture(depthtex1, refractedCoord).r;

      opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
      opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;
    }
    #endif

    if(waterMask == inWater && opaqueDepth != 1.0){
      color = getFog(color, opaqueEyePlayerPos);
    }

    if(inWater && !waterMask){ // water fog when camera and object are underwater
      color.rgb = waterFog(color.rgb, vec3(0.0), opaqueEyePlayerPos, sunlightColor, skyLightColor);
    } else if(inWater && waterMask){ // water fog when only camera is underwater
      color.rgb = waterFog(color.rgb, vec3(0.0), translucentEyePlayerPos, sunlightColor, skyLightColor);

      translucent.rgb = waterFog(translucent.rgb, vec3(0.0), translucentEyePlayerPos, sunlightColor, skyLightColor);
    } else if(!inWater && waterMask){ // water fog when only object is underwater
      color.rgb = waterFog(color.rgb, translucentEyePlayerPos, opaqueEyePlayerPos, sunlightColor, skyLightColor);
    }

    color.rgb = mix(color.rgb, translucent.rgb, clamp01(translucent.a));
  }
#endif