#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/util/dither.glsl"
#include "/lib/util/rectilinearWarp.glsl"
#include "/lib/util/screenSpaceRayTrace.glsl"

vec3 sampleShadow(vec3 shadowScreenPos) {
  float transparentShadow = texture(shadowtex0HW, shadowScreenPos).r;

  if (transparentShadow >= 1.0 - 1e-6) {
    return vec3(transparentShadow);
  }

  float opaqueShadow = texture(shadowtex1HW, shadowScreenPos).r;

  if (opaqueShadow <= 1e-6) {
    return vec3(opaqueShadow);
  }

  vec4 shadowColorData = texture(shadowcolor0, shadowScreenPos.xy);
  vec3 shadowColor =
    pow(shadowColorData.rgb, vec3(2.2)) * (1.0 - shadowColorData.a);
  return mix(shadowColor * opaqueShadow, vec3(1.0), transparentShadow);
}

vec3 sampleShadowPCF(
  vec3 shadowScreenPos,
  float radius,
  float jitter,
  vec3 shadowViewNormal
) {
  vec3 shadow = vec3(0.0);

  for (int i = 0; i < SHADOW_PCF_SAMPLES; i++) {
    vec2 offset = vogelDisc(i, SHADOW_PCF_SAMPLES, jitter) * radius;

    vec3 offsetPos = shadowScreenPos + vec3(offset, 0.0);
    offsetPos.xy += getWarp(offsetPos.xy);
    shadow += sampleShadow(offsetPos);
  }
  return shadow / SHADOW_PCF_SAMPLES;
}

float getBlockerDistance(
  vec3 shadowScreenPos,
  float jitter,
  vec3 shadowViewNormal
) {
  float blockerDistanceSum = 0.0;
  uint blockerCount = 0;
  for (int i = 0; i < PCSS_SEARCH_SAMPLES; i++) {
    vec2 offset =
      vogelDisc(i, PCSS_SEARCH_SAMPLES, jitter) *
      PCSS_SEARCH_RADIUS /
      shadowDistance;

    vec3 offsetPos = shadowScreenPos + vec3(offset, 0.0);

    offsetPos.xy += getWarp(offsetPos.xy);
    float blockerDistance = max(
      0.0,
      offsetPos.z - texture(shadowtex0, offsetPos.xy).r
    );

    blockerDistanceSum += blockerDistance;
    if (blockerDistance > 0.0) {
      blockerCount++;
    }
  }
  if (blockerCount > 0) {
    return blockerDistanceSum / float(blockerCount);
  } else {
    return 0.0;
  }
}

float getShadowScreenSpace(vec3 viewPos, vec3 playerNormal) {
  vec3 p;
  return rayIntersects(
    viewPos,
    lightDir,
    SCREEN_SPACE_SHADOW_STEPS,
    blueNoise(gl_FragCoord.xy, frameCounter).r,
    false,
    p,
    depthtex0,
    gbufferProjection
  )
    ? 0.0
    : 1.0;
}

vec3 getShadow(
  vec3 playerPos,
  vec3 playerNormal,
  float subsurface,
  float skyLightmap,
  out float blockerDistance,
  out float distFade
) {
  blockerDistance = 100.0;
  float jitter = blueNoise(gl_FragCoord.xy, frameCounter).r;
  vec3 shadowViewPos = transformView(playerPos, shadowModelView);

  vec3 shadowViewNormal = mat3(shadowModelView) * playerNormal;
  shadowViewPos +=
    shadowViewNormal *
    (0.1 + step(0.5, length(playerPos) / shadowDistance) * 0.2) *
    sqrt(1.0 - pow2(dot(playerNormal, worldLightDir)));

  vec3 shadowScreenPos = viewSpaceToScreenSpaceOrtho(
    shadowViewPos,
    shadowProjection
  );
  shadowScreenPos.z /= SHADOW_Z_STRETCH;
  distFade = smoothstep(0.5, 0.9, maxVec2(abs(shadowScreenPos.xy * 2.0 - 1.0)));

  // vec3 screenSpaceShadow = vec3(1.0);
  // if (distFade > 0.01) {
  //   screenSpaceShadow = vec3(
  //     getShadowScreenSpace(
  //       transformView(playerPos, gbufferModelView),
  //       playerNormal
  //     )
  //   );
  // }

  vec3 shadow = vec3(1.0);
  if (distFade < 1.0) {
    blockerDistance = getBlockerDistance(
      shadowScreenPos,
      jitter,
      shadowViewNormal
    );

    float radius = mix(
      PCSS_MIN_RADIUS / shadowDistance,
      PCSS_MAX_RADIUS / shadowDistance,
      blockerDistance
    );

    shadow = sampleShadowPCF(shadowScreenPos, radius, jitter, shadowViewNormal);
  }

  shadow = mix(
    shadow,
    vec3(smoothstep(13.5 / 15, 14.5 / 15, skyLightmap)),
    distFade
  );

  return shadow;
}

float getShadowFast(vec3 playerPos, vec3 playerNormal, float skyLightmap) {
  vec3 shadowViewPos = transformView(playerPos, shadowModelView);

  vec3 shadowViewNormal = mat3(shadowModelView) * playerNormal;
  shadowViewPos +=
    shadowViewNormal * 0.3 * sqrt(1.0 - pow2(dot(playerNormal, worldLightDir)));

  vec3 shadowScreenPos = viewSpaceToScreenSpaceOrtho(
    shadowViewPos,
    shadowProjection
  );
  shadowScreenPos.z /= SHADOW_Z_STRETCH;

  shadowScreenPos.xy += getWarp(shadowScreenPos.xy);

  float shadow = texture(shadowtex0HW, shadowScreenPos).r;

  float distFade = smoothstep(
    0.5,
    0.9,
    maxVec2(abs(shadowScreenPos.xy * 2.0 - 1.0))
  );
  shadow = mix(
    shadow,
    smoothstep(13.5 / 15.0, 14.5 / 15.0, skyLightmap),
    distFade
  );

  return shadow;
}

#endif
