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

layout(r32ui) uniform uimage2D undistortedShadowMap;

in vec2 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 shadowViewPos;

flat out uint materialID;

#include "/lib/util/rectilinearWarp.glsl"

void main() {
  gl_Position = ftransform();

  shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

  normal = normalize(gl_NormalMatrix * gl_Normal);
  vec3 screenPos = gl_Position.xyz * 0.5 + 0.5;
  imageAtomicMax(
    undistortedShadowMap,
    ivec2(screenPos.xy * imageSize(undistortedShadowMap) + 0.5),
    floatBitsToUint(1.0 - screenPos.z)
  );

  screenPos.xy += getWarp(screenPos.xy);
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
in vec3 shadowViewPos;

flat in uint materialID;

#include "/lib/water/waveNormals.glsl"

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec2 encodedNormal;
layout(location = 2) out float caustics;

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }

  caustics = 0.5;

  if (materialIsWater(materialID)) {
    float blockerDistance =
      texture(shadowtex1, gl_FragCoord.xy / shadowMapResolution).r -
      gl_FragCoord.z;
    blockerDistance *= shadowRange;

    color.rgb = exp(-waterExtinction * blockerDistance);
    color.a = 0.0;

    vec3 feetPlayerPos = transformView(shadowViewPos, shadowModelViewInverse);
    vec3 wave = waveNormal(
      feetPlayerPos.xz + cameraPosition.xz,
      vec3(0.0, 1.0, 0.0),
      1.0
    );

    vec3 refracted = refract(-worldLightDir, wave, 1.0 / 1.33);
    vec3 oldPos = feetPlayerPos - worldLightDir * blockerDistance;
    vec3 newPos = feetPlayerPos + refracted * blockerDistance;

    // https://medium.com/@evanwallace/rendering-realtime-caustics-in-webgl-2a99a29a0b2c
    // I do not understand entirely what this does but it seems to work
    float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
    float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

    caustics = oldArea / newArea;

  }

  encodedNormal = normal.xy * 0.5 + 0.5;
}

#endif
