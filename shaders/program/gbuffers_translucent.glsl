#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 faceNormal;
  out vec3 faceTangent;
  flat out int materialID;
  out vec3 viewPos;

  uniform int worldTime;
  uniform int worldDay;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;

  in vec3 at_tangent;
  in vec2 mc_Entity;
  in vec3 at_midBlock;

  #include "/lib/util.glsl"
  #include "/lib/misc/sway.glsl"

  void main() {
    materialID = int(mc_Entity.x + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    faceNormal = gl_NormalMatrix * gl_Normal;
    faceTangent = gl_NormalMatrix * at_tangent;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    worldPos = getSway(materialID, worldPos, at_midBlock);
    feetPlayerPos = worldPos - cameraPosition;
    viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;

    gl_Position = gbufferProjection * vec4(viewPos, 1.0);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;

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
  in vec3 faceTangent;
  in vec3 faceNormal;
  flat in int materialID;
  in vec3 viewPos;

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




  vec3 getMappedNormal(vec2 texcoord, vec3 faceNormal, vec3 faceTangent){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(faceNormal, faceTangent);
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:312 */
  layout(location = 0) out vec4 color; // shaded colour
  layout(location = 1) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 2) out vec4 outData2; // mapped normal, specular map data

  void main() {
    vec3 faceNormal = faceNormal;

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(gtexture, texcoord) * glcolor;

    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    #ifdef gbuffers_weather
      if(biome_precipitation != 2){
        color = vec4(0.2);
      }

      // hide rain above the clouds
      color.a *= (1.0 - smoothstep(CLOUD_LOWER_PLANE_HEIGHT, CLOUD_UPPER_PLANE_HEIGHT, eyePlayerPos.y + cameraPosition.y));
      if (color.a < alphaTestRef) {
        discard;
      }
      
    #endif

    

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord, faceNormal, faceTangent);
    #else
      vec3 mappedNormal = faceNormal;
    #endif

    if(materialIsWater(materialID)){
      color = vec4(0.0);
      #ifdef WATER_NORMALS
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
    }

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);

    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);
    vec3 sunlight = hasSkylight ? getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, mappedNormal, faceNormal, material.sss, lightmap) * SUNLIGHT_STRENGTH * sunlightColor : vec3(0.0);
    color.rgb = shadeDiffuse(color.rgb, lightmap, sunlight, material);
    color = shadeSpecular(color, lightmap, mappedNormal, viewPos, material, sunlight);

    color = getAtmosphericFog(color, eyePlayerPos);
  }
#endif