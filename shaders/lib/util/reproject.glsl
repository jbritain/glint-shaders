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
mat4 gbufferPreviousProjectionInverse = inverse(gbufferPreviousProjection);

#include "/lib/util/spaceConversions.glsl"

vec3 previousViewSpaceToPreviousScreenSpace(vec3 viewPosition) {
  vec3 screenPosition  = vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * viewPosition + gbufferPreviousProjection[3].xyz;
      screenPosition /= -viewPosition.z;

  return screenPosition * 0.5 + 0.5;
}

vec3 previousScreenSpaceToPreviousViewSpace(vec3 screenPosition){
  screenPosition = screenPosition * 2.0 - 1.0;

	vec3 viewPosition  = vec3(vec2(gbufferPreviousProjectionInverse[0].x, gbufferPreviousProjectionInverse[1].y) * screenPosition.xy + gbufferPreviousProjectionInverse[3].xy, gbufferPreviousProjectionInverse[3].z);

  viewPosition /= gbufferPreviousProjectionInverse[2].w * screenPosition.z + gbufferPreviousProjectionInverse[3].w;

	return viewPosition;
}

vec3 reproject(vec3 screenPos){

  vec3 viewPos = screenSpaceToViewSpace(screenPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  feetPlayerPos += cameraPosition;
  feetPlayerPos -= previousCameraPosition;
  vec3 previousViewPos = (gbufferPreviousModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec3 previousScreenPos = previousViewSpaceToPreviousScreenSpace(previousViewPos);

  return previousScreenPos;
}

#endif