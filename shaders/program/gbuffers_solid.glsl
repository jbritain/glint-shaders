/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_solid.glsl
    - Solid terrain
    - Solid entities
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
  uniform sampler2D noisetex;

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
  uniform sampler2D noisetex;

  uniform sampler2D colortex3;

  uniform vec4 entityColor;

  uniform float alphaTestRef;

  uniform vec3 cameraPosition;
  uniform vec3 shadowLightPosition;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in mat3 tbnMatrix;
  flat in int materialID;
  in vec3 viewPos;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform float wetness;
  uniform int biome_precipitation;

  uniform int frameCounter;

  flat in vec2 singleTexSize;
  flat in ivec2 pixelTexSIze;
  flat in vec4 textureBounds;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/misc/parallax.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/water/puddles.glsl"
  #include "/lib/lighting/directionalLightmap.glsl"

  vec3 getMappedNormal(vec2 texcoord){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    return tbnMatrix * mappedNormal;
  }

  /* RENDERTARGETS: 1,2,3 */
  layout(location = 0) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 1) out vec4 outData2; // mapped normal, specular map data
  layout(location = 2) out vec4 outData3; // nothing in the rgb but parallax shadow in the a

  void main() {
    float parallaxShadow = 1.0;
    #if defined POM && !defined gbuffers_spidereyes
    vec2 texcoord = texcoord;
    vec2 dx = dFdx(texcoord);
    vec2 dy = dFdy(texcoord);
    vec3 parallaxPos;
    if(length(viewPos) < 32.0){
      vec2 pomJitter = vec2(interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter));
      texcoord = getParallaxTexcoord(texcoord, viewPos, tbnMatrix, parallaxPos, dx, dy, pomJitter.x);
      #ifdef POM_SHADOW
      parallaxShadow = getParallaxShadow(parallaxPos, tbnMatrix, dx, dy, pomJitter.y) ? smoothstep(0.0, 32.0, length(viewPos)) : 1.0;
      #endif
    }
    #endif
    outData3.rgb = texture(colortex3, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rgb;
    outData3.a = parallaxShadow;

    vec4 color;
    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord);
    #else
      vec3 mappedNormal = tbnMatrix[2];
    #endif

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, texcoord);

    float rainingFactor = float(biome_precipitation == PPT_RAIN) * wetness;

    if(rainingFactor > 0.0){
      float porosity = specularData.b <= 0.25 ? specularData.b * 4.0 : (1.0 - specularData.r) * specularData.g;

      vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
      float wetnessFactor = getWetnessFactor(feetPlayerPos + cameraPosition, porosity, texture(normals, texcoord).a, lightmap, mat3(gbufferModelViewInverse) * mappedNormal) * rainingFactor;
      color.rgb = mix(color.rgb, vec3(0.0), porosity * rainingFactor);
      specularData.g = specularData.g <= 229.0/255.0 ? mix(specularData.g, 0.02, wetnessFactor) : specularData.g;
      specularData.r = clamp01(specularData.r + wetnessFactor);
      mappedNormal = tbnMatrix[2];
    }
    #else
    vec4 specularData = vec4(0.0);
    #endif

    #ifdef DIRECTIONAL_LIGHTMAPPING
    applyDirectionalLightmap(lightmap, viewPos, mappedNormal, tbnMatrix, specularData.b > 0.25 ? (specularData.b - 0.25) * 4.0/3.0 : 0.0);
    #endif


    // encode gbuffer data
    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * tbnMatrix[2]));
    outData1.w = pack2x8F(lightmap);

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);
  }
#endif