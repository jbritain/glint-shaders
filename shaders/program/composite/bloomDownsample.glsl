/*
    Copyright (c) 2024 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#include "/lib/common.glsl"
#include "/lib/post/bloom.glsl"

#ifdef vsh

out vec2 texcoord;

void main() {
  gl_Position = ftransform();
  gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
  gl_Position.xy = scaleFromBloomTile(gl_Position.xy, tiles[TILE_INDEX]);
  gl_Position.xy = gl_Position.xy * 2.0 - 1.0;
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif

#ifdef fsh

in vec2 texcoord;

/* RENDERTARGETS: 16 */
layout(location = 0) out vec3 bloomColor;

void main() {
  #if TILE_INDEX == 0
  bloomColor = downSample(colortex0, texcoord, true);
  #else
  bloomColor = downSample(
    colortex16,
    scaleFromBloomTile(texcoord, tiles[TILE_INDEX - 1]),
    true
  );
  #endif
}
#endif
