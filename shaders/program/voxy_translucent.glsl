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

#define GBUFFERS_VOXY

#include "/lib/common.glsl"
#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/material/integratedPBR.glsl"

layout(location = 0) out vec4 color;
layout(location = 1) out uvec3 gbufferData;
layout(location = 2) out uvec2 materialData;

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

  color = params.sampledColour * params.tinting;

  Material material = defaultMaterial;
  material.albedo = pow(color.rgb, vec3(2.2));
  material.id = params.customId;
  applyIntegratedPBR(material);
  if (materialIsWater(material.id)) {
    color.a = 0.01;
  }

  gbuffer.lightmap = params.lightMap;
  gbuffer.lightmap = applyLightmapFalloff(gbuffer.lightmap);

  vec3 viewPos = screenSpaceToViewSpace(
    gl_FragCoord.xyz / vec3(viewWidth, viewHeight, 1.0)
  );
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  float shadow = smoothstep(13.5 / 15.0, 14.5 / 15.0, gbuffer.lightmap.y);

  color.rgb = vec3(0.0);
  #ifndef WORLD_THE_NETHER
  color.rgb =
    diffuseBRDF(
      material,
      gbuffer.geometryNormal,
      gbuffer.geometryNormal,
      viewPos
    ) *
    sunlightColor *
    shadow;
  #endif

  color.rgb += gbuffer.lightmap.y * skylightColor * material.albedo;
  color.rgb += gbuffer.lightmap.x * blocklightColor * material.albedo;
  color.rgb += material.albedo * material.emission * EMISSIVE_STRENGTH;

  gbufferData = packGbuffer(gbuffer);
  materialData = packMaterial(material);
}
