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

#include "/lib/atmosphere/volumetricFog.glsl"
#include "/lib/util/misc.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 12 */

layout(location = 0) out vec4 fog;

void main() {
  float depth = texture(depthtex0, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);

  if (isEyeInWater != 0) {
    fog = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // vec4 previousFog = texture(colortex12, texcoord);
  fog = getVolumetricFog(feetPlayerPos, depth);
  fog.rgb /= max(vec3(1.0), sunlightColor);

  // fog = mix(fog, previousFog, 0.7);
  // fog = analyticalFog(vec3(0.0), normalize(feetPlayerPos));

}

#endif
