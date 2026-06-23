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

#include "/lib/util/atrous.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 15 */

layout(location = 0) out vec3 globalIllumination;

void main() {
  // globalIllumination = texture(colortex15, texcoord).rgb;
  globalIllumination = atrous(colortex15, texcoord, 4.0, 0.01, 1.0, STRIDE);
}

#endif
