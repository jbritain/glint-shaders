#ifndef GTAO_GLSL
#define GTAO_GLSL

#include "/lib/util/packing.glsl"

// GTAO BY CYBEREALITY
// https://cybereality.com/screen-space-indirect-lighting-with-visibility-bitmask-improvement-to-gtao-ssao-real-time-ambient-occlusion-algorithm-glsl-shader-implementation/

// https://cdrinmatane.github.io/posts/ssaovb-code/
const uint sectorCount = 32u;
uint updateSectors(float minHorizon, float maxHorizon, uint outBitfield) {
  uint startBit = uint(minHorizon * float(sectorCount));
  uint horizonAngle = uint(
    ceil((maxHorizon - minHorizon) * float(sectorCount))
  );
  uint angleBit =
    horizonAngle > 0u
      ? uint(0xFFFFFFFFu >> sectorCount - horizonAngle)
      : 0u;
  uint currentBitfield = angleBit << startBit;
  return outBitfield | currentBitfield;
}

vec2 screenSize = vec2(viewWidth, viewHeight);
const float twoPi = 2.0 * PI;
const float halfPi = PI / 2.0;

vec3 getNormal(vec2 coord) {
  uint encoded = texture(colortex1, coord).g;
  vec2 packedGeometry;
  packedGeometry.r = float(bitfieldExtract(encoded, 0, 8)) / 255.0;
  packedGeometry.g = float(bitfieldExtract(encoded, 8, 8)) / 255.0;
  return decodeUnitVector(packedGeometry);
}

float getGTAO(vec3 position, vec3 normal, vec2 fragUV) {
  uint indirect = 0u;
  uint occlusion = 0u;

  float visibility = 0.0;
  vec3 lighting = vec3(0.0);
  vec2 frontBackHorizon = vec2(0.0);
  vec2 aspect = screenSize.yx / screenSize.x;
  vec3 camera = normalize(-position);

  float sliceRotation = twoPi / (AO_SAMPLES - 1.0);
  float sampleScale = -AO_RADIUS * gbufferProjection[0][0] / position.z;
  float sampleOffset = 0.01;
  vec2 jitter = blueNoise(floor(gl_FragCoord.xy), frameCounter).rg;

  for (float slice = 0.0; slice < AO_SAMPLES + 0.5; slice += 1.0) {
    float phi = sliceRotation * (slice + jitter.r) + PI;
    vec2 omega = vec2(cos(phi), sin(phi));
    vec3 direction = vec3(omega.x, omega.y, 0.0);
    vec3 orthoDirection = direction - dot(direction, camera) * camera;
    vec3 axis = cross(direction, camera);
    vec3 projNormal = normal - axis * dot(normal, axis);
    float projLength = length(projNormal);

    float signN = sign(dot(orthoDirection, projNormal));
    float cosN = clamp(dot(projNormal, camera) / projLength, 0.0, 1.0);
    float n = signN * acos(cosN);

    for (
      float currentSample = 0.0;
      currentSample < GTAO_DIRECTION_SAMPLE_COUNT + 0.5;
      currentSample += 1.0
    ) {
      float sampleStep =
        (currentSample + jitter.g) / GTAO_DIRECTION_SAMPLE_COUNT + sampleOffset;
      vec2 sampleUV = fragUV - sampleStep * sampleScale * omega * aspect;
      vec3 samplePosition = screenSpaceToViewSpace(
        vec3(sampleUV, texture(depthtex0, sampleUV).r)
      );
      vec3 sampleNormal = getNormal(sampleUV);
      vec3 sampleLight = texture(colortex6, sampleUV).rgb;
      vec3 sampleDistance = samplePosition - position;
      float sampleLength = length(sampleDistance);
      vec3 sampleHorizon = sampleDistance / sampleLength;

      frontBackHorizon.x = dot(sampleHorizon, camera);
      frontBackHorizon.y = dot(
        normalize(sampleDistance - camera * GTAO_THICKNESS),
        camera
      );

      frontBackHorizon = acos(frontBackHorizon);
      frontBackHorizon = clamp((frontBackHorizon + n + halfPi) / PI, 0.0, 1.0);

      indirect = updateSectors(frontBackHorizon.x, frontBackHorizon.y, 0u);
      // lighting +=
      //   (1.0 - float(bitCount(indirect & ~occlusion)) / float(sectorCount)) *
      //   sampleLight *
      //   clamp(dot(normal, sampleHorizon), 0.0, 1.0) *
      //   clamp(dot(sampleNormal, -sampleHorizon), 0.0, 1.0);
      occlusion |= indirect;
    }
    visibility += 1.0 - float(bitCount(occlusion)) / float(sectorCount);
  }

  visibility /= AO_SAMPLES;

  return visibility;
}

#endif
