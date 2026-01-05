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
#include "/lib/lighting/brdf.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/screenSpaceReflections.glsl"
#include "/lib/lighting/shadows.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

void main() {
  vec4 translucents = texture(colortex6, texcoord);
  color = texture(colortex0, texcoord);
  if (translucents.a == 0.0) {
    return;
  }

  Material material = unpackMaterial(texture(colortex2, texcoord).rg);
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  vec3 viewGeometryNormal = mat3(gbufferModelView) * gbuffer.geometryNormal;
  vec3 viewSurfaceNormal = mat3(gbufferModelView) * gbuffer.surfaceNormal;

  float translucentDepth = texture(depthtex0, texcoord).r;
  vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
  vec3 viewDir = normalize(translucentViewPos);
  vec3 translucentFeetPlayerPos = transformView(translucentViewPos, gbufferModelViewInverse);

  float opaqueDepth = texture(depthtex2, texcoord).r;
  vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
  vec3 opaqueFeetPlayerPos = transformView(opaqueViewPos, gbufferModelViewInverse);

  // REFRACTION
  float refractedRayLength = distance(translucentViewPos, opaqueViewPos);
  float sqrf0 = sqrt(material.f0.r);
  float ior = (1.0 + sqrf0) / (1.0 - sqrf0);
  if(isEyeInWater != 1){
    ior = 1.0 / ior;
  }
  vec3 refractedDir = refract(viewDir, ior < 1.0 ? viewGeometryNormal - viewSurfaceNormal : viewSurfaceNormal, ior);

  vec3 refractedPos = translucentViewPos + refractedDir * refractedRayLength;
  refractedPos = viewSpaceToScreenSpace(refractedPos);
  float refractedDepth = texture(depthtex1, refractedPos.xy).r;
  if(refractedDepth > translucentDepth){
    color.rgb = texture(colortex0, refractedPos.xy).rgb;
  }

  #ifdef MULTIPLICATIVE_TRANSLUCENTS
  color.rgb *= material.albedo;
  #endif
  

  // TRANSLUCENT BLENDING
  color.rgb = mix(color.rgb, translucents.rgb, translucents.a);


  // TRANSLUCENT SHADING
  float hitLength;
  vec3 indirectSpecular = getSSR(translucentViewPos, gbuffer, material, hitLength);

  vec3 f = fresnelRoughness(material, dot(-viewDir, viewSurfaceNormal));
  if(refractedDir == vec3(0.0)){
    f = vec3(1.0);
  }
  if(material.roughness != 0.0){
    f *= smoothstep(ROUGH_SSR_THRESHOLD, ROUGH_SSR_THRESHOLD * 1.2, maxVec3(f));
  }

  // the blend here is incorrectly applying fresnel to the direct diffuse
  // on the surface
  // however, it looks fine, and translucents like this aren't physically accurate anyway
  color.rgb = mix(color.rgb, indirectSpecular, f);
  #ifndef WORLD_THE_NETHER

  float shadow = getShadowFast(translucentFeetPlayerPos, gbuffer.surfaceNormal);
  shadow *= 1.0 - step(0.01, hitLength);

  vec3 specularHighlight = specularBRDF(
    material,
    viewSurfaceNormal,
    viewGeometryNormal,
    translucentViewPos
  ) * shadow;
  color.rgb += specularHighlight;
  #endif

}

#endif
