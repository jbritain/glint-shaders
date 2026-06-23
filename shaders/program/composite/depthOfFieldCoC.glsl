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

/* RENDERTARGETS: 6 */

#include "/lib/post/camera.glsl"

layout(location = 0) out float coc;

void main() {
  float depth = -screenSpaceToViewSpace(texture(depthtex0, texcoord).r);

  if (texture(depthtex2, texcoord).r != texture(depthtex1, texcoord).r) {
    coc = 0.0;
  } else {
    float focusDepth = -screenSpaceToViewSpace(centerDepthSmooth);
    coc = circleOfConfusion(depth, focusDepth);
  }

}

#endif
