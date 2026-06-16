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

/* RENDERTARGETS: 15 */

layout(location = 0) out vec3 globalIllumination;

void main() {
  globalIllumination = vec3(0.0);
  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);

  if (depth == 1.0) {
    return;
  }

  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  float caustics;
  globalIllumination = getReflectiveShadowMap(
    feetPlayerPos,
    gbuffer.geometryNormal
  );

  #ifdef RSM_LIGHT_LEAK_FIX
  globalIllumination *= smoothstep(0.0, 0.2, gbuffer.lightmap.y);
  #endif

  // vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  // vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  // previousPos = viewSpaceToScreenSpace(
  //   previousViewPos,
  //   gbufferPreviousProjection
  // );

  // uint frameCount = min(texture(colortex11, texcoord).r, RSM_MAX_FRAMES);

  // vec3 previousGI = texture(colortex9, previousPos.xy).rgb;
  // globalIllumination =
  //   (previousGI * frameCount + globalIllumination) / (frameCount + 1);

}

#endif
