/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

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

  if (materialIsFoliage(material.id)) {
    material.subsurface = 1.0;
  }
}

#endif // IPBR_GLSL
