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

layout(location = 0) out vec3 color;

const bool colortex0MipmapEnabled = true;

void main() {
  color = texture(colortex0, texcoord).rgb;

  #ifdef AUTO_EXPOSURE
  float EV100 = autoEV100(averageLuminanceSmooth);
  #else
  float EV100 = manualEV100();
  #endif
  color *= calculateExposure(EV100 - EXPOSURE_COMPENSATION);

}

#endif
