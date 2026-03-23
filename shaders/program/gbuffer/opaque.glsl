/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
#include "/lib/common.glsl"

#ifdef vsh
in vec2 mc_Entity;
in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 lightmap;
out vec2 texcoord;
out vec4 glcolor;
out mat3 tbn;
out vec3 viewPos;

flat out uint materialID;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

  vec2 lmcoord = gl_MultiTexCoord1.xy / 255.0;
  lightmap = lmcoord / (30.0 / 32.0) - 1.0 / 32.0;

  tbn[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
  tbn[2] = normalize(gl_NormalMatrix * gl_Normal);
  tbn[1] = normalize(cross(tbn[0], tbn[2]) * at_tangent.w);

  viewPos = (gbufferProjectionInverse * gl_Position).xyz;

  glcolor = gl_Color;

  materialID = uint(mc_Entity.x);
}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/lib/util/dither.glsl"

in vec2 lightmap;
in vec2 texcoord;
in vec4 glcolor;
in mat3 tbn;
in vec3 viewPos;

flat in uint materialID;

#ifdef SSAO
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

  Gbuffer gbuffer;

  gbuffer.geometryNormal = mat3(gbufferModelViewInverse) * tbn[2];
  vec3 surfaceNormal = getSurfaceNormal(texcoord, tbn);
  gbuffer.surfaceNormal = mat3(gbufferModelViewInverse) * surfaceNormal;
  gbuffer.lightmap = lightmap;

  vec4 color = texture(gtexture, texcoord);
  color.rgb *= glcolor.rgb;
  if (
    color.a <
    max(
      alphaTestRef,
      blueNoise(gl_FragCoord.xy, frameCounter).r *
        float(renderStage == MC_RENDER_STAGE_ENTITIES)
    )
  ) {
    discard;
  }

  Material material = materialFromSpecularMap(
    pow(color.rgb, vec3(2.2)),
    texture(specular, texcoord),
    materialID
  );

  if (
    material.roughness > ROUGH_SSR_THRESHOLD &&
    material.metalID != NO_METAL
  ) {
    material.roughness = ROUGH_SSR_THRESHOLD;
  }

  gbuffer.lightmap = applyLightmapFalloff(lightmap);
  // gbuffer.lightmap *= applyDirectionalLightmap(lightmap, viewPos, surfaceNormal, tbn, material.subsurface);

  gbufferData = packGbuffer(gbuffer);
  materialData = packMaterial(material);
}

#endif
