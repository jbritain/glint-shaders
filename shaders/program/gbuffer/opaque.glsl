/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
#include "/lib/common.glsl"

#ifdef vsh
#include "/lib/misc/waving.glsl"

in vec2 mc_Entity;
in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 lightmap;
out vec2 texcoord;
out vec4 glcolor;
out mat3 tbn;
out vec3 viewPos;
out float emission;

flat out uint materialID;

#ifdef PARALLAX
flat out vec2 singleTexSize;
flat out ivec2 pixelTexSize;
flat out vec4 textureBounds;
#endif

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

  vec2 lmcoord = gl_MultiTexCoord1.xy / 240;
  lightmap = clamp01(lmcoord / (30.0 / 32.0) - 1.0 / 32.0);

  tbn[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
  tbn[2] = normalize(gl_NormalMatrix * gl_Normal);
  tbn[1] = normalize(cross(tbn[0], tbn[2]) * at_tangent.w);

  viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  materialID = uint(mc_Entity.x);
  feetPlayerPos =
    getVertexWave(feetPlayerPos + cameraPosition, materialID, at_midBlock.xyz) -
    cameraPosition;
  viewPos = transformView(feetPlayerPos, gbufferModelView);

  gl_Position = gbufferProjection * vec4(viewPos, 1.0);

  glcolor = gl_Color;

  if (
    renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
    renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT
  ) {
    emission = at_midBlock.w / 15.0;
  } else {
    emission = 0;
  }

  #ifdef PARALLAX
  vec2 halfSize = abs(texcoord - mc_midTexCoord);
  textureBounds = vec4(
    mc_midTexCoord.xy - halfSize,
    mc_midTexCoord.xy + halfSize
  );

  singleTexSize = halfSize * 2.0;
  pixelTexSize = ivec2(singleTexSize * atlasSize);
  #endif

}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/lib/material/integratedPBR.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/water/puddles.glsl"

in vec2 lightmap;
in vec2 texcoord;
in vec4 glcolor;
in mat3 tbn;
in vec3 viewPos;
in float emission;

#ifdef PARALLAX
flat in vec2 singleTexSize;
flat in ivec2 pixelTexSize;
flat in vec4 textureBounds;
#include "/lib/misc/parallax.glsl"
#endif

flat in uint materialID;

#if AO > 0
/* RENDERTARGETS: 1,2 */
#else
/* RENDERTARGETS: 1,2,3 */
#endif

layout(location = 0) out uvec3 gbufferData;
layout(location = 1) out uvec2 materialData;
#ifndef SSAO
layout(location = 2) out float occlusion;
#endif

void main() {
  #ifndef SSAO
  occlusion = pow2(glcolor.a);
  #endif

  #ifdef PARALLAX

  float pomJitter = interleavedGradientNoise(
    floor(gl_FragCoord.xy),
    frameCounter
  );

  vec3 parallaxPos;
  vec2 dx = dFdx(texcoord);
  vec2 dy = dFdy(texcoord);
  vec2 texcoord = texcoord;
  if (
    renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
    renderStage == MC_RENDER_STAGE_ENTITIES ||
    renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
  ) {
    texcoord = getParallaxTexcoord(
      texcoord,
      viewPos,
      tbn,
      parallaxPos,
      dx,
      dy,
      pomJitter
    );
  }
  #endif

  Gbuffer gbuffer;

  vec4 color = texture(gtexture, texcoord);
  color.rgb *= glcolor.rgb;
  if (color.a < alphaTestRef) {
    discard;
  }

  Material material = materialFromSpecularMap(
    sRGBToLinear(color.rgb),
    texture(specular, texcoord),
    materialID
  );
  vec3 surfaceNormal = getSurfaceNormal(texcoord, tbn);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  applyIntegratedPBR(material);
  applyPuddles(
    material,
    texture(gtexture, texcoord).a,
    feetPlayerPos + cameraPosition,
    surfaceNormal,
    tbn[2],
    lightmap.y
  );
  // if (material.metalID != NO_METAL && gl_FragCoord.x > viewWidth / 2) {
  //   material.metalID = OTHER_METAL;
  // }

  gbuffer.geometryNormal = mat3(gbufferModelViewInverse) * tbn[2];

  gbuffer.surfaceNormal = mat3(gbufferModelViewInverse) * surfaceNormal;
  gbuffer.lightmap = lightmap;

  #ifdef WHITE_WORLD
  material.albedo = vec3(1.0);
  #endif

  #ifndef MC_TEXTURE_FORMAT_LAB_PBR
  material.emission = luminance(material.albedo) * emission;
  #endif

  if (
    material.roughness > ROUGH_SSR_THRESHOLD &&
    material.metalID != NO_METAL
  ) {
    material.roughness = ROUGH_SSR_THRESHOLD;
  }

  gbuffer.lightmap = applyLightmapFalloff(lightmap);
  // gbuffer.lightmap +=
  //   (interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter) - 0.5) / 15;
  // gbuffer.lightmap *= applyDirectionalLightmap(
  //   lightmap,
  //   viewPos,
  //   surfaceNormal,
  //   tbn,
  //   material.subsurface
  // );

  gbufferData = packGbuffer(gbuffer);
  materialData = packMaterial(material);
}

#endif
