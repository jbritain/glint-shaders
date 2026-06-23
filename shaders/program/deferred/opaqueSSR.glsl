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

#include "/lib/lighting/screenSpaceReflections.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 7 */

layout(location = 0) out vec3 SSRColor;

void main() {
  SSRColor = vec3(0.0);
  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);

  if (depth == 1.0) {
    return;
  }

  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  Material material = unpackMaterial(texture(colortex2, texcoord).rg);

  float averageHitLength;
  SSRColor = getSSR(viewPos, gbuffer, material, colortex13, averageHitLength);
  // averageHitLength *= 1.0 - material.roughness;

  if (
    (material.roughness >= 0.01 && material.roughness < ROUGH_SSR_THRESHOLD)
    #ifdef METAL_REFLECTION_OVERRIDE
     || (ROUGH_SSR_THRESHOLD > 0.0 && material.metalID != NO_METAL)
    #endif
  ) {

    vec3 viewNormal = mat3(gbufferModelView) * gbuffer.surfaceNormal;
    vec3 viewDir = normalize(viewPos);
    vec3 reflectDir = reflect(viewDir, viewNormal);
    vec3 projectedPos = viewPos + viewDir * averageHitLength;
    projectedPos = transformView(projectedPos, gbufferModelViewInverse);
    projectedPos += cameraPosition - previousCameraPosition;
    vec3 projectedViewPos = transformView(
      projectedPos,
      gbufferPreviousModelView
    );
    projectedViewPos -= normalize(projectedViewPos) * averageHitLength;
    projectedPos = viewSpaceToScreenSpace(
      projectedViewPos,
      gbufferPreviousProjection
    );

    vec3 actualProjectedPos = projectedViewPos;
    actualProjectedPos.z = screenSpaceToViewSpace(
      texture(colortex5, projectedPos.xy).a
    );

    if (
      clamp01(projectedPos) == projectedPos &&
      distance(projectedViewPos, actualProjectedPos) < 0.1
    ) {
      vec3 previousSSR = texture(colortex7, projectedPos.xy).rgb;
      SSRColor = mix(SSRColor, previousSSR, 0.6);
    }

  
  }

}

#endif
