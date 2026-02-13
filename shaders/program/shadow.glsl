/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
#include "/lib/common.glsl"

#ifdef vsh

layout(r32ui) uniform uimage2D undistortedShadowMap;

in vec2 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

flat out uint materialID;

#include "/lib/util/rectilinearWarp.glsl"

void main() {
  gl_Position = ftransform();
  normal = normalize(gl_NormalMatrix * gl_Normal);
  vec3 screenPos = gl_Position.xyz * 0.5 + 0.5;
  imageAtomicMax(
    undistortedShadowMap,
    ivec2(screenPos.xy * imageSize(undistortedShadowMap) + 0.5),
    floatBitsToUint(1.0 - screenPos.z)
  );

  screenPos.xy += getWarp(screenPos.xy);
  screenPos.z /= SHADOW_Z_STRETCH;
  gl_Position.xyz = screenPos * 2.0 - 1.0;

  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;

  materialID = uint(mc_Entity.x);
}
#endif

// ==============================================================================================

#ifdef fsh

in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

flat in uint materialID;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec2 encodedNormal;

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }
  encodedNormal = normal.xy * 0.5 + 0.5;
}

#endif
