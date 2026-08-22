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

#ifndef WAVING_GLSL
#define WAVING_GLSL

#include "/mcwind/mcwind.glsl"
#include "/mcwind/mcwind_field.glsl"

vec3 getVertexWave(vec3 worldPos, uint materialID, vec3 midBlock) {
  vec3 blockCentre = worldPos + midBlock / 64;
  vec3 delta = vec3(0.0);

  #ifdef MCWIND
  if (materialIsGrass(materialID)) {
    float upper = materialIsTop_Half(materialID) ? 1.0 : 0.0;
    float w = mcw_grassHeight(worldPos, blockCentre, upper);
    delta.xz = mcw_grassPush(blockCentre, w);

    delta.xz += mcw_draftPush(blockCentre, cameraPosition, w);
  } else if (materialIsLeaves(materialID) || materialIsHanging(materialID)) {
    float weld = mcw_leafWeld(worldPos, blockCentre);
    delta = mcw_leafSway(worldPos, blockCentre, weld);
    if (materialIsHanging(materialID)) {
      delta.xz += mcw_vineSwing(worldPos, blockCentre, weld);
    }

  } else if (materialIsFire(materialID)) {
    delta = mcw_fireLean(blockCentre, step(blockCentre.y, worldPos.y));
  }
  #endif

  return worldPos + delta;
}

#endif
