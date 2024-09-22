#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  #if TILE_INDEX == 0
  uniform sampler2D colortex0;
  #endif
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
    BloomTile previousTile = tiles[max(0, TILE_INDEX - 1)];

    vec2 tileCoord = scaleToBloomTile(texcoord, tile); // scale up to encompass whole texture
    
    if(clamp01(tileCoord) != tileCoord){
      #if TILE_INDEX == 0
        bloomColor = vec4(0.0); // write black to remove whatever from the buffer
        return;
      #else
        bloomColor = texture(colortex3, texcoord);
        return;
      #endif
    }

    #if TILE_INDEX > 0
      tileCoord = scaleFromBloomTile(tileCoord, previousTile); // scale down to encompass the tile we are downscaling
      bloomColor = vec4(tileCoord / 0.5, 0.0, 1.0);
      bloomColor = vec4(downSample(colortex3, tileCoord, false), 1.0);
    #else
      bloomColor = vec4(downSample(colortex0, tileCoord, true), 1.0);
    #endif



    
  }
#endif