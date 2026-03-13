/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#define GBUFFERS_VOXY

#include "/lib/common.glsl"
#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/lib/util/dither.glsl"

layout(location = 0) out uvec3 gbufferData;
layout(location = 1) out uvec2 materialData;

void voxy_emitFragment(VoxyFragmentParameters params) {
  Gbuffer gbuffer;

  gbuffer.geometryNormal =
    vec3(
      uint(params.face >> 1 == 2),
      uint(params.face >> 1 == 0),
      uint(params.face >> 1 == 1)
    ) *
    (float(int(params.face) & 1) * 2 - 1);
  gbuffer.surfaceNormal = gbuffer.geometryNormal;

  vec4 color = params.sampledColour * params.tinting;

  Material material = defaultMaterial;
  material.albedo = pow(color.rgb, vec3(2.2));
  material.id = params.customId;

  if (
    material.roughness > ROUGH_SSR_THRESHOLD &&
    material.metalID != NO_METAL
  ) {
    material.roughness = ROUGH_SSR_THRESHOLD;
  }

  gbuffer.lightmap = params.lightMap;
  gbuffer.lightmap = applyLightmapFalloff(gbuffer.lightmap);

  gbufferData = packGbuffer(gbuffer);
  materialData = packMaterial(material);
}

#endif
