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

/* RENDERTARGETS: 6 */

#include "/lib/post/lensFlares.glsl"

layout(location = 0) out vec3 lensFlares;

// const bool colortex0MipmapEnabled = true;

void main() {
  lensFlares = sampleGhosts(texcoord) * 0.0001;

  lensFlares += sampleHalos(texcoord) * 0.0001;

  lensFlares.g *= 0.7;

  lensFlares;

}

#endif
