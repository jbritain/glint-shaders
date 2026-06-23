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

#include "/lib/material/material.glsl"
#include "/lib/lighting/ssao.glsl"
#include "/lib/lighting/gtao.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 3 */

layout(location = 0) out float occlusion;

void main() {
  occlusion = 1.0;
  float depth = texture(depthtex0, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);

  if (depth == 1.0) {
    return;
  }

  vec3 playerPos = transformView(viewPos, gbufferModelViewInverse);
  vec3 previousPos = playerPos + cameraPosition - previousCameraPosition;
  previousPos = transformView(previousPos, gbufferPreviousModelView);
  previousPos = viewSpaceToScreenSpace(previousPos, gbufferPreviousProjection);

  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);

  #if AO == 1
  occlusion = getSSAO(viewPos, gbuffer.geometryNormal);
  #elif AO == 2
  occlusion = getGTAO(
    viewPos,
    mat3(gbufferModelView) * gbuffer.geometryNormal,
    texcoord
  ).a;
  #endif

  uint frameCount = min(texture(colortex11, texcoord).r, AO_MAX_FRAMES);

  float previousOcclusion = texture(colortex3, previousPos.xy).r;
  occlusion = (previousOcclusion * frameCount + occlusion) / (frameCount + 1);

}

#endif
