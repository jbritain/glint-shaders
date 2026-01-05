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
  color = mix(color, bloom, 0.001);

  color /= 15;
  color = tonemap(color);
  color += interleavedGradientNoise(floor(gl_FragCoord.xy), 0) / 255;

  #ifdef DEBUG_ENABLE
  if (hideGUI) {
    color = texture(debugtex, texcoord).rgb;
  }
  #endif

  if(gl_FragCoord.x < 256 && gl_FragCoord.y < 256){
    color = vec3(
      texelFetch(shadowImportanceMapTex, ivec2(gl_FragCoord.xy), 0).r,
      texelFetch(shadowtex0, ivec2(gl_FragCoord.xy * shadowMapResolution / 256), 0).r,
      0.0
      );
  } else if(gl_FragCoord.x < 266 && gl_FragCoord.y < 256) {
    color = texelFetch(colortex4, ivec2(gl_FragCoord.y, 1), 0).rgb;
  } else if(gl_FragCoord.y < 266 && gl_FragCoord.x < 256){
    color = texelFetch(colortex4, ivec2(gl_FragCoord.x, 0), 0).rgb;
  }
}

#endif
