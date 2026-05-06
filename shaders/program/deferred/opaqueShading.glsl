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
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/subsurfaceScattering.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"
#include "/lib/lighting/cloudShadows.glsl"
#include "/lib/misc/voxel.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

void main() {
  float depth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  voxyOverride(depth, viewPos, texcoord, true);

  if (depth == 1.0) {
    color.rgb = getSky(
      mat3(gbufferModelViewInverse) * normalize(viewPos),
      true
    );
    return;
  }

  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);

  Material material = unpackMaterial(texture(colortex2, texcoord).rg);
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);

  color.rgb = vec3(0.0);
  #ifndef WORLD_THE_NETHER
  vec4 shadowAndBlockerDistance = texture(colortex10, texcoord);
  float blockerDistance = shadowAndBlockerDistance.a;
  vec3 shadow = shadowAndBlockerDistance.rgb;

  float cloudShadow = getCloudShadow(feetPlayerPos);
  gbuffer.lightmap.y *= 1.0 + (1.0 - cloudShadow); // boost skylight in cloud shadow
  shadow *= cloudShadow;

  color.rgb =
    brdf(
      material,
      mat3(gbufferModelView) * gbuffer.surfaceNormal,
      mat3(gbufferModelView) * gbuffer.geometryNormal,
      viewPos
    ) *
    sunlightColor *
    shadow;
  #endif

  float occlusion = texture(colortex3, texcoord).r;

  vec3 specularc = texture(colortex7, texcoord).rgb;
  vec3 f = fresnelRoughness(
    material,
    dot(gbuffer.geometryNormal, -normalize(feetPlayerPos))
  );

  vec3 diffuse = vec3(0.0);
  if (material.metalID == NO_METAL) {
    #ifndef WORLD_THE_NETHER
    vec3 subsurfaceScattering =
      getSubsurfaceScattering(
        material.albedo,
        material.subsurface,
        blockerDistance,
        length(shadow),
        normalize(feetPlayerPos),
        gbuffer.geometryNormal
      ) *
      sunlightColor *
      cloudShadow;
    diffuse += subsurfaceScattering;

    #ifdef PHOTONICS
    diffuse += texture(indirectRadiosityTex, texcoord).rgb * occlusion;
    #else
    #ifdef RSM
    diffuse += texture(colortex9, texcoord).rgb * sunlightColor * cloudShadow;
    #endif
    #endif
    #endif

    #ifdef PHOTONICS
    vec4 radiosity = texture(radiosity_direct_soft, texcoord);
    diffuse += radiosity.rgb / max(1.0, radiosity.a);
    diffuse += texture(radiosity_direct, texcoord).rgb;
    #else
    diffuse += gbuffer.lightmap.y * weatherSkylightColor * occlusion;

    #ifdef FLOODFILL
    diffuse +=
      sampleFloodfill(
        feetPlayerPos,
        gbuffer.geometryNormal,
        gbuffer.surfaceNormal,
        material.subsurface
      ) *
      EMISSIVE_STRENGTH /
      16;
    #else
    diffuse += gbuffer.lightmap.x * blocklightColor * occlusion;
    #endif
    #endif

    // diffuse += vec3(AMBIENT_LIGHT_STRENGTH) * occlusion;
    #ifdef WORLD_THE_NETHER
    diffuse += vec3(NETHER_AMBIENT_LIGHT_BOOST) * occlusion;
    #endif
  }
  color.rgb += mix(
    diffuse * material.albedo,
    specularc,
    f * float(material.roughness <= ROUGH_SSR_THRESHOLD)
  );

  color.rgb += material.emission * material.albedo * EMISSIVE_STRENGTH;
}

#endif
