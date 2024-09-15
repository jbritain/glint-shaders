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

  #include "/lib/postProcessing/bloom.glsl"
  #include "/lib/util.glsl"



  /* DRAWBUFFERS:3 */
  layout(location = 0) out vec4 bloomColor;

  void main() {
    BloomTile tile = tiles[TILE_INDEX];
    BloomTile nextTile = tiles[TILE_INDEX - 1];

    bloomColor = texture(colortex3, texcoord);

    vec2 tileCoord = scaleToBloomTile(texcoord, nextTile);

    if(clamp01(tileCoord) != tileCoord){
      return;
    }

    tileCoord = scaleFromBloomTile(tileCoord, tile);
    // bloomColor.rgb = vec3(tileCoord.xy, 0.0);
    bloomColor.rgb += upSample(colortex3, tileCoord);    
  }
#endif