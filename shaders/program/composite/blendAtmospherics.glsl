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

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

#include "/lib/atmosphere/volumetricClouds.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"
#include "/lib/util/upsample.glsl"

void main() {
  color = texture(colortex0, texcoord);
  float depth = texture(depthtex0, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

  // EXPLANATION:
  // fog should always be blended after translucents (no fog behind glass, cry about it)
  // which means that it should only be blended in the program where blend_before_translucents is true
  // we then hijack the check for if the player is in the clouds
  // because that decides whether we blend fog or the clouds first

  #ifdef VOLUMETRIC_FOG
  vec4 fog = upsample(colortex12, uvec2(gl_FragCoord.xy), depth, 2);
  fog.rgb *= max(vec3(1.0), sunlightColor);
  #else
  vec4 fog = vec4(0.0, 0.0, 0.0, 1.0);
  #endif

  bool blend;
  #ifdef BLEND_BEFORE_TRANSLUCENTS
  blend = cameraPosition.y < VOLUMETRIC_CLOUDS_BASE_ALTITUDE;
  #else
  blend = cameraPosition.y >= VOLUMETRIC_CLOUDS_BASE_ALTITUDE;

  if (!blend) {
    if (depth != 1.0) {
      color.rgb = getAtmosphericFog(color.rgb, viewPos);
    }
    color.rgb = fma(color.rgb, vec3(fog.a), fog.rgb);

  }
  #endif

  if (blend) {
    #if defined VOLUMETRIC_CLOUDS || defined PLANAR_CLOUDS
    vec4 clouds = texture(colortex8, texcoord);
    clouds.rgb *= max(vec3(1.0), sunlightColor);

    color.rgb = fma(color.rgb, vec3(clouds.a), clouds.rgb);
    #endif
    #ifndef BLEND_BEFORE_TRANSLUCENTS
    if (depth != 1.0) {
      color.rgb = getAtmosphericFog(color.rgb, viewPos);
    }
    color.rgb = fma(color.rgb, vec3(fog.a), fog.rgb);

    #endif
  }

}

#endif
