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

layout(location = 0) out vec3 color;

uniform sampler2D debugtex;

#include "/lib/post/tonemap.glsl"
#include "/lib/util/dither.glsl"

void main() {
  color = texture(colortex0, texcoord).rgb;

  vec3 bloom = texture(colortex6, texcoord * 0.5).rgb;
  color = mix(color, bloom, 0.01);

  color *= 126 / 15;
  color = tonemap(color);
}

#endif
