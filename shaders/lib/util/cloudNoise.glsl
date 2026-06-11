/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef CLOUD_NOISE_GLSL
#define CLOUD_NOISE_GLSL

// "Hash functions for GPU rendering"
// https://www.shadertoy.com/view/XlGcRh
uvec3 pcg3d(uvec3 v) {
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

vec3 hash(ivec3 p) {
  return vec3(pcg3d(uvec3(p))) / 4294967295.0;
}

// Code adapted from "Volumetric Clouds and Atmosphere in DOOM: The Dark Ages" in GPU Zen 4: Advanced Rendering Techniques

float worleyNoise(vec3 uv, int numCells) {
  vec3 cellPos = uv * numCells;
  ivec3 cellID = ivec3(cellPos);
  vec3 w = fract(cellPos);
  float minDistSq = 10000.0;
  // Prevent top left always hashing to same value
  cellID += ivec3(443189, 79301, 41681);
  for (int z = -1; z <= 1; ++z) {
    for (int y = -1; y <= 1; ++y) {
      for (int x = -1; x <= 1; ++x) {
        ivec3 vertexId = (cellID + ivec3(x, y, z)) % numCells;
        vec3 pointFrac = hash(vertexId);
        vec3 toPoint = vec3(x, y, z) + pointFrac - w;
        minDistSq = min(minDistSq, dot(toPoint, toPoint));
      }
    }
  }
  return 1.0 - minDistSq;
}

float perlinNoise(vec3 uv, int numCells) {
  vec3 cellPos = uv * numCells;
  ivec3 cellID = ivec3(cellPos);
  vec3 w = fract(cellPos);
  // Prevent top left always hashing to same value
  cellID += ivec3(443189, 79301, 41681);

  vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
  float noise = 0.0;

  vec3 weights = vec3(0.0);

  weights.z = 1.0 - u.z;
  for (int z = 0; z <= 1; ++z) {
    weights.y = 1.0 - u.y;
    for (int y = 0; y <= 1; ++y) {
      weights.x = 1.0 - u.x;
      for (int x = 0; x <= 1; ++x) {
        ivec3 vertexId = (cellID + ivec3(x, y, z)) % numCells;
        vec3 gradVec = hash(vertexId) * 2.0 - 1.0;
        float dotProduct = dot(gradVec, w - vec3(x, y, z));
        noise += weights.x * weights.y * weights.z * dotProduct;
        weights.x = 1.0 - weights.x;
      }
      weights.y = 1.0 - weights.y;
    }
    weights.z = 1.0 - weights.z;
  }
  return noise;
}

#endif // CLOUD_NOISE_GLSL
