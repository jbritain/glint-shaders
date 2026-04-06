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

layout(location = 0) out vec3 color;

const bool colortex0MipmapEnabled = true;

void main() {
  color = texture(colortex0, texcoord).rgb;

  int maxMipLevel = int(floor(log2(max(viewWidth, viewHeight))));
  float averageLuminance = textureLod(colortex0, vec2(0.5), maxMipLevel).a;

  if (gl_FragCoord.xy == vec2(0.5)) {
    if (frameCounter <= 10) {
      averageLuminanceSmooth = averageLuminance;
    }

    averageLuminanceSmooth = mix(
      averageLuminance,
      averageLuminanceSmooth,
      clamp01(exp2(frameTime * -1))
    );
  }

  float EV100 = log2(
    averageLuminanceSmooth * SENSOR_SENSITIVITY / CALIBRATION_CONSTANT
  );

  float Lmax =
    78 *
    pow(2.0, EV100 - EXPOSURE_COMPENSATION) /
    (LENS_VIGNETTE * SENSOR_SENSITIVITY);
  float exposure = rcp(Lmax);
  exposure = clamp(exposure, 0.0, 0.1);
  color *= exposure;

  // float purkinje = smoothstep(0.04, 0.05, exposure);
  // color = hsv(color);
  // color.g *= 1.0 - purkinje * 0.5;
  // color = rgb(color);
  // color.rg *= 1.0 - purkinje * 0.2;

}

#endif
