/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/bloomUpsample.glsl
    - Bloom upsampling

    **THIS PROGRAM RUNS MULTIPLE TIMES**
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex3;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  #include "/lib/post/bloom.glsl"
  #include "/lib/util.glsl"



  /* DRAWBUFFERS:3 */
  layout(location = 0) out vec4 bloomColor;

  void main() {
    BloomTile tile = tiles[TILE_INDEX];
    #if TILE_INDEX > 0
    BloomTile nextTile = tiles[max(0, TILE_INDEX - 1)];
    vec2 tileCoord = scaleToBloomTile(texcoord, nextTile);

    bloomColor = texture(colortex3, texcoord);

    if(clamp01(tileCoord) != tileCoord){
      return;
    }

    tileCoord = scaleFromBloomTile(tileCoord, tile);
    // bloomColor.rgb = vec3(tileCoord.xy, 0.0);
    #else
    vec2 tileCoord = texcoord / 2;
    #endif
    bloomColor.rgb += upSample(colortex3, tileCoord);  
  }
#endif