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

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/planarClouds.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/jitter.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 14 */

layout(location = 0) out vec4 clouds;

void main() {
  vec2 texcoord = texcoord + getJitterOffset(4, frameCounter) / resolution;

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

  clouds.rgb = fma(clouds.rgb, vec3(volClouds.a), volClouds.rgb);
  clouds.a *= volClouds.a;
}

#endif
