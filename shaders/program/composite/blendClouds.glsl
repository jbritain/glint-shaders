/*
    Copyright (c) 2025 Josh Britain (jbritain)
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

layout(location = 0) out vec4 color;

#include "/lib/atmosphere/clouds.glsl"

void main() {

  color = texture(colortex0, texcoord);

  bool blend;
  #ifdef BLEND_BEFORE_TRANSLUCENTS
  blend = cameraPosition.y < CLOUDS_BASE_ALTITUDE;
  #else
  blend = cameraPosition.y >= CLOUDS_BASE_ALTITUDE;
  #endif

  if(blend){
    vec4 clouds = texture(colortex8, texcoord);

    color.rgb = fma(color.rgb, vec3(clouds.a), clouds.rgb);
  }

}

#endif
