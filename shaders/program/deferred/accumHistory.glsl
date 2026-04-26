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
out vec2 texcoord;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/lighting/reflectiveShadowMapping.glsl"
#include "/lib/material/material.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 11,13 */

layout(location = 0) out uint historyCount;
layout(location = 1) out float reprojectedDepth;

void main() {
  historyCount = 0;

  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  previousPos = viewSpaceToScreenSpace(
    previousViewPos,
    gbufferPreviousProjection
  );

  reprojectedDepth = texture(colortex5, previousPos.xy).a;

  vec3 actualPreviousPos = previousViewPos;

  actualPreviousPos.z = screenSpaceToViewSpace(reprojectedDepth);
  show(-actualPreviousPos.z / far);

  if (
    clamp01(previousPos) == previousPos &&
    (distance(actualPreviousPos, previousViewPos) < 0.1 ||
      distance(cameraPosition, previousCameraPosition) < 0.01)
  ) {
    historyCount = texture(colortex11, texcoord).r + 1;
  }

}

#endif
