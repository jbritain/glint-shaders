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

#include "/lib/atmosphere/clouds.glsl"
#include "/lib/util/misc.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 8 */

layout(location = 0) out vec4 clouds;

void main() {
  float depth = texture(depthtex0, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);

  clouds = getClouds(feetPlayerPos, depth == 1.0);
  if (depth == 1.0 || distance(cameraPosition, previousCameraPosition) < 0.01) {
    vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
    previousPos = transformView(previousPos, gbufferPreviousModelView);
    previousPos = viewSpaceToScreenSpace(
      previousPos,
      gbufferPreviousProjection
    );

    vec4 previousClouds = catmullRom5(colortex8, previousPos.xy);
    float previousZ = texture(colortex5, previousPos.xy).a;
    float previousDepth = viewSpaceToScreenSpace(
      previousZ,
      gbufferPreviousProjection
    );

    if (saturate(previousPos.xy) == previousPos.xy && previousDepth == 1.0) {
      clouds = mix(previousClouds, clouds, 0.05);
    }
  }
}

#endif
