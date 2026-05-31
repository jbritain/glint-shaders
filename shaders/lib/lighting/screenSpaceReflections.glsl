/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef SSR_GLSL
#define SSR_GLSL

#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/material/material.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/util/packing.glsl"
#include "/lib/atmosphere/volumetricFog.glsl"

vec3 SSRSample(
  inout vec3 origin,
  vec3 dir,
  vec3 normal,
  float skyLightmap,
  float jitter,
  int samples,
  bool refine,
  sampler2D depthBuffer,
  out float hitLength
) {
  vec3 rayPos;
  vec3 reflectedDir = reflect(dir, normal);

  bool hit = rayIntersects(
    origin,
    reflectedDir,
    samples,
    jitter,
    refine,
    rayPos,
    depthBuffer,
    0,
    gbufferPreviousProjection
  );

  float skyBlendWeight = 1.0;
  vec3 col = vec3(0.0);
  hitLength = 0.0;

  rayPos = screenSpaceToViewSpace(rayPos);
  if (hit) {
    hitLength = distance(rayPos, origin);
    rayPos = transformView(rayPos, gbufferModelViewInverse);
    rayPos += cameraPosition - previousCameraPosition;
    rayPos = transformView(rayPos, gbufferPreviousModelView);
    rayPos = viewSpaceToScreenSpace(rayPos, gbufferPreviousProjection);
    skyBlendWeight = smoothstep(0.9, 1.0, maxVec2(abs(rayPos.xy * 2.0 - 1.0)));
    col = texture(colortex5, rayPos.xy).rgb;

  }

  if (skyBlendWeight > 0.0) {
    vec3 skyDir = mat3(gbufferModelViewInverse) * reflectedDir;
    vec3 sky = getSky(skyDir, false);

    vec4 clouds = texture(skyCloudMapTex, encodeUnitVector(skyDir));
    sky = fma(sky, vec3(clouds.a), clouds.rgb);
    sky *= skyLightmap;

    col = mix(col, sky, skyBlendWeight);

    // vec4 fog = analyticalFog(
    //   transformView(origin, gbufferModelViewInverse),
    //   skyDir
    // );
    // sky = fma(sky, vec3(fog.a), fog.rgb);

  }
  return col;
}

vec3 getSSR(
  vec3 viewPos,
  Gbuffer gbuffer,
  Material material,
  sampler2D depthBuffer,
  out float averageHitLength
) {
  averageHitLength = 0.0;
  vec3 SSRColor = vec3(0.0);
  vec3 viewNormal = mat3(gbufferModelView) * gbuffer.surfaceNormal;
  vec3 viewDir = normalize(viewPos);

  if (material.roughness < 0.01
    #ifdef METAL_REFLECTION_OVERRIDE
     || (ROUGH_SSR_THRESHOLD == 0.0 && (material.metalID != NO_METAL || material.roughness < 0.1))
    #endif
    ) {
    SSRColor = SSRSample(
      viewPos,
      viewDir,
      viewNormal,
      gbuffer.lightmap.y,
      interleavedGradientNoise(floor(gl_FragCoord.xy)),
      SMOOTH_SSR_STEPS,
      true,
      depthBuffer,
      averageHitLength
    );
  } else if (
    material.roughness <= ROUGH_SSR_THRESHOLD
    #ifdef METAL_REFLECTION_OVERRIDE
     || (ROUGH_SSR_THRESHOLD > 0.0 && material.metalID != NO_METAL)
    #endif
  ) {
    mat3 tbn = generateTBN(viewNormal);
    vec3 tangentViewDir = normalize(-viewDir * tbn);
    vec3 f = fresnelRoughness(
      material,
      dot(tangentViewDir, vec3(0.0, 1.0, 0.0))
    );

    for (int i = 0; i < ROUGH_SSR_SAMPLES; i++) {
      vec3 noise = blueNoise(gl_FragCoord.xy, frameCounter, i);
      vec3 roughNormal =
        tbn * SampleVNDFGGX(tangentViewDir, vec2(material.roughness), noise.xy);

      float hitLength;
      SSRColor += SSRSample(
        viewPos,
        viewDir,
        roughNormal,
        gbuffer.lightmap.y,
        noise.z,
        ROUGH_SSR_STEPS,
        false,
        depthBuffer,
        hitLength
      );
      averageHitLength += hitLength;
    }
    SSRColor /= float(ROUGH_SSR_SAMPLES);
    averageHitLength /= float(ROUGH_SSR_SAMPLES);
  }
  return SSRColor;
}

#endif
