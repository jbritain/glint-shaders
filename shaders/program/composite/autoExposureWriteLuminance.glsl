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
#include "/lib/atmosphere/atmosphere.glsl"

layout(location = 0) out vec4 color;

void main() {
  color.rgb = texture(colortex0, texcoord).rgb;
  float weight = max0(luminance(color.rgb));

  #ifdef EXCLUDE_SUN_AUTO_EXPOSURE
  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) {
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 worldDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
    if (dot(worldDir, worldSunDir) > cos(sunAngularRadius)) {
      weight = 0.0;
    }
  }
  #endif

  weight *= getMeteringWeight(texcoord);
  // show(weight);
  // show(getMeteringWeight(texcoord));

  color.a = weight;
}

#endif
