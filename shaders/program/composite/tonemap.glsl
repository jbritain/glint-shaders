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

layout(location = 0) out vec3 color;

#include "/lib/post/tonemap.glsl"
#include "/lib/util/dither.glsl"

void main() {
  color = texture(colortex0, texcoord).rgb;

  vec3 bloom = texture(colortex16, texcoord * 0.5).rgb;
  color = mix(color, bloom, 0.001);

  color = tonemap(color);

}

#endif
