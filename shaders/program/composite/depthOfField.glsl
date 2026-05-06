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

// https://blog.voxagon.se/2018/05/04/bokeh-depth-of-field-in-single-pass.html
// TODO: since DoF is applied before temporal filtering, screen space reflections etc reflect the DoF

float DOF_MAX_RADIUS_PIXELS = DOF_MAX_RADIUS * min(viewWidth, viewHeight);

const float DOF_STEP = DOF_MAX_RADIUS_PIXELS / DOF_SAMPLES;
const float GOLDEN_ANGLE = 2.39996323;

float getBlurRadius(float depth, float focusDepth) {
  float focalLength = getFocalLength();
  depth *= 1000; // convert to mm
  focusDepth *= 1000;
  float coc =
    pow2(focalLength) /
    (APERTURE * (focusDepth - focalLength)) *
    (abs(depth - focusDepth) / depth);

  return abs(coc) * viewWidth / SENSOR_SIZE;
}
void main() {
  float depth = -screenSpaceToViewSpace(texture(depthtex0, texcoord).r);
  float focusDepth = -screenSpaceToViewSpace(centerDepthSmooth);

  float blurRadius = getBlurRadius(depth, focusDepth);
  color = texture(colortex0, texcoord).rgb;
  float weight = 1.0;
  vec2 jitter = blueNoise(gl_FragCoord.xy, frameCounter).rg;
  float radius = DOF_STEP * jitter.y;
  float ang = jitter.x * TAU;

  for (int i = 0; i < DOF_SAMPLES; i++) {
    vec2 sampleCoord = texcoord + vec2(cos(ang), sin(ang)) * pixelSize * radius;
    vec3 sampleColor = texture(colortex0, sampleCoord).rgb;
    float sampleDepth = -screenSpaceToViewSpace(
      texture(depthtex0, sampleCoord).r
    );
    float sampleBlurRadius = getBlurRadius(sampleDepth, focusDepth);
    if (sampleDepth > depth) {
      sampleBlurRadius = clamp(sampleBlurRadius, 0.0, blurRadius * 2.0);
    }
    float m = smoothstep(radius - 0.5, radius + 0.5, sampleBlurRadius);
    color += mix(color / weight, sampleColor, m);
    weight += 1.0;
    radius += DOF_STEP / radius;
    ang = mod(ang + TAU / DOF_SAMPLES, TAU);
  }

  color /= weight;
}

#endif
