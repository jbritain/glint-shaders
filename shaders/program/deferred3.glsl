/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred3.glsl
    - Opaque diffuse shading
    - Sky
    - Clear sky buffer for translucents
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
  uniform sampler2D colortex5;
  uniform sampler2D colortex6;
  uniform sampler2D colortex10;
  uniform sampler2D colortex9;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex2;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;

  uniform sampler2D noisetex;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec4 lightningBoltPosition;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float frameTimeCounter;
  uniform int worldTime;
  uniform int worldDay;

  uniform int biome_precipitation;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform float wetness;
  uniform float thunderStrength;

  uniform float near;
  uniform float far;

  uniform int isEyeInWater;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform ivec2 eyeBrightnessSmooth;

  in vec2 texcoord;





  /* DRAWBUFFERS:038 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 tex3;
  layout(location = 2) out vec3 sunlight;
  #include "/lib/util.glsl"
  #include "/lib/util/gbufferData.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/blur.glsl"
  #include "/lib/util/dh.glsl"
  #include "/lib/util/bilateralFilter.glsl"
  #include "/lib/lighting/brdf.glsl"

  void main() {
    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    dhOverride(depth, viewPos, false);
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
    
    tex3 = vec4(0.0); // clear buffer in preparation for translucents to write to it

    if(depth == 1.0){
      color = texture(colortex3, texcoord);
      color.rgb = getSky(color, normalize(eyePlayerPos), true);
      return;
    }

    GbufferData gbufferData;
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord), gbufferData);

    if(materialIsPlant(gbufferData.materialID)){
      gbufferData.material.sss = 1.0;
      gbufferData.material.f0 = vec3(0.04);
      gbufferData.material.roughness = 0.5;
    }

    vec3 skyLightColor;
    vec3 sunlightColor;
    getLightColors(sunlightColor, skyLightColor, eyePlayerPos, mat3(gbufferModelViewInverse) * gbufferData.faceNormal);


    float parallaxShadow = texture(colortex3, texcoord).a;

    if(DH_MASK){
      parallaxShadow = 1.0;
    }

    float scatter;
    vec3 sunlight = getSunlight(feetPlayerPos, gbufferData.mappedNormal, gbufferData.faceNormal, gbufferData.material.sss, gbufferData.lightmap, scatter) * parallaxShadow;

    color.rgb = gbufferData.material.albedo;

    #ifdef GLOBAL_ILLUMINATION
    // vec3 GI = bilateralFilterDepth(colortex10, depthtex0, texcoord, 5, 10, GI_RESOLUTION, 0).rgb;
    vec4 GI = texture(colortex10, texcoord);
    #else
    vec4 GI = vec4(vec3(0.0), 1.0);
    #endif

    vec3 diffuse = getDiffuseColor(gbufferData.lightmap, gbufferData.material, skyLightColor) * gbufferData.material.albedo;
    vec3 fresnel;
    vec3 specular = getSpecularColor(color.rgb, gbufferData.lightmap, gbufferData.mappedNormal, viewPos, gbufferData.material, fresnel);

    color.rgb *= (brdf(gbufferData.material, gbufferData.mappedNormal, gbufferData.faceNormal, viewPos) * sunlight + vec3(scatter)) * sunlightColor;
    color.rgb += mix(diffuse, specular, fresnel);
  }
#endif