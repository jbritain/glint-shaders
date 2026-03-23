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

/* RENDERTARGETS: 0 */

#include "/lib/post/camera.glsl"

layout(location = 0) out vec4 color;

void main() {
  color.rgb = texture(colortex0, texcoord).rgb;
  float weight = luminance(color.rgb);
  weight *= getMeteringWeight(texcoord);

  color.a = weight;
}

#endif
