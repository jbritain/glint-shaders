/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred2.glsl
    - Opaque shading
    - Sky
    - Clear sky buffer for translucents
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

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float frameTimeCounter;
  uniform int worldTime;
  uniform int worldDay;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform float wetness;

  uniform float near;
  uniform float far;

  uniform int isEyeInWater;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform ivec2 eyeBrightnessSmooth;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:03 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 tex3;

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

  void main() {
    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    
    tex3 = vec4(0.0); // clear buffer in preparation for translucents to write to it

    if(depth == 1.0){
      color = texture(colortex3, texcoord);
      color.rgb = getSky(color, normalize(eyePlayerPos), true);
      return;
    }

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));
    Material material = materialFromSpecularMap(albedo, specularData);

    if(materialIsPlant(materialID)){
      material.sss = 1.0;
    }

    float wetnessFactor = wetness * (1.0 - material.porosity) * lightmap.y;

    material.f0 = mix(material.f0, waterMaterial.f0, wetnessFactor);
    material.roughness = mix(material.roughness, waterMaterial.roughness, wetnessFactor);


    vec3 sunlight = hasSkylight ? getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, mappedNormal, faceNormal, material.sss, lightmap) * SUNLIGHT_STRENGTH * sunlightColor : vec3(0.0);

    color.rgb = albedo;

    vec3 GI = blur13(colortex10, texcoord, vec2(viewWidth, viewHeight), vec2(1.0, 0.0)).rgb;

    color.rgb = shadeDiffuse(color.rgb, lightmap, sunlight, material, GI);
    color = shadeSpecular(color, lightmap, mappedNormal, viewPos, material, sunlight);

    if((isEyeInWater == 1) != materialIsWater(materialID)){
      color = getAtmosphericFog(color, eyePlayerPos);
    }
    // color.rgb = mix(color.rgb, cloudColor.rgb, cloudColor.a);

  }
#endif