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
#include "/lib/atmosphere/pulsar.glsl"
#include "/lib/atmosphere/volumetricFog.glsl"

void main() {
  int maxMipLevel = int(floor(log2(max(viewWidth, viewHeight))));
  float averageLuminance = textureLod(colortex0, vec2(0.5), maxMipLevel).a;

  if (gl_FragCoord.xy == vec2(0.5)) {
    if (frameCounter <= 10) {
      averageLuminanceSmooth = averageLuminance;
    }

    averageLuminanceSmooth = averageLuminanceSmooth + (averageLuminance - averageLuminanceSmooth) * (1.0 - exp(-frameTime * EXPOSURE_ADAPTATION));
    

  }

  color = texture(colortex0, texcoord).rgb;

  color += interleavedGradientNoise(floor(gl_FragCoord.xy), 0) / 255;

  #if (defined DEBUG_ENABLE || defined CAMERA_INFO)
  beginText(ivec2(gl_FragCoord.xy / 2.0), ivec2(0, viewHeight / 2.0) + ivec2(8, -8));
  #endif

  #ifdef DEBUG_ENABLE
  if (hideGUI) {
    color = texture(debugtex, texcoord).rgb;
  }
  printString((_D, _e, _b, _u, _g, _space, _m, _o, _d, _e, _space, _i, _s, _space, _a, _c, _t, _i, _v, _e));
  if (!hideGUI) {
    printLine();
    printString((_P, _r, _e, _s, _s, _space, _F, _1, _space, _a, _n, _d, _space, _c, _a, _l, _l, _space, _s, _h, _o, _w, _opprn, _clprn));
  }
  printLine();
  printString((_F, _r, _a, _m, _e, _colon, _space));
  printInt(frameCounter);
  printLine();
  printString((_A, _v, _g, _space, _F, _P, _S, _colon, _space));
  printFloat(frameCounter / frameTimeCounter);

  printLine();
  printLine();
  #endif

  #ifdef CAMERA_INFO
  #ifdef AUTO_EXPOSURE
  float EV100 = autoEV100(averageLuminanceSmooth);
  #else
  float EV100 = manualEV100();
  #endif
  printString((_E, _V, _1, _0, _0, _colon, _space));
  printFloat(EV100);
  printLine();
  printString((_F, _o, _c, _a, _l, _space, _L, _e, _n, _g, _t, _h, _colon, _space));
  printFloat(getFocalLength());
  printString((_m, _m));
  printLine();
  printString((_I, _S, _O, _colon, _space));
  printFloat(ISO);
  printLine();
  printString((_A, _p, _e, _r, _t, _u, _r, _e, _colon, _space, _f, _slash));
  text.fpPrecision = 1;
  printFloat(APERTURE);
  text.fpPrecision = 2;
  printLine();
  printString((_S, _h, _u, _t, _t, _e, _r, _space, _S, _p, _e, _e, _d, _colon, _space, _1, _slash));
  printInt(int(SHUTTER_TIME));
  printString((_s));
  printLine();
  printString((_F, _o, _c, _u, _s, _space, _D, _i, _s, _t, _a, _n, _c, _e, _colon, _space));
  printFloat(-screenSpaceToViewSpace(centerDepthSmooth));
  printString((_m));
  printLine();
  printString((_A, _v, _e, _r, _a, _g, _e, _space, _S, _c, _e, _n, _e, _space, _L, _u, _m, _i, _n, _a, _n, _c, _e, _colon, _space));
  printFloat(averageLuminanceSmooth);
  printString((_c, _d, _slash, _m, _caret, _2));
  
  #endif

  printLine();
  printFloat(cameraPosition.y - VOLUMETRIC_FOG_MIDDLE_PLANE);
  printLine();
  printFloat(getFogDensity(cameraPosition));

  #if (defined DEBUG_ENABLE || defined CAMERA_INFO)
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
