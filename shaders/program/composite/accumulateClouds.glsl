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
#include "/lib/util/upsample.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 8 */

layout(location = 0) out vec4 clouds;

void main() {
  clouds = vec4(0.0, 0.0, 0.0, 1.0);
  float depth = texture(depthtex0, texcoord).r;

  if (texture(depthtex2, texcoord).r != texture(depthtex1, texcoord).r) {
    return;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  // vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  // vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  // previousPos = viewSpaceToScreenSpace(
  //   previousViewPos,
  //   gbufferPreviousProjection
  // );

  // vec4 previousClouds = texture(colortex8, previousPos.xy);

  // clouds = upsample(colortex14, uvec2(gl_FragCoord.xy), depth, 4);
  // uint frameCount = min(texture(colortex11, texcoord).r, RSM_MAX_FRAMES);
  // clouds = (previousClouds * frameCount + clouds) / (frameCount + 1);

  if (depth == 1.0 || distance(cameraPosition, previousCameraPosition) < 0.01) {
    vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
    previousPos = transformView(previousPos, gbufferPreviousModelView);
    previousPos = viewSpaceToScreenSpace(
      previousPos,
      gbufferPreviousProjection
    );
    vec4 previousClouds = texture(colortex8, previousPos.xy);
    float previousZ = screenSpaceToViewSpace(
      texture(colortex5, previousPos.xy).a
    );
    if (
      saturate(previousPos.xy) == previousPos.xy &&
      abs(viewPos.z - previousZ) < 0.1
    ) {
      clouds = previousClouds;
    } else {
      clouds = texture(colortex14, texcoord);
    }
  }

  if (
    ivec2(floor(vec2(gl_FragCoord.xy) / 4.0) * 4.0) +
      getJitterOffset(4, frameCounter) ==
    ivec2(gl_FragCoord.xy)
  ) {
    clouds = mix(
      clouds,
      texelFetch(colortex14, ivec2(gl_FragCoord.xy) / 4, 0),
      1.0
    );
  }

}

#endif
