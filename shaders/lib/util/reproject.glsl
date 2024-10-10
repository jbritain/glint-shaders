/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef REPROJECT_INCLUDE
#define REPROJECT_INCLUDE

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

mat4 gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView); // TODO: not this

#include "/lib/util/spaceConversions.glsl"

vec3 previousViewSpaceToPreviousScreenSpace(vec3 viewPosition) {
  vec3 screenPosition  = vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * viewPosition + gbufferPreviousProjection[3].xyz;
      screenPosition /= -viewPosition.z;

  return screenPosition * 0.5 + 0.5;
}

vec3 reproject(vec3 screenPos){

  vec3 viewPos = screenSpaceToViewSpace(screenPos);
  vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
  eyePlayerPos += gbufferModelViewInverse[3].xyz + cameraPosition; // technically feetPlayerPos now
  eyePlayerPos -= gbufferPreviousModelViewInverse[3].xyz + previousCameraPosition;
  vec3 previousViewPos = mat3(gbufferPreviousModelView) * eyePlayerPos;
  vec3 previousScreenPos = previousViewSpaceToPreviousScreenSpace(previousViewPos);

  return previousScreenPos;
}

#endif