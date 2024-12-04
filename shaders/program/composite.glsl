/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
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

  uniform vec3 cameraPosition;
  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform mat4 gbufferModelViewInverse;
  uniform ivec2 eyeBrightnessSmooth;
  uniform float far;



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
  uniform sampler2D shadowtex1;
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

  uniform float near;
  uniform float far;
  uniform float wetness;
  uniform float thunderStrength;
  uniform int isEyeInWater;
  uniform vec4 lightningBoltPosition;

  uniform int frameCounter;

  uniform float viewWidth;
  uniform float viewHeight;
  uniform float aspectRatio;

  uniform ivec2 eyeBrightnessSmooth;

  uniform vec3 previousCameraPosition;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform float frameTimeCounter;

  uniform sampler2D noisetex;

  in vec2 texcoord;





  #include "/lib/util/gbufferData.glsl"
  #include "/lib/atmosphere/sky.glsl"

  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/water/waterFog.glsl"
  #include "/lib/util/screenSpaceRayTrace.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/uvmap.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"
  #include "/lib/util/dh.glsl"
  #include "/lib/atmosphere/sky.glsl"

  // Kneemund's Border Attenuation
  float kneemundAttenuation(vec2 pos, float edgeFactor) {
    pos *= 1.0 - pos;
    return 1.0 - quinticStep(edgeFactor, 0.0, min2(pos));
  }

  /* DRAWBUFFERS:08 */
  layout(location = 0) out vec4 color;

  void main() {


    color = texture(colortex0, texcoord);
    GbufferData gbufferData;
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord), gbufferData);
    float translucentDepth = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex2, texcoord).r;

    vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
    dhOverride(opaqueDepth, opaqueViewPos, true);
    

    vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
    dhOverride(translucentDepth, translucentViewPos, false);
    vec3 translucentEyePlayerPos = mat3(gbufferModelViewInverse) * translucentViewPos;
    
    vec4 translucent = texture(colortex3, texcoord);

    bool inWater = isEyeInWater == 1;
    bool waterMask = (materialIsWater(gbufferData.materialID) || materialIsIce(gbufferData.materialID)) && translucent.a < 1.0;

    vec3 skyLightColor;
    vec3 sunlightColor;

    #ifdef REFRACTION

    if(waterMask){
      vec3 dir = normalize(translucentViewPos);

      bool doSnellsWindow = false;
      #ifdef SNELLS_WINDOW
      doSnellsWindow = inWater;
      #endif

      // the actual refracted ray direction
      vec3 refractionNormal = !doSnellsWindow ? gbufferData.faceNormal - gbufferData.mappedNormal :  gbufferData.mappedNormal;

      vec3 refractedDir = normalize(refract(dir, refractionNormal, inWater ? 1.33 : rcp(1.33))); // refracted ray in view space
      float jitter = blueNoise(texcoord, frameCounter).r;

      

      // vec3 refractedPos = viewSpaceToScreenSpace(translucentViewPos + refractedDir * distance(translucentViewPos, opaqueViewPos));
      vec3 refractedPos;
      bool intersect = rayIntersects(translucentViewPos, refractedDir, 8, jitter, true, refractedPos, false);
      
      float refractedDepth = texture(depthtex2, refractedPos.xy).r;
      intersect = intersect && refractedDepth > translucentDepth + 1e-6 && refractedDepth != 1.0; 
      // intersect = intersect && distance(refractedPos.xy, texcoord) > 5e-3;
      if(intersect){
        color = texture(colortex0, refractedPos.xy);
        // opaqueViewPos = screenSpaceToViewSpace(refractedPos);
        // opaqueDepth = refractedPos.z;
      } else if(doSnellsWindow) {
        if((mat3(gbufferModelViewInverse) * refractedDir).y > 0.0){
          vec3 worldRefractedDir = normalize(mat3(gbufferModelViewInverse) * refractedDir);
          vec2 environmentUV = mapSphere(worldRefractedDir);

          color.a = 1.0;
          color.rgb = texture(colortex9, environmentUV).rgb * float(opaqueDepth == 1.0 || refractedDepth > 0.99);
        } else {
          color.rgb = skyLightColor * EBS.y;
        }
      }

    }
    #endif

    vec3 opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;
    getLightColors(sunlightColor, skyLightColor, opaqueEyePlayerPos, gbufferData.faceNormal);

    if(!inWater && !waterMask && opaqueDepth != 1.0){
      color = getAtmosphericFog(color, opaqueEyePlayerPos);
      color = getBorderFog(color, opaqueEyePlayerPos);
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