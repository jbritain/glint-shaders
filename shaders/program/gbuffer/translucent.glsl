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
in vec2 mc_Entity;
in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 lightmap;
out vec2 texcoord;
out vec4 glcolor;
out mat3 tbn;
out vec3 viewPos;
flat out uint materialID;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

  vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  lightmap = lmcoord / (30.0 / 32.0) - 1.0 / 32.0;

  tbn[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
  tbn[2] = normalize(gl_NormalMatrix * gl_Normal);
  tbn[1] = normalize(cross(tbn[0], tbn[2]) * at_tangent.w);

  viewPos = (gbufferProjectionInverse * gl_Position).xyz;

  glcolor = gl_Color;

  materialID = uint(mc_Entity.x);
}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/cloudShadows.glsl"

in vec2 lightmap;
in vec2 texcoord;
in vec4 glcolor;
in mat3 tbn;
in vec3 viewPos;

flat in uint materialID;

/* RENDERTARGETS: 6,1,2 */

layout(location = 0) out vec4 color;
layout(location = 1) out uvec3 gbufferData;
layout(location = 2) out uvec2 materialData;

void main() {
  Gbuffer gbuffer;

  gbuffer.geometryNormal = mat3(gbufferModelViewInverse) * tbn[2];
  vec3 surfaceNormal = getSurfaceNormal(texcoord, tbn);
  gbuffer.surfaceNormal = mat3(gbufferModelViewInverse) * surfaceNormal;
  gbuffer.lightmap = applyLightmapFalloff(lightmap);

  color = texture(gtexture, texcoord);
  color.rgb *= glcolor.rgb;

  if (color.a < alphaTestRef) {
    discard;
  }

  Material material = materialFromSpecularMap(
    pow(color.rgb, vec3(2.2)),
    texture(specular, texcoord),
    materialID
  );

  if (materialIsWater(materialID)) {
    material.roughness = 0.0;
    material.f0 = vec3(0.02);
    material.albedo = vec3(0.0);
    color.a = 0.01;
  }

  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  float shadow = getShadowFast(
    feetPlayerPos,
    gbuffer.surfaceNormal,
    gbuffer.lightmap.y
  );
  float cloudShadow = getCloudShadow(feetPlayerPos);
  color.rgb = vec3(0.0);
  #ifndef WORLD_THE_NETHER
  color.rgb =
    diffuseBRDF(material, surfaceNormal, tbn[2], viewPos) *
    sunlightColor *
    shadow *
    cloudShadow;
  #endif

  color.rgb +=
    gbuffer.lightmap.y *
    skylightColor *
    material.albedo *
    (1.0 + (1.0 - cloudShadow));
  color.rgb += gbuffer.lightmap.x * blocklightColor * material.albedo;
  color.rgb += material.albedo * material.emission * EMISSIVE_STRENGTH;

  gbufferData = packGbuffer(gbuffer);
  materialData = packMaterial(material);
}

#endif
