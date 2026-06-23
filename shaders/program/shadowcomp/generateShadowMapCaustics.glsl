/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

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

#include "/lib/water/waveNormals.glsl"

/* RENDERTARGETS: 2 */
layout(location = 0) out vec2 caustics;

void main() {
  vec3 originalPosAndCaustics = texture(shadowcolor2, texcoord).xyz;
  vec2 trueCoord = originalPosAndCaustics.yz * 2.0 - 1.0;

  // check if any surrounding texels have water to decide whether we generate caustics
  const int radius = 5;
  bool doCaustics = false;
  for (int x = -radius; x < radius; x++) {
    for (int y = -radius; y < radius; y++) {
      if (
        texelFetch(shadowcolor2, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).x >
        0.5
      ) {
        doCaustics = true;
        break;
      }
    }
  }

  // if (!doCaustics) {
  //   return;
  // }

  float opaqueDepth = texture(shadowtex1, texcoord).r;
  float translucentDepth = texture(shadowtex0, texcoord).r;

  vec3 translucentShadowViewPos = screenSpaceToViewSpaceOrtho(
    vec3(trueCoord, translucentDepth),
    shadowProjectionInverse
  );

  float blockerDistance = (opaqueDepth - translucentDepth) * shadowRange;
  vec3 feetPlayerPos = transformView(
    translucentShadowViewPos,
    shadowModelViewInverse
  );

  vec3 normal = waveNormal(
    feetPlayerPos.xz + cameraPosition.xz,
    vec3(0.0, 1.0, 0.0),
    1.0
  );

  caustics.x = originalPosAndCaustics.x;
  vec3 halfwayVector = normalize(vec3(0.0, 1.0, 0.0) + worldLightDir);
  caustics.y = pow(dot(normal, halfwayVector), 32);

}

#endif
