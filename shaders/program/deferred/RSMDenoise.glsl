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

#include "/lib/material/material.glsl"
#include "/lib/lighting/ssao.glsl"
#include "/lib/lighting/gtao.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 9 */

layout(location = 0) out vec3 GI;

#define BLUR_RADIUS 3

void main() {
  // GI = texture(colortex9, texcoord).rgb;
  // return;

  GI = vec3(0.0);
  float totalWeight = 0.0;

  for (int x = -BLUR_RADIUS; x <= BLUR_RADIUS; x++) {
    for (int y = -BLUR_RADIUS; y <= BLUR_RADIUS; y++) {
      vec2 offset = vec2(x, y);
      float weight = exp(-dot(offset, offset) / 2);
      GI +=
        texelFetch(colortex9, ivec2(gl_FragCoord.xy + offset), 0).rgb * weight;
      totalWeight += weight;
    }
  }

  GI /= totalWeight;

}

#endif
