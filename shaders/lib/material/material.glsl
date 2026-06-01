/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef MATERIAL_GLSL
#define MATERIAL_GLSL

#include "/lib/util/packing.glsl"
#include "/lib/util/dither.glsl"

struct Gbuffer {
  vec3 surfaceNormal;
  vec3 geometryNormal;
  vec2 lightmap;
};

uvec3 packGbuffer(Gbuffer gbuffer) {
  uvec3 packedGbuffer = uvec3(0);

  vec2 packedSurface = encodeUnitVector(gbuffer.surfaceNormal);
  vec2 packedGeometry = encodeUnitVector(gbuffer.geometryNormal);

  gbuffer.lightmap = pow(gbuffer.lightmap, vec2(rcp(2.2)));

  packedGbuffer.r = bitfieldInsert(
    packedGbuffer.r,
    uint(packedSurface.r * 255),
    0,
    8
  );
  packedGbuffer.r = bitfieldInsert(
    packedGbuffer.r,
    uint(packedSurface.g * 255),
    8,
    8
  );

  packedGbuffer.g = bitfieldInsert(
    packedGbuffer.g,
    uint(packedGeometry.r * 255),
    0,
    8
  );
  packedGbuffer.g = bitfieldInsert(
    packedGbuffer.g,
    uint(packedGeometry.g * 255),
    8,
    8
  );

  packedGbuffer.b = bitfieldInsert(
    packedGbuffer.b,
    uint(gbuffer.lightmap.x * 255),
    0,
    8
  );
  packedGbuffer.b = bitfieldInsert(
    packedGbuffer.b,
    uint(gbuffer.lightmap.y * 255),
    8,
    8
  );

  return packedGbuffer;
}

Gbuffer unpackGbuffer(uvec3 packedGbuffer) {
  Gbuffer gbuffer;

  vec2 packedSurface;
  vec2 packedGeometry;

  packedSurface.r = float(bitfieldExtract(packedGbuffer.r, 0, 8)) / 255.0;
  packedSurface.g = float(bitfieldExtract(packedGbuffer.r, 8, 8)) / 255.0;

  packedGeometry.r = float(bitfieldExtract(packedGbuffer.g, 0, 8)) / 255.0;
  packedGeometry.g = float(bitfieldExtract(packedGbuffer.g, 8, 8)) / 255.0;

  gbuffer.surfaceNormal = decodeUnitVector(packedSurface);
  gbuffer.geometryNormal = decodeUnitVector(packedGeometry);

  gbuffer.lightmap.x = float(bitfieldExtract(packedGbuffer.b, 0, 8)) / 255.0;
  gbuffer.lightmap.y = float(bitfieldExtract(packedGbuffer.b, 8, 8)) / 255.0;

  gbuffer.lightmap = pow(gbuffer.lightmap, vec2(2.2));
  gbuffer.lightmap = clamp01(gbuffer.lightmap);

  return gbuffer;
}

#define NO_METAL 0
#define IRON 1
#define GOLD 2
#define ALUMINIUM 3
#define CHROME 4
#define COPPER 5
#define LEAD 6
#define PLATINUM 7
#define SILVER 8
#define OTHER_METAL 9

// metal properties obtained from https://physicallybased.info/
const vec3 metalF0[9] = vec3[](
  vec3(0.04),
  vec3(0.53, 0.513, 0.494),
  vec3(1.059, 0.773, 0.307),
  vec3(0.916, 0.923, 0.924),
  vec3(0.654, 0.685, 0.701),
  vec3(0.932, 0.623, 0.522),
  vec3(0.626, 0.64, 0.693),
  vec3(0.765, 0.73, 0.676),
  vec3(0.991, 0.985, 0.974)
);

const vec3 metalF82[9] = vec3[](
  vec3(1.0),
  vec3(0.765, 0.767, 0.802),
  vec3(0.971, 1.018, 0.994),
  vec3(0.91, 0.936, 0.959),
  vec3(0.688, 0.728, 0.798),
  vec3(0.982, 0.947, 0.945),
  vec3(0.758, 0.773, 0.799),
  vec3(0.793, 0.815, 0.84),
  vec3(0.994, 0.995, 0.998)
);

struct Material {
  vec3 albedo;
  float emission;
  vec3 f0;
  uint metalID;
  float roughness;
  float subsurface;
  float porosity;
  float ao;
  uint id;
};

Material defaultMaterial = Material(
  vec3(0.0),
  0.0,
  vec3(0.04),
  NO_METAL,
  1.0,
  0.0,
  0.0,
  1.0,
  0
);

Material materialFromSpecularMap(
  vec3 albedo,
  vec4 specularData,
  uint materialID
) {
  Material material;

  material.albedo = albedo;
  material.roughness = pow2(1.0 - specularData.r);
  if (specularData.g <= 229.0 / 255.0) {
    material.f0 = vec3(specularData.g);
    material.metalID = NO_METAL;
  } else {
    material.f0 = albedo;
    material.metalID = int(specularData.g * 255 + 0.5) - 229;
  }

  if (specularData.b <= 0.25) {
    material.porosity = specularData.b * 4.0;
    material.subsurface = 0.0;
  } else {
    material.porosity = (1.0 - specularData.r) * specularData.g; // fall back to using roughness and base reflectance for porosity
    material.subsurface = (specularData.b - 0.25) * 4.0 / 3.0;
  }

  material.emission = specularData.a < 1.0 ? specularData.a : 0.0;
  material.id = materialID;

  return material;
}

uvec2 packMaterial(Material material) {
  uvec2 data = uvec2(0);

  material.albedo = linearToSRGB(material.albedo);
  data.r = bitfieldInsert(data.r, uint(material.albedo.r * 255), 0, 8);
  data.r = bitfieldInsert(data.r, uint(material.albedo.g * 255), 8, 8);
  data.r = bitfieldInsert(data.r, uint(material.albedo.b * 255), 16, 8);
  data.r = bitfieldInsert(data.r, uint(material.emission * 255), 24, 8);

  data.g = bitfieldInsert(data.g, uint(material.roughness * 255), 0, 8);
  float packedF0 =
    material.metalID == NO_METAL
      ? material.f0.r
      : (material.metalID + 229) / 255.0;
  data.g = bitfieldInsert(data.g, uint(packedF0 * 255), 8, 8);
  data.g = bitfieldInsert(data.g, uint(material.subsurface * 255), 16, 8);
  data.g = bitfieldInsert(data.g, uint(material.ao * 15), 24, 4);

  // only the first 15 material IDs get stored, so anything that needs a deferred effect must have an ID < 16
  if (material.id < 1016) {
    data.g = bitfieldInsert(data.g, uint(material.id - 999), 28, 4);
  }

  return data;
}

Material unpackMaterial(uvec2 data) {
  Material material;
  material.albedo.r = bitfieldExtract(data.r, 0, 8) / 255.0;
  material.albedo.g = bitfieldExtract(data.r, 8, 8) / 255.0;
  material.albedo.b = bitfieldExtract(data.r, 16, 8) / 255.0;
  material.albedo = sRGBToLinear(material.albedo);

  material.emission = bitfieldExtract(data.r, 24, 8) / 255.0;

  material.roughness = bitfieldExtract(data.g, 0, 8) / 255.0;
  float specularG = bitfieldExtract(data.g, 8, 8) / 255.0;
  if (specularG <= 229.0 / 255.0) {
    material.f0 = vec3(specularG);
    material.metalID = NO_METAL;
  } else {
    material.f0 = material.albedo;
    material.metalID = int(specularG * 255 + 0.5) - 229;
  }
  material.subsurface = bitfieldExtract(data.g, 16, 8) / 255.0;
  material.ao = bitfieldExtract(data.g, 24, 4) / 15.0;
  material.id = bitfieldExtract(data.g, 28, 4) + 999;

  return material;
}

#endif
