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
#include "/lib/util/upsample.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 9 */

layout(location = 0) out vec3 globalIllumination;

void main() {
  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  previousPos = viewSpaceToScreenSpace(
    previousViewPos,
    gbufferPreviousProjection
  );

  uint frameCount = min(texture(colortex11, texcoord).r, RSM_MAX_FRAMES);

  globalIllumination = upsample(
    colortex15,
    uvec2(gl_FragCoord.xy),
    depth,
    4
  ).rgb;

  vec3 previousGI = texture(colortex9, previousPos.xy).rgb;
  globalIllumination =
    (previousGI * frameCount + globalIllumination) / (frameCount + 1);
}

#endif
