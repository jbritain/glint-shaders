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

in vec2 texcoord;

/* RENDERTARGETS: 11 */

layout(location = 0) out float depth;

void main() {
  float currentDepth = texture(depthtex0, texcoord).r;
  vec3 pos = vec3(texcoord, currentDepth);
  pos = screenSpaceToViewSpace(pos);
  pos = transformView(pos, gbufferModelViewInverse);
  pos += cameraPosition - previousCameraPosition;
  pos = transformView(pos, gbufferPreviousModelView);
  pos = viewSpaceToScreenSpace(pos, gbufferPreviousProjection);
  depth = texture(depthtex0, texcoord).r;

}

#endif
