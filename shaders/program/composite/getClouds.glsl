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

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/planarClouds.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/jitter.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 14 */

layout(location = 0) out vec4 clouds;

void main() {
  ;
  ivec2 fullResPixel =
    ivec2(gl_FragCoord.xy) * 4 + getJitterOffset(4, frameCounter);
  vec2 texcoord = (vec2(fullResPixel) + 0.5) / resolution;

  clouds = vec4(0.0, 0.0, 0.0, 1.0);
  float depth = texelFetch(depthtex0, ivec2(texcoord * resolution), 0).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);

  vec4 planarClouds = getPlanarClouds(normalize(feetPlayerPos));
  vec4 volClouds = getVolumetricClouds(feetPlayerPos, depth == 1.0);

  if (depth == 1.0) {
    clouds = planarClouds;
  }

  clouds.rgb *= volClouds.a;
  clouds.rgb += volClouds.rgb;
  clouds.a *= volClouds.a;

  // clouds.rgb = fma(clouds.rgb, vec3(volClouds.a), volClouds.rgb);
  // clouds.a *= volClouds.a;

  clouds.rgb /= max(vec3(1.0), sunlightColor);
}

#endif
