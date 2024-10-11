/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_translucent.glsl
    - Translucent terrain
    - Translucent entities
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out mat3 tbnMatrix;
  flat out int materialID;
  out vec3 viewPos;

  flat out vec2 singleTexSize;
  flat out ivec2 pixelTexSize;
  flat out vec4 textureBounds;

  uniform int worldTime;
  uniform int worldDay;
  uniform float frameTimeCounter;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;

  uniform ivec2 atlasSize;

  in vec4 at_tangent;
  in vec2 mc_Entity;
  in vec3 at_midBlock;
  in vec2 mc_midTexCoord;

  #include "/lib/util.glsl"
  #include "/lib/misc/sway.glsl"

  void main() {
    materialID = int(mc_Entity.x + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    
    tbnMatrix[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
    tbnMatrix[2] = normalize(gl_NormalMatrix * gl_Normal);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * at_tangent.w);

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    worldPos = getSway(materialID, worldPos, at_midBlock);

    if(materialIsWater(materialID)){
      worldPos.y += (getwaves(worldPos.xz, ITERATIONS_NORMAL) - 0.5);
    }

    feetPlayerPos = worldPos - cameraPosition;
    viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;

    gl_Position = gbufferProjection * vec4(viewPos, 1.0);

    vec2 halfSize      = abs(texcoord - mc_midTexCoord);
    textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);

    singleTexSize = halfSize * 2.0;
    pixelTexSize  = ivec2(singleTexSize * atlasSize);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;

  uniform vec4 entityColor;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;

  uniform sampler2D depthtex0; // do not use this in gbuffers it is a bad idea
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
  uniform vec4 lightningBoltPosition;

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
  in mat3 tbnMatrix;
  flat in int materialID;
  in vec3 viewPos;

  flat in vec2 singleTexSize;
  flat in ivec2 pixelTexSIze;
  flat in vec4 textureBounds;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/lighting/specularShading.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/misc/parallax.glsl"
  #include "/lib/water/waveNormals.glsl"

  vec3 getMappedNormal(vec2 texcoord){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:312 */
  layout(location = 0) out vec4 color; // shaded colour
  layout(location = 1) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 2) out vec4 outData2; // mapped normal, specular map data

  void main() {
    float parallaxSunlight = 1.0;
    #ifdef POM
    vec2 texcoord = texcoord;
    vec2 dx = dFdx(texcoord);
    vec2 dy = dFdy(texcoord);
    vec3 parallaxPos;
    if(length(viewPos) < 32.0){
      vec2 pomJitter = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rg;
      texcoord = getParallaxTexcoord(texcoord, viewPos, tbnMatrix, parallaxPos, dx, dy, pomJitter.x);
      #ifdef POM_SHADOW
            parallaxSunlight = getParallaxShadow(parallaxPos, tbnMatrix, dx, dy, pomJitter.y) ? smoothstep(0.0, 32.0, length(viewPos)) : 1.0;
      #endif
    }
    #endif


    vec3 faceNormal = tbnMatrix[2];

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(gtexture, texcoord) * glcolor;

    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

    color.rgb = gammaCorrect(color.rgb);

    #ifdef gbuffers_spidereyes
    color.a = 1.0;
    #endif

    if (color.a < alphaTestRef) {
      discard;
    }

    #ifdef gbuffers_weather
      if(color.rgb != vec3(1.0)){
        color = vec4(0.2);
        color.a = 0.1;
      }

      // hide rain above the clouds
      // color.a *= (1.0 - smoothstep(CLOUD_LOWER_PLANE_HEIGHT, CLOUD_UPPER_PLANE_HEIGHT, eyePlayerPos.y + cameraPosition.y));
      if (color.a < alphaTestRef) {
        discard;
      }
      
    #endif

    

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord);
    #else
      vec3 mappedNormal = faceNormal;
    #endif

    if(materialIsWater(materialID)){
      #ifdef CUSTOM_WATER
      color = vec4(0.0);

      #ifdef DISTANT_HORIZONS
      color.a = smoothstep(0.8 * far, far, length(viewPos));
      #endif

      mappedNormal = mat3(gbufferModelView) * waveNormal(eyePlayerPos.xz + cameraPosition.xz, mat3(gbufferModelViewInverse) * faceNormal, WAVE_E, WAVE_DEPTH);
      #endif
    }

    // encode gbuffer data
    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * faceNormal));
    outData1.w = pack2x8F(lightmap);

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, texcoord);
    #else
    vec4 specularData= vec4(0.0);
    #endif

    Material material;

    if(materialIsWater(materialID)) {
      material = waterMaterial;
    } else {
      material = materialFromSpecularMap(color.rgb, specularData);

      float wetnessFactor = wetness * (1.0 - material.porosity) * smoothstep(0.66, 1.0, lightmap.y) * float(biome_precipitation == PPT_RAIN);

      material.f0 = mix(material.f0, waterMaterial.f0, wetnessFactor);
      material.roughness = mix(material.roughness, waterMaterial.roughness, wetnessFactor);
    }

    #ifdef gbuffers_spidereyes
    material.emission = 1.0;
    #endif

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);

    #ifndef gbuffers_weather
      vec3 sunlightColor; vec3 skyLightColor;
      getLightColors(sunlightColor, skyLightColor);
      vec3 sunlight = getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, mappedNormal, faceNormal, material.sss, lightmap) * SUNLIGHT_STRENGTH * sunlightColor * parallaxSunlight;
      color.rgb = shadeDiffuse(color.rgb, lightmap, sunlight, material, vec3(0.0), skyLightColor);
      color = shadeSpecular(color, lightmap, mappedNormal, viewPos, material, sunlight, skyLightColor);
    #endif

    color = getAtmosphericFog(color, eyePlayerPos);
  }
#endif