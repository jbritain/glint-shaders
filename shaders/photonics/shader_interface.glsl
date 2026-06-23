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

#define PHOTONICS_SHADER_INTERFACE

uniform mat4 gbufferProjection;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler3D bluenoisetex;
uniform vec2 resolution;

uniform usampler2D colortex1;
uniform usampler2D colortex2;
uniform vec3 worldLightDir;

#include "/lib/common.glsl"
#include "/lib/material/material.glsl"

vec3 load_world_position() {
  vec2 texcoord = gl_FragCoord.xy / resolution;
  float depth = texture(depthtex0, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  vec3 playerPos = transformView(viewPos, gbufferModelViewInverse);
  return playerPos + cameraPosition;
}

void load_fragment_variables(
  out vec3 albedo,
  out vec3 world_pos,
  out vec3 world_normal,
  out vec3 world_normal_mapped
) {
  vec2 texcoord = gl_FragCoord.xy / resolution;
  Material material = unpackMaterial(texture(colortex2, texcoord).rg);
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);

  world_normal = gbuffer.geometryNormal;
  world_normal_mapped = gbuffer.surfaceNormal;

  albedo = material.albedo;
  world_pos = load_world_position() - 0.01f * world_normal;
}

vec2 get_taa_jitter() {
  return vec2(0.0);
}

bool is_in_world() {
  return texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x <= 0.99999f;
}
