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

#include "/lib/material/material.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/screenSpaceReflections.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/water/waveNormals.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"
#include "/lib/atmosphere/volumetricFog.glsl"
#include "/lib/lighting/cloudShadows.glsl"
#include "/lib/util/screenSpaceRayTrace.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

void main() {
  vec3 noise = blueNoise(gl_FragCoord.xy, frameCounter);

  color = texture(colortex0, texcoord);

  bool inWater = isEyeInWater == 1;

  float translucentDepth = texture(depthtex0, texcoord).r;
  vec3 translucentViewPos = screenSpaceToViewSpace(
    vec3(texcoord, translucentDepth)
  );

  vec3 viewDir = normalize(translucentViewPos);
  vec3 translucentFeetPlayerPos = transformView(
    translucentViewPos,
    gbufferModelViewInverse
  );

  float opaqueDepth = texture(depthtex2, texcoord).r;

  #ifdef VOXY
  bool isVoxy = texture(vxDepthTexTrans, texcoord).r != 1.0;

  #else
  bool isVoxy = false;
  #endif

  if (
    translucentDepth == opaqueDepth
    #ifdef VOXY
     &&
    texture(vxDepthTexTrans, texcoord).r ==
      texture(vxDepthTexOpaque, texcoord).r
    #endif
  ) {
    if (inWater) {
      color.rgb = getWaterFog(color.rgb, vec3(0.0), translucentFeetPlayerPos);
    }
    color.rgb = max(vec3(0.0), color.rgb);
    return;
  }

  Material material;
  Gbuffer gbuffer;
  vec4 translucents = texture(colortex6, texcoord);
  #ifdef VOXY

  if(isVoxy){
    opaqueDepth = viewSpaceToScreenSpace(screenSpaceToViewSpace(texture(vxDepthTexOpaque, texcoord).r, vxProjInv));
  }

  if (isVoxy && translucents.a == 0) {
    translucents = texture(colortex29, texcoord);
    material = unpackMaterial(texture(colortex31, texcoord).rg);
    gbuffer = unpackGbuffer(texture(colortex30, texcoord).rgb);

  } else {
    translucents = texture(colortex6, texcoord);
    material = unpackMaterial(texture(colortex2, texcoord).rg);
    gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  }
  #else

  material = unpackMaterial(texture(colortex2, texcoord).rg);
  gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  #endif

  bool isWater = materialIsWater(material.id);
  if (isWater) {
    gbuffer.surfaceNormal = getWaterParallaxNormal(
      translucentFeetPlayerPos,
      gbuffer.geometryNormal,
      noise.r,
      1.0
    );
  }

  vec3 viewGeometryNormal = mat3(gbufferModelView) * gbuffer.geometryNormal;
  vec3 viewSurfaceNormal = mat3(gbufferModelView) * gbuffer.surfaceNormal;

  vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));

  // REFRACTION
  float refractedRayLength = distance(translucentViewPos, opaqueViewPos);
  float sqrf0 = sqrt(material.f0.r);
  float ior = (1.0 + sqrf0) / (1.0 - sqrf0);
  if (!inWater) {
    ior = 1.0 / ior;
  }
  #ifdef REFRACTION_NORMAL_HACK
  vec3 refractionNormal =
    ior < 1.0
      ? viewGeometryNormal - viewSurfaceNormal * 0.7
      : viewSurfaceNormal;
  #else
  vec3 refractionNormal = viewSurfaceNormal;
  #endif

  #ifdef ROUGH_REFRACTION
  if (material.roughness > 0.01) {
    mat3 tbn = generateTBN(refractionNormal);
    vec3 tangentViewDir = normalize(-viewDir * tbn);
    refractionNormal =
      tbn * SampleVNDFGGX(tangentViewDir, vec2(material.roughness), noise.xy);
  }

  #endif
  vec3 refractedDir = refract(viewDir, refractionNormal, ior);

  #ifdef RT_REFRACTION
  vec3 refractedPos;
  if (
    !rayIntersects(
      translucentViewPos,
      refractedDir,
      RT_REFRACTION_STEPS,
      interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter),
      true,
      refractedPos,
      depthtex1,
      0,
      gbufferProjection
    )
  ) {
    refractedPos = vec3(-1.0);
  } else {
    opaqueViewPos = screenSpaceToViewSpace(refractedPos);
  }
  #else
  opaqueViewPos = translucentViewPos + refractedDir * refractedRayLength;
  vec3 refractedPos = viewSpaceToScreenSpace(opaqueViewPos);
  #endif
  float refractedDepth = texture(depthtex1, refractedPos.xy).r;
  if (clamp01(refractedPos) == refractedPos && refractedDepth != 1.0) {
    if (refractedDepth > translucentDepth) {
      color.rgb = texture(colortex0, refractedPos.xy).rgb;
    }
  } else if (inWater || !isWater) {
    vec3 skyDir = mat3(gbufferModelViewInverse) * refractedDir;
    vec3 sky = getSky(skyDir, true);
    vec4 clouds = texture(skyCloudMapTex, encodeUnitVector(skyDir));
    sky = fma(sky, vec3(clouds.a), clouds.rgb);
    // vec4 fog = analyticalFog(translucentFeetPlayerPos, skyDir);
    // sky = fma(sky, vec3(fog.a), fog.rgb);
    color.rgb = sky * gbuffer.lightmap.y;
  }

  vec3 opaqueFeetPlayerPos = transformView(
    opaqueViewPos,
    gbufferModelViewInverse
  );

  #ifdef MULTIPLICATIVE_TRANSLUCENTS
  if (!isWater) {
    color.rgb *= material.albedo;
  }
  #endif

  // TRANSLUCENT BLENDING
  color.rgb = mix(color.rgb, translucents.rgb, translucents.a);

  if (isWater && !inWater) {
    show(-screenSpaceToViewSpace(opaqueDepth) / 100);
    color.rgb = getWaterFog(
      color.rgb,
      translucentFeetPlayerPos,
      opaqueFeetPlayerPos
    );
  }

  // TRANSLUCENT SHADING
  float hitLength;
  vec3 indirectSpecular = getSSR(
    translucentViewPos,
    gbuffer,
    material,
    depthtex0,
    hitLength
  );

  vec3 f = fresnelRoughness(material, dot(-viewDir, viewSurfaceNormal));
  if (refractedDir == vec3(0.0)) {
    f = vec3(1.0);
  }

  // the blend here is incorrectly applying fresnel to the direct diffuse
  // on the surface
  // however, it looks fine, and translucents like this aren't physically accurate anyway
  if (material.roughness <= ROUGH_SSR_THRESHOLD) {
    color.rgb = mix(color.rgb, indirectSpecular, f);
  }
  #ifndef WORLD_THE_NETHER

  float shadow = getShadowFast(
    translucentFeetPlayerPos,
    gbuffer.surfaceNormal,
    gbuffer.lightmap.y
  );
  shadow *= 1.0 - step(0.01, hitLength);

  float cloudShadow = getCloudShadow(translucentFeetPlayerPos);

  vec3 specularHighlight =
    specularBRDF(
      material,
      viewSurfaceNormal,
      viewGeometryNormal,
      translucentViewPos
    ) *
    shadow *
    cloudShadow;
  color.rgb += specularHighlight * sunlightColor;

  #endif

  if (isWater && inWater) {
    color.rgb = getWaterFog(color.rgb, vec3(0.0), translucentFeetPlayerPos);
  }

  color.rgb = max(vec3(0.0), color.rgb);

}

#endif
