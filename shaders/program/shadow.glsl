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
#include "/lib/util/rectilinearWarp.glsl"

#ifdef vsh

layout(r32ui) uniform uimage2D undistortedShadowMap;
layout(r32ui) uniform uimage3D voxelMap;

in vec2 mc_Entity;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 shadowViewPos;
out vec2 originalPos;

flat out uint materialID;

#include "/lib/misc/voxel.glsl"
#include "/lib/misc/waving.glsl"

void main() {
  if (
    renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
    renderStage == MC_RENDER_STAGE_TERRAIN_CUTOUT ||
    renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
  ) {
    materialID = uint(mc_Entity.x);
  } else {
    materialID = 0;
  }

  shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  vec3 feetPlayerPos = transformView(shadowViewPos, shadowModelViewInverse);
  feetPlayerPos =
    getVertexWave(feetPlayerPos + cameraPosition, materialID, at_midBlock.xyz) -
    cameraPosition;
  shadowViewPos = transformView(feetPlayerPos, shadowModelView);

  vec3 worldNormal = mat3(shadowModelViewInverse) * normal;

  normal = normalize(gl_NormalMatrix * gl_Normal);

  #ifdef FLOODFILL

  ivec3 voxelPos = mapVoxelPos(
    feetPlayerPos +
      (renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES
        ? -worldNormal * 0.2
        : vec3(at_midBlock.xyz * rcp(64.0)))
  );
  if (
    isWithinVoxelBounds(voxelPos) &&
    gl_VertexID % 4 == 0 &&
    (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID ||
      // renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES ||
      renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT ||
      renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES)
  ) {
    VoxelData data;
    vec4 averageTextureData =
      textureLod(gtexture, mc_midTexCoord, 4) * gl_Color;

    // data.color = getBlocklightColor(materialID);

    data.color = sRGBToLinear(averageTextureData.rgb);
    data.opacity =
      renderStage == MC_RENDER_STAGE_TERRAIN_SOLID
        ? 1.0
        : pow(averageTextureData.a, rcp(3));
    data.emission = pow2(at_midBlock.w / 15.0);

    if (materialIsEndPortal(blockEntityId)) {
      data.emission = 1.0;
    }

    if (materialIsTintedGlass(materialID)) {
      data.opacity = 1.0;
    }

    if (materialLetsLightThrough(materialID)) {
      data.opacity = 0.0;
    }

    if (materialIsWater(materialID)) {
      data.color = 1.0 - waterScattering;
    }

    uint encodedVoxelData = encodeVoxelData(data);
    imageAtomicMax(voxelMap, voxelPos, encodedVoxelData);
  }
  #endif

  gl_Position = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
  vec3 screenPos = gl_Position.xyz * 0.5 + 0.5;
  imageAtomicMax(
    undistortedShadowMap,
    ivec2(screenPos.xy * imageSize(undistortedShadowMap) + 0.5),
    floatBitsToUint(1.0 - screenPos.z)
  );
  originalPos = screenPos.xy;
  screenPos.xy += getWarp(screenPos.xy);
  gl_Position.xyz = screenPos * 2.0 - 1.0;

  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;

}
#endif

// ==============================================================================================

#ifdef fsh

in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 shadowViewPos;
in vec2 originalPos;

flat in uint materialID;

#include "/lib/water/waveNormals.glsl"

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec2 encodedNormal;
layout(location = 2) out vec3 originalPosAndWaterMask;

void main() {
  vec3 normal = normal;
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }

  originalPosAndWaterMask = vec3(0.0, originalPos * 0.5 + 0.5);

  if (materialIsWater(materialID)) {
    originalPosAndWaterMask.r = 1.0;
    float blockerDistance =
      texture(shadowtex1, gl_FragCoord.xy / shadowMapResolution).r -
      gl_FragCoord.z;
    blockerDistance *= shadowRange;

    color.rgb = exp(-waterExtinction * blockerDistance);
    color.a = 0.01;

    #if ( defined REFRACTIVE_CAUSTICS || defined REFLECTIVE_CAUSTICS )
    vec3 feetPlayerPos = transformView(shadowViewPos, shadowModelViewInverse);
    vec3 wave = waveNormal(
      feetPlayerPos.xz + cameraPosition.xz,
      vec3(0.0, 1.0, 0.0),
      1.0
    );
    normal = mat3(shadowModelView) * wave;
    #endif

  }

  encodedNormal = normal.xy * 0.5 + 0.5;
}

#endif
