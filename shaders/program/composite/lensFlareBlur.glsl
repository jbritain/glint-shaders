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

in vec2 texcoord;

#ifdef BLEND
/* RENDERTARGETS: 0 */
#else
/* RENDERTARGETS: 6 */
#endif

#include "/lib/util/blur.glsl"
layout(location = 0) out vec3 color;

void main() {
  vec3 lensFlares = blur13(colortex6, texcoord, 0, DIRECTION).rgb;

  #ifdef BLEND
  color = texture(colortex0, texcoord).rgb + lensFlares * 0.1;
  #else
  color = lensFlares;
  #endif
}

#endif
