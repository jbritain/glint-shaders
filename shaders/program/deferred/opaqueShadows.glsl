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

#include "/lib/material/material.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/subsurfaceScattering.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 10 */

layout(location = 0) out vec4 shadowAndBlockerDistance;

void main() {
  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  voxyOverride(depth, viewPos, texcoord, true);

  Material material = unpackMaterial(texture(colortex2, texcoord).rg);
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);

  float blockerDistance;
  float shadowFade;
  vec3 shadow = getShadow(feetPlayerPos, gbuffer.geometryNormal, material.subsurface, gbuffer.lightmap.y, blockerDistance, shadowFade);

  float occlusion = texture(colortex3, texcoord).r;
  float fakeBlockerDistance = (1.0 - occlusion) * 10.0;
  // show(vec2(blockerDistance, fakeBlockerDistance));
  blockerDistance = mix(blockerDistance, fakeBlockerDistance, shadowFade);

  shadowAndBlockerDistance = vec4(shadow, blockerDistance);

  // if(VOXY_MASK){
  //   shadowAndBlockerDistance.rgb = vec3(getShadowScreenSpace(viewPos, gbuffer.geometryNormal));
  // }

  vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  previousPos = viewSpaceToScreenSpace(
    previousViewPos,
    gbufferPreviousProjection
  );

  vec3 actualPreviousPos = previousViewPos;
  actualPreviousPos.z = texture(colortex5, previousPos.xy).a;

  if (
    clamp01(previousPos) == previousPos &&
    ((distance(actualPreviousPos, previousViewPos) < 0.1))
  ) {
    vec4 previous = texture(colortex10, previousPos.xy);
    shadowAndBlockerDistance.a = mix(shadowAndBlockerDistance.a, previous.a, 0.9);
  }

}

#endif
