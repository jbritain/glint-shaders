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

layout(location = 0) out vec3 color;

uniform sampler2D debugtex;

#include "/lib/post/tonemap.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/util/textRenderer.glsl"
#include "/lib/post/camera.glsl"

void main() {
  int maxMipLevel = int(floor(log2(max(viewWidth, viewHeight))));
  float averageLuminance = textureLod(colortex0, vec2(0.5), maxMipLevel).a;

  if (gl_FragCoord.xy == vec2(0.5)) {
    if (frameCounter <= 10) {
      averageLuminanceSmooth = averageLuminance;
    }

    averageLuminanceSmooth = mix(
      averageLuminance,
      averageLuminanceSmooth,
      clamp01(exp2(frameTime * -1))
    );
  }

  color = pow(texture(colortex0, texcoord).rgb, vec3(rcp(2.2)));
  color += interleavedGradientNoise(floor(gl_FragCoord.xy), 0) / 255;

  #ifdef DEBUG_ENABLE
  if (hideGUI) {
    color = texture(debugtex, texcoord).rgb;
  }

  beginText(ivec2(gl_FragCoord.xy / 2.0), ivec2(0, viewHeight / 2.0) + ivec2(8, -8));
  printString((_D, _e, _b, _u, _g, _space, _m, _o, _d, _e, _space, _i, _s, _space, _a, _c, _t, _i, _v, _e));
  printLine();
  printString((_F, _r, _a, _m, _e, _colon, _space));
  printInt(frameCounter);
  printLine();

  if (!hideGUI) {
    printString((_P, _r, _e, _s, _s, _space, _F, _1, _space, _a, _n, _d, _space, _c, _a, _l, _l, _space, _s, _h, _o, _w, _opprn, _clprn));
  }

  endText(color.rgb);
  #endif

  #ifdef DEBUG_RECTILINEAR
  if (gl_FragCoord.x < 256 && gl_FragCoord.y < 256) {
    color = vec3(
      texelFetch(shadowImportanceMapTex, ivec2(gl_FragCoord.xy), 0).r,
      texelFetch(
        shadowtex0,
        ivec2(gl_FragCoord.xy * shadowMapResolution / 256),
        0
      ).r,
      0.0
    );
    // color = vec3(getWarp(gl_FragCoord.xy / 255), 0);
  } else if (gl_FragCoord.x < 266 && gl_FragCoord.y < 256) {
    color = vec3(yWarpMap[int(gl_FragCoord.y)]);
  } else if (gl_FragCoord.y < 266 && gl_FragCoord.x < 256) {
    color = vec3(xWarpMap[int(gl_FragCoord.x)]);
  }
  #endif
}

#endif
