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
      sunlightColor;
    diffuse += material.albedo * subsurfaceScattering;

    #ifdef RSM
    diffuse +=
      texture(colortex9, texcoord).rgb * sunlightColor * material.albedo;
    #endif
    #endif

    diffuse += gbuffer.lightmap.y * skylightColor * material.albedo * occlusion;
    diffuse +=
      gbuffer.lightmap.x * blocklightColor * material.albedo * occlusion;
  }
  color.rgb += mix(diffuse, specularc, f * float(material.roughness <= ROUGH_SSR_THRESHOLD));
  
  color.rgb += material.emission * material.albedo * EMISSIVE_STRENGTH;

}

#endif
