/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_hand.glsl
    - Hand, both opaque and translucent
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out mat3 tbnMatrix;
  flat out int materialID;
  out vec3 viewPos;

  flat out vec3 sunlightColor;
  flat out vec3 skyLightColor;

  uniform int worldTime;
  uniform int worldDay;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;
  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform float far;

  uniform ivec2 eyeBrightnessSmooth;

  in vec4 at_tangent;
  in vec2 mc_Entity;
  in vec3 at_midBlock;

  #include "/lib/util.glsl"

  void main() {

    gl_Position = ftransform();
    materialID = int(mc_Entity.x + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    
    tbnMatrix[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
    tbnMatrix[2] = normalize(gl_NormalMatrix * gl_Normal);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * at_tangent.w);

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;
  uniform sampler2D noisetex;

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
  uniform sampler2D colortex12;

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



  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/lighting/diffuseShading.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/material.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/lighting/specularShading.glsl"




  vec3 getMappedNormal(vec2 texcoord){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    return tbnMatrix * mappedNormal;
  }

  /* DRAWBUFFERS:5 */
  layout(location = 0) out vec4 color; // shaded colour

  void main() {
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    vec3 faceNormal = tbnMatrix[2];

    color = texture(gtexture, texcoord) * glcolor;

    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord);
    #else
      vec3 mappedNormal = faceNormal;
    #endif

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, texcoord);
    #else
    vec4 specularData= vec4(0.0);
    #endif

    Material material;
    material = materialFromSpecularMap(color.rgb, specularData);


    float scatter;
    vec3 sunlight = getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, mappedNormal, faceNormal, material.sss, lightmap, scatter);


    vec3 skyLightColor;
    vec3 sunlightColor;
    getLightColors(sunlightColor, skyLightColor, eyePlayerPos, faceNormal);

    vec3 diffuse = getDiffuseColor(lightmap, material, skyLightColor);
    vec3 fresnel;
    vec3 specular = getSpecularColor(color.rgb, lightmap, mappedNormal, viewPos, material, fresnel);


    color.rgb = (brdf(material, mappedNormal, faceNormal, viewPos) * sunlight + vec3(scatter) * material.albedo) * sunlightColor;
    // color.rgb += mix(diffuse, specular, fresnel);
    color.rgb += material.emission * 40.0 * material.albedo;
    // color.a *= (1.0 - max3(fresnel));
  }
#endif