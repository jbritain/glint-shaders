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

/* RENDERTARGETS: 4 */

layout(location = 0) out float importance;

// https://lisyarus.github.io/blog/posts/blur-coefficients-generator.html
const float OFFSETS[6] = float[6](
  -4.378621204796657,
  -2.431625915613778,
  -0.4862426846689485,
  1.4588111840004858,
  3.4048471718931532,
  5
);
const float WEIGHTS[6] = float[6](
  0.09461172151436463,
  0.20023097066826712,
  0.2760751120037518,
  0.24804559825032563,
  0.14521459357563646,
  0.035822003987654526
);

void main() {
  importance = 0.0;
  for (int i = 0; i < 6; i++) {
    vec2 offset = vec2(OFFSETS[i] / 256, 0.0);
    importance += texture(colortex4, texcoord + offset).r * WEIGHTS[i];
  }
}

#endif
