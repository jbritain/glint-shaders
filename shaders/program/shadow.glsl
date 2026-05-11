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
layout(r32ui) uniform uimage3D voxelMap;

in vec2 mc_Entity;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 shadowViewPos;

flat out uint materialID;

#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/misc/voxel.glsl"

void main() {
  gl_Position = ftransform();

  shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  materialID = uint(mc_Entity.x);
  vec3 worldNormal = mat3(shadowModelViewInverse) * normal;

  vec3 feetPlayerPos = transformView(shadowViewPos, shadowModelViewInverse);

  normal = normalize(gl_NormalMatrix * gl_Normal);
  vec3 screenPos = gl_Position.xyz * 0.5 + 0.5;
  imageAtomicMax(
    undistortedShadowMap,
    ivec2(screenPos.xy * imageSize(undistortedShadowMap) + 0.5),
    floatBitsToUint(1.0 - screenPos.z)
  );

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

    // if (isEndPortal(blockEntityId)) {
    //   data.emission = 1.0;
    // }

    // data.emission = textureLod(specular, mc_midTexCoord, 4).a;
    // if(data.emission == 1.0){
    //     data.emission = 0.0;
    // }

    // if (isTintedGlass(materialID)) {
    //   data.opacity = 1.0;
    // }

    // if (isLetsLightThrough(materialID)) {
    //   data.opacity = 0.0;
    // }

    // if (isWater(materialID)) {
    //   data.color = 1.0 - WATER_SCATTERING;
    // }

    uint encodedVoxelData = encodeVoxelData(data);
    imageAtomicMax(voxelMap, voxelPos, encodedVoxelData);
  }
  #endif

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

flat in uint materialID;

#include "/lib/water/waveNormals.glsl"

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec2 encodedNormal;
layout(location = 2) out vec3 caustics;

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }

  caustics = vec3(0.0);

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

    const vec3 iors = vec3(1 / 1.332, 1 / 1.333, 1 / 1.336);

    float oldArea = length(dFdx(feetPlayerPos)) * length(dFdy(feetPlayerPos));

    for (int i = 0; i < 3; i++) {
      vec3 refracted = refract(worldLightDir, wave, iors[i]);
      vec3 newPos = feetPlayerPos + refracted * blockerDistance;

      // https://medium.com/@evanwallace/rendering-realtime-caustics-in-webgl-2a99a29a0b2c
      // I do not understand entirely what this does but it seems to work

      float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

      caustics[i] = 1.0 - oldArea / newArea * 0.1;
    }

  }

  encodedNormal = normal.xy * 0.5 + 0.5;
}

#endif
