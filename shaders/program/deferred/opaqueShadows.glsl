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

#include "/lib/material/material.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/subsurfaceScattering.glsl"
#include "/lib/lighting/cloudShadows.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 10 */

layout(location = 0) out vec4 shadowAndBlockerDistance;

void main() {
  float depth = texture(depthtex1, texcoord).r;
  if (depth == 1.0) {
    return;
  }
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  voxyOverride(depth, viewPos, texcoord, true);

  Material material = unpackMaterial(texture(colortex2, texcoord).rg);
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);

  #ifdef VOXY
  bool isVoxy = texture(vxDepthTexOpaque, texcoord).r != 1.0;
  #else
  bool isVoxy = false;
  #endif

  float blockerDistance;
  float shadowFade;
  vec3 shadow;
  if (!isVoxy) {
    shadow = getShadow(
      feetPlayerPos,
      gbuffer.geometryNormal,
      material.subsurface,
      gbuffer.lightmap.y,
      blockerDistance,
      shadowFade
    );

    if (shadowFade > 0.01) {
      float occlusion = texture(colortex3, texcoord).r;
      float fakeBlockerDistance = 10.0; //pow2(1.0 - occlusion) * 10.0; // todo: good subsurface scattering heuristic for distant terrain
      blockerDistance = mix(blockerDistance, fakeBlockerDistance, shadowFade);

      vec3 p;
      float screenSpaceShadow = rayIntersects(
        viewPos,
        lightDir,
        8,
        bayer64(gl_FragCoord.xy),
        false,
        p,
        depthtex0,
        0,
        gbufferProjection
      )
        ? 0.0
        : 1.0;
      shadow = mix(shadow, vec3(screenSpaceShadow), shadowFade);
    }

  } else {
    #ifdef VOXY
    vec3 p;
    shadow = rayIntersects(
      viewPos,
      lightDir,
      8,
      bayer64(gl_FragCoord.xy),
      false,
      p,
      vxDepthTexTrans,
      0,
      vxProj
    )
      ? vec3(0.0)
      : vec3(1.0);
    #endif
    blockerDistance = 10.0;
  }

  shadowAndBlockerDistance = vec4(shadow, blockerDistance);

  vec3 previousPos = feetPlayerPos + cameraPosition - previousCameraPosition;
  vec3 previousViewPos = transformView(previousPos, gbufferPreviousModelView);
  previousPos = viewSpaceToScreenSpace(
    previousViewPos,
    gbufferPreviousProjection
  );

  vec3 actualPreviousPos = previousViewPos;
  actualPreviousPos.z = screenSpaceToViewSpace(
    texture(colortex5, previousPos.xy).a
  );

  if (
    clamp01(previousPos) == previousPos &&
    distance(actualPreviousPos, previousViewPos) < 0.1
  ) {
    vec4 previous = texture(colortex10, previousPos.xy);
    shadowAndBlockerDistance.a = mix(
      shadowAndBlockerDistance.a,
      previous.a,
      0.9
    );
  }

}

#endif
