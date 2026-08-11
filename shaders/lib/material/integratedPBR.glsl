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

#ifndef IPBR_GLSL
#define IPBR_GLSL

#include "/lib/material/material.glsl"

void applyIntegratedPBR(inout Material material) {
  if (materialIsWater(material.id)) {
    material.roughness = 0.0;
    material.f0 = vec3(0.02);
    material.albedo = vec3(0.0);
  }

  #ifdef MC_TEXTURE_FORMAT_LAB_PBR_1_3
  return;
  #endif

  if (materialIsFoliage(material.id)) {
    material.subsurface = 1.0;
  }

  #ifdef INTEGRATED_SPECULAR
  if (materialIsIron(material.id)) {
    material.roughness = pow2(luminance(material.albedo)) * 0.1;
    material.metalID = IRON;
  } else if (materialIsGold(material.id)) {
    material.roughness = pow2(luminance(material.albedo)) * 0.1;
    material.metalID = GOLD;
  } else if (materialIsCopper(material.id)) {
    material.roughness = pow2(material.albedo.g);
    if (material.albedo.g < material.albedo.r) {
      material.metalID = COPPER;
    }
  } else if (materialIsDiamond(material.id)) {
    material.roughness = 0.0;
    material.f0 = vec3(0.171);
    material.subsurface = 1.0;
  } else if (materialIsObsidian(material.id)) {
    material.roughness = material.albedo.r * 0.1 + 0.02;
  } else if (materialIsIce(material.id)) {
    material.roughness = 0.0;
    material.f0 = vec3(0.02);
  } else if (materialIsWool(material.id)) {
    material.subsurface = 1.0;
  } else if (materialIsSand(material.id)) {
    material.subsurface = 1.0;
  } else if (materialIsGlass(material.id)) {
    material.roughness = 0.0;
  }

  #ifdef EVERYTHING_CHROME
  material.roughness = 0.0;
  material.metalID = CHROME;
  #endif
  #endif
}

#endif // IPBR_GLSL
