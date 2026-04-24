/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef VOXEL_GLSL
#define VOXEL_GLSL

struct VoxelData {
  float emission; // 4 bits
  float opacity; // 4 bits
  vec3 color; // 12 bits
};

uint encodeVoxelData(VoxelData data) {
  uint encodedData = 0;

  encodedData = bitfieldInsert(
    encodedData,
    uint(clamp01(data.emission) * 15.0),
    0,
    4
  );
  encodedData = bitfieldInsert(
    encodedData,
    uint(clamp01(data.opacity) * 15.0),
    4,
    4
  );

  vec3 encodedColor = hsv(data.color).rbg;

  encodedData = bitfieldInsert(
    encodedData,
    uint(clamp01(encodedColor.r) * 255.0),
    8,
    8
  );
  encodedData = bitfieldInsert(
    encodedData,
    uint(clamp01(encodedColor.g) * 255.0),
    16,
    8
  );
  encodedData = bitfieldInsert(
    encodedData,
    uint(clamp01(encodedColor.b) * 255.0),
    24,
    8
  );

  return encodedData;
}

VoxelData decodeVoxelData(uint encodedData) {
  VoxelData data;

  data.emission = float(uint(bitfieldExtract(encodedData, 0, 4))) / 15.0;
  data.opacity = float(bitfieldExtract(encodedData, 4, 4)) / 15.0;

  vec3 encodedColor;

  encodedColor.r = float(bitfieldExtract(encodedData, 8, 8)) / 255.0;
  encodedColor.g = float(bitfieldExtract(encodedData, 16, 8)) / 255.0;
  encodedColor.b = float(bitfieldExtract(encodedData, 24, 8)) / 255.0;

  data.color = rgb(encodedColor.rbg);

  return data;
}

// takes in a player space position and returns a position in the voxel map
ivec3 mapVoxelPos(vec3 playerPos) {
  return ivec3(
    floor(playerPos + cameraPositionFract) + ivec3(VOXEL_MAP_SIZE / 2)
  );
}

vec3 unmapVoxelPos(ivec3 voxelPos) {
  return vec3(voxelPos) - VOXEL_MAP_SIZE / 2 - cameraPositionFract;
}

bool isWithinVoxelBounds(ivec3 voxelPos) {
  return all(greaterThanEqual(voxelPos, ivec3(0))) &&
  all(lessThan(voxelPos, ivec3(VOXEL_MAP_SIZE)));
}

// for sampling the voxel texture as a sampler3D so we get interpolation
vec3 mapVoxelPosInterp(vec3 playerPos) {
  return (playerPos + cameraPositionFract + VOXEL_MAP_SIZE / 2) /
  VOXEL_MAP_SIZE;
}

ivec3 getPreviousVoxelOffset() {
  return ivec3(floor(cameraPosition) - floor(previousCameraPosition));
}

vec3 sampleFloodfill(
  vec3 playerPos,
  vec3 geometryNormal,
  vec3 surfaceNormal,
  float sss
) {
  vec3 offset = -geometryNormal * 0.5 + surfaceNormal;
  offset = mix(offset, vec3(0.0), sss * 0.25);
  vec3 voxelPosInterp = mapVoxelPosInterp(playerPos + offset);

  if (frameCounter % 2 == 0) {
    return texture(floodfillVoxelMapTex2, voxelPosInterp).rgb;
  } else {
    return texture(floodfillVoxelMapTex1, voxelPosInterp).rgb;
  }
}

vec3 sampleFloodfill(vec3 playerPos) {
  vec3 voxelPosInterp = mapVoxelPosInterp(playerPos);
  if (frameCounter % 2 == 0) {
    return texture(floodfillVoxelMapTex2, voxelPosInterp).rgb;
  } else {
    return texture(floodfillVoxelMapTex1, voxelPosInterp).rgb;
  }
}

#endif // VOXEL_MAP_GLSL
