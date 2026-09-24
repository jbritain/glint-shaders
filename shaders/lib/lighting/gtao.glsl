#ifndef GTAO_GLSL
#define GTAO_GLSL

#include "/lib/util/packing.glsl"
#include "/lib/util/dither.glsl"

vec3 getViewPos(vec2 coord) {
  float depth = texture(depthtex0, coord).r;
  vec3 screenPos = vec3(coord, depth);
  return screenSpaceToViewSpace(screenPos);
}

#define GTAO_SLICE_COUNT AO_SAMPLES

float getHorizonAngle(
  vec2 coord,
  vec3 viewPos,
  vec3 viewDir,
  vec2 dir,
  float radius,
  float jitter
) {
  float maxCosHorizonAngle = -1.0;
  vec2 rayStep = normalize(dir) * radius / GTAO_DIRECTION_SAMPLE_COUNT;
  coord += rayStep * jitter;
  for (int i = 0; i < GTAO_DIRECTION_SAMPLE_COUNT; i++) {
    coord += rayStep;
    vec3 samplePos = getViewPos(coord);
    vec3 sampleVec = samplePos - viewPos;
    float cosTheta = mix(
      dot(sampleVec, viewDir) / length(sampleVec),
      -1.0,
      linearstep(0.75 * AO_RADIUS, AO_RADIUS, length(sampleVec))
    );
    maxCosHorizonAngle = max(maxCosHorizonAngle, cosTheta);

  }

  return acos(maxCosHorizonAngle);
}

vec4 getGTAO(vec3 viewPos, vec3 normal, vec2 coord) {
  float visibility = 0.0;
  vec3 viewDir = -normalize(viewPos);
  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).xy;

  float depthScale = gbufferProjection[1][1] / -viewPos.z;

  for (int i = 0; i < AO_SAMPLES; i++) {
    float sliceAngle = (float(i) + jitter.x) / float(AO_SAMPLES) * 2.0 * PI;
    vec3 sliceDir = vec3(sin(sliceAngle), cos(sliceAngle), 0.0);

    vec3 tangent = sliceDir - dot(sliceDir, viewDir) * viewDir;
    vec3 axis = cross(sliceDir, viewDir);
    vec3 projNormal = normal - axis * dot(normal, axis);

    float cosY = clamp01(
      dot(viewDir, projNormal) * inversesqrt(dot(projNormal, projNormal))
    );
    float y = sign(dot(tangent, projNormal)) * acos(cosY);
    float sinY = sin(y);

    vec2 thetas = vec2(
      -getHorizonAngle(
        coord,
        viewPos,
        viewDir,
        -sliceDir.xy,
        depthScale * AO_RADIUS * 0.1,
        jitter.y
      ),
      getHorizonAngle(
        coord,
        viewPos,
        viewDir,
        sliceDir.xy,
        depthScale * AO_RADIUS * 0.1,
        jitter.y
      )
    );

    thetas = y + clamp(thetas - y, -PI / 2, PI / 2);
    visibility += dot(
      vec2(0.25),
      cosY + 2.0 * thetas * sinY - cos(2.0 * thetas - y)
    );
  }

  visibility /= AO_SAMPLES * 2;

  show(visibility);
  return vec4(vec3(0.0), visibility);
}

// vec4 getGTAO(vec3 cPosV, vec3 normalV, vec2 cTexCoord) {
//   float visibility = 0.0;

//   float scaling = gbufferProjection[1][1] / -cPosV.z;

//   vec3 viewV = -normalize(cPosV);

//   vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).xy;

//   for (int slice = 0; slice < GTAO_SLICE_COUNT; slice++) {
//     float phi = PI / GTAO_SLICE_COUNT * (float(slice) + jitter.x);

//     vec2 omega = vec2(cos(phi), sin(phi));

//     vec3 directionV = vec3(omega.x, omega.y, 0); // direction of the slice in view space
//     vec3 axisV = cross(directionV, viewV);

//     // in the paper this is directionV − dot(directionV, viewV) ∗ viewV)
//     // this seems to be incorrect
//     // vec3 orthoDirectionV = directionV - dot(directionV, viewV) * viewV;
//     vec3 orthoDirectionV = cross(directionV, axisV);
//     vec3 projNormalV = normalV - axisV * dot(normalV, axisV);

//     float sgnN = sign(dot(orthoDirectionV, projNormalV));
//     float cosN = clamp01(dot(projNormalV, viewV) / length(projNormalV));
//     float n = sgnN * acos(cosN);

//     vec2 h;

//     for (int side = 0; side < 1; side++) {
//       float cHorizonCos = -1;
//       for (
//         int samp = 0;
//         samp < GTAO_DIRECTION_SAMPLE_COUNT && cHorizonCos < 0.95;
//         samp++
//       ) {
//         float s = (float(samp) + jitter.y) / float(GTAO_DIRECTION_SAMPLE_COUNT);
//         vec2 sTexCoord =
//           cTexCoord + (-1 + 2 * side) * s * vec2(omega.x, -omega.y) * scaling;
//         vec3 sPosV = getViewPos(sTexCoord);
//         vec3 sHorizonV = normalize(sPosV - cPosV);
//         cHorizonCos = max(cHorizonCos, dot(sHorizonV, viewV));
//       }

//       h[side] =
//         n + clamp((-1 + 2 * side) * acos(cHorizonCos) - n, -PI / 2, PI / 2);
//       visibility +=
//         length(projNormalV) *
//         (cosN + 2 * h[side] * sin(n) - cos(2 * h[side] - n)) /
//         4.0;
//     }
//   }

//   visibility /= float(GTAO_SLICE_COUNT);
//   show(visibility);

//   return vec4(vec3(0.0), visibility);
// }

#endif
