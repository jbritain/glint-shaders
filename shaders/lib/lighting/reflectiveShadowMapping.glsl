#ifndef RSM_GLSL
#define RSM_GLSL

#include "/lib/util/dither.glsl"

vec3 getReflectiveShadowMap(vec3 playerPos, vec3 playerNormal) {
  vec3 shadowViewPos = transformView(playerPos, shadowModelView);
  // shadowViewPos.z -= 0.1;

  vec3 shadowViewNormal = mat3(shadowModelView) * playerNormal;
  vec3 shadowScreenPos = viewSpaceToScreenSpaceOrtho(
    shadowViewPos,
    shadowProjection
  );

  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).rg;
  const float radius = RSM_RADIUS / shadowDistance;

  vec3 irradiance = vec3(0.0);

  for (int i = 0; i < RSM_SAMPLES; i++) {
    float angle = fract(float(i) / RSM_SAMPLES + jitter.x) * 2.0 * PI;
    float r = sqrt(float(i + jitter.y) / RSM_SAMPLES);
    vec2 offset = r * radius * vec2(sin(angle), cos(angle));

    vec3 offsetPos = shadowScreenPos + vec3(offset, 0.0);
    vec2 warp = vec2(
      texture(colortex4, vec2(offsetPos.x, 0.0)).r,
      texture(colortex4, vec2(offsetPos.y, 1.0)).r
    );
    vec2 warpedPos = offsetPos.xy + warp;

    offsetPos.z = texture(shadowtex0, warpedPos).r * 2.0;
    vec3 samplePos = screenSpaceToViewSpaceOrtho(
      offsetPos,
      shadowProjectionInverse
    );
    vec3 sampleFlux = texture(shadowcolor0, warpedPos).rgb;
    sampleFlux = pow(sampleFlux, vec3(2.2));
    vec3 sampleNormal = texture(shadowcolor1, warpedPos).rgb * 2.0 - 1.0;
    sampleNormal.z = sqrt(1.0 - dot(sampleNormal.xy, sampleNormal.xy));

    vec3 dir = normalize(shadowViewPos - samplePos); // direction from fragment to sample

    irradiance += sampleFlux * max0(dot(dir, sampleNormal)) * max0(dot(-dir, shadowViewNormal)) / (pow2(distance(samplePos, shadowViewPos) + 1.0));
  }

  irradiance /= float(RSM_SAMPLES);
  irradiance *= PI * pow2(RSM_RADIUS) * RSM_BRIGHTNESS;

  return irradiance;
}

#endif
