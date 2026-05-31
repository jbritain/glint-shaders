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

in vec2 texcoord;

/* RENDERTARGETS: 0 */

#include "/lib/post/camera.glsl"
#include "/lib/util/dither.glsl"

layout(location = 0) out vec3 color;

// TODO: since DoF is applied before temporal filtering, screen space reflections etc reflect the DoF
// TODO: cleanly handle issues with foreground and background separation

float getSampleWeight(float sampleCoC, float CoC, float radius) {
  return abs(sampleCoC / 2) >= radius && sign(sampleCoC) <= sign(CoC)
    ? sign(CoC) < 1
      ? 2.0
      : 1.0
    : 0.0;
}

const float GOLDEN_ANGLE = 2.39996323;

void main() {
  float CoC = texture(colortex6, texcoord).r;

  float weight = 1.0 / (PI * pow2(CoC / 2) + 1.0);
  color = texture(colortex0, texcoord).rgb * weight;
  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).rg;

  for (int i = 0; i < DOF_SAMPLES; i++) {
    float radius =
      sqrt(float(i + jitter.x) / DOF_SAMPLES) * float(DOF_MAX_RADIUS);
    float ang = float(i) * GOLDEN_ANGLE + jitter.y * TAU;
    vec2 sampleCoord = texcoord + vec2(cos(ang), sin(ang)) * pixelSize * radius;
    vec3 sampleColor = texelFetch(
      colortex0,
      ivec2(sampleCoord * resolution),
      0
    ).rgb;
    float sampleCoC = texture(colortex6, sampleCoord).r;

    float sampleWeight =
      getSampleWeight(sampleCoC, CoC, radius) /
      (PI * pow2(sampleCoC / 2) + 1.0);

    color += sampleColor * sampleWeight;
    weight += sampleWeight;
  }

  color /= weight;
}

#endif
