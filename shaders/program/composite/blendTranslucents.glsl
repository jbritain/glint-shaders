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
#include "/lib/water/waterFog.glsl"
#include "/lib/water/waveNormals.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

void main() {
  vec4 translucents = texture(colortex6, texcoord);
  color = texture(colortex0, texcoord);

  bool inWater = isEyeInWater == 1;

  float translucentDepth = texture(depthtex0, texcoord).r;
  vec3 translucentViewPos = screenSpaceToViewSpace(
    vec3(texcoord, translucentDepth)
  );
  voxyOverride(translucentDepth, translucentViewPos, texcoord, false);
  vec3 viewDir = normalize(translucentViewPos);
  vec3 translucentFeetPlayerPos = transformView(
    translucentViewPos,
    gbufferModelViewInverse
  );


  if (translucents.a == 0.0) {
    if (inWater) {
      color.rgb = getWaterFog(color.rgb, vec3(0.0), translucentFeetPlayerPos);
    }
    return;
  }

  Material material; 
  Gbuffer gbuffer; 

  #ifdef VOXY
  if(!VOXY_MASK){
    material = unpackMaterial(texture(colortex2, texcoord).rg);
    gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);
  } else {
    material = unpackMaterial(texture(colortex17, texcoord).rg);
    gbuffer = unpackGbuffer(texture(colortex16, texcoord).rgb);
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
      interleavedGradientNoise(floor(gl_FragCoord.xy)),
      1.0
    );
  }

  vec3 viewGeometryNormal = mat3(gbufferModelView) * gbuffer.geometryNormal;
  vec3 viewSurfaceNormal = mat3(gbufferModelView) * gbuffer.surfaceNormal;

  float opaqueDepth = texture(depthtex2, texcoord).r;
  vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
  voxyOverride(opaqueDepth, opaqueViewPos, texcoord, true);
  vec3 opaqueFeetPlayerPos = transformView(
    opaqueViewPos,
    gbufferModelViewInverse
  );


  // REFRACTION
  float refractedRayLength = distance(translucentViewPos, opaqueViewPos);
  float sqrf0 = sqrt(material.f0.r);
  float ior = (1.0 + sqrf0) / (1.0 - sqrf0);
  if (!inWater) {
    ior = 1.0 / ior;
  }
  vec3 refractedDir = refract(
    viewDir,
    ior < 1.0
      ? viewGeometryNormal - viewSurfaceNormal
      : viewSurfaceNormal,
    ior
  );

  vec3 refractedPos = translucentViewPos + refractedDir * refractedRayLength;
  refractedPos = viewSpaceToScreenSpace(refractedPos);
  float refractedDepth = texture(depthtex1, refractedPos.xy).r;
  if(clamp01(refractedPos) == refractedPos && refractedDepth != 1.0){
    if (refractedDepth > translucentDepth) {
      color.rgb = texture(colortex0, refractedPos.xy).rgb;
    }
  } else if(inWater) {
    vec3 skyDir = mat3(gbufferModelViewInverse) * refractedDir;
    vec3 sky = getSky(skyDir, true);
    #ifdef CLOUDS
    vec4 clouds = texture(skyCloudMapTex, encodeUnitVector(skyDir));
    sky = fma(sky, vec3(clouds.a), clouds.rgb);
    #endif
    color.rgb = sky * gbuffer.lightmap.y;
  }


  #ifdef MULTIPLICATIVE_TRANSLUCENTS
  if (!isWater) {
    color.rgb *= material.albedo;
  }
  #endif

  // TRANSLUCENT BLENDING
  color.rgb = mix(color.rgb, translucents.rgb, translucents.a);

  if (isWater && !inWater) {
    color.rgb = getWaterFog(color.rgb, translucentFeetPlayerPos, opaqueFeetPlayerPos);
  }

  // TRANSLUCENT SHADING
  float hitLength;
  vec3 indirectSpecular = getSSR(
    translucentViewPos,
    gbuffer,
    material,
    hitLength
  );

  vec3 f = fresnelRoughness(material, dot(-viewDir, viewSurfaceNormal));
  if (refractedDir == vec3(0.0)) {
    f = vec3(1.0);
  }

  // the blend here is incorrectly applying fresnel to the direct diffuse
  // on the surface
  // however, it looks fine, and translucents like this aren't physically accurate anyway
  if(material.roughness <= ROUGH_SSR_THRESHOLD){
    color.rgb = mix(color.rgb, indirectSpecular, f);
  }
  #ifndef WORLD_THE_NETHER

  float shadow = getShadowFast(translucentFeetPlayerPos, gbuffer.surfaceNormal, gbuffer.lightmap.y);
  shadow *= 1.0 - step(0.01, hitLength);

  vec3 specularHighlight =
    specularBRDF(
      material,
      viewSurfaceNormal,
      viewGeometryNormal,
      translucentViewPos
    ) *
    shadow;
  color.rgb += specularHighlight;
  #endif

  if (isWater && inWater) {
    color.rgb = getWaterFog(color.rgb, vec3(0.0), translucentFeetPlayerPos);
  }

  color.rgb = getAtmosphericFog(color.rgb, translucentViewPos);

}

#endif
