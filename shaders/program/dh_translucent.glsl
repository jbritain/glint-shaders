/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/dh_solid.glsl
    - Opaque DH Terrain
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  flat out int materialID;
  out vec3 viewPos;
  out vec3 faceNormal;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;

  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util.glsl"

  void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    faceNormal = gl_NormalMatrix * gl_Normal;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    gl_Position = gbufferProjection * vec4(viewPos, 1.0);

    switch(dhMaterialId){
      case DH_BLOCK_WATER:
      //TODO: come up with a better system for this because if I ever regenerate the block properties this will break
        materialID = 10008;
        break;
    }
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;

  uniform vec4 entityColor;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;
  uniform sampler2D depthtex2;
  uniform sampler2D colortex0;
  uniform sampler2D colortex4;
  uniform sampler2D colortex6;
  uniform sampler2D colortex9;

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
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float near;
  uniform float far;

  uniform float wetness;
uniform float thunderStrength;

  uniform int frameCounter;
  uniform int worldTime;
  uniform int worldDay;

  uniform int isEyeInWater;

  uniform int biome_precipitation;
  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform ivec2 eyeBrightnessSmooth;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  flat in int materialID;
  in vec3 viewPos;
  in vec3 faceNormal;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/dh.glsl"

  /* DRAWBUFFERS:312 */
  layout(location = 0) out vec4 color; // shaded colour
  layout(location = 1) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 2) out vec4 outData2; // mapped normal, specular map data

  void main() {
    if(length(viewPos) < far * 0.8){
      discard;
      return;
    } 

    float opaqueDepth = texture(depthtex1, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
    float opaqueDistance = screenSpaceToViewSpace(opaqueDepth);

    if(opaqueDistance > viewPos.z){
      discard;
      return;
    }

    DH_MASK = true;
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

    vec4 specularData = vec4(0.0);

    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;
    vec3 mappedNormal = faceNormal;

    if(materialIsWater(materialID)){
      #ifdef CUSTOM_WATER
      color = vec4(0.0);

      color.a = smoothstep(0.8 * far, far, length(viewPos));

      mappedNormal = mat3(gbufferModelView) * waveNormal(eyePlayerPos.xz + cameraPosition.xz, mat3(gbufferModelViewInverse) * faceNormal, WAVE_E, WAVE_DEPTH);
      #endif
    }

    // encode gbuffer data
    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * faceNormal));
    outData1.w = pack2x8F(lightmap);

    Material material;

    if(materialIsWater(materialID)) {
      material = waterMaterial;
    } else {
      material = materialFromSpecularMap(color.rgb, specularData);

      float wetnessFactor = wetness * (1.0 - material.porosity) * lightmap.y;

      material.f0 = mix(material.f0, waterMaterial.f0, wetnessFactor);
      material.roughness = mix(material.roughness, waterMaterial.roughness, wetnessFactor);
    }

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);

    #ifndef gbuffers_weather
      vec3 sunlightColor; vec3 skyLightColor;
      getLightColors(sunlightColor, skyLightColor);
      vec3 sunlight = SUNLIGHT_STRENGTH * sunlightColor;
      color.rgb = shadeDiffuse(color.rgb, lightmap, sunlight, material, vec3(0.0), skyLightColor);
      color = shadeSpecular(color, lightmap, mappedNormal, viewPos, material, sunlight, skyLightColor);
    #endif

    color = getAtmosphericFog(color, eyePlayerPos);
  }
#endif