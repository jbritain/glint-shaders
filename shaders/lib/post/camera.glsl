/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef CAMERA_GLSL
#define CAMERA_GLSL

// https://google.github.io/filament/Filament.md.html

#define CALIBRATION_CONSTANT 12.5
#define LENS_VIGNETTE 0.65

const float SHUTTER_SPEED = 1.0 / SHUTTER_TIME;

float getMeteringWeight(vec2 texcoord) {
  return clamp01(1.0 - length(texcoord - 0.5) / 0.5) * (12 / PI);
}

float autoEV100(float luminance) {
  return clamp(
    log2(luminance * ISO / CALIBRATION_CONSTANT),
    MIN_EV100,
    MAX_EV100
  );
}

float manualEV100() {
  return log2(pow2(APERTURE) / SHUTTER_SPEED * 100.0 / ISO);
}

float calculateExposure(float ev100) {
  return 1.0 / (pow(2.0, ev100) * 1.2);
}

// TODO: this can be a custom uniform I think
// VALUE IS IN MM
float getFocalLength() {
  return SENSOR_SIZE * 0.5 / tan(horizontalFov * 0.5);
}

float circleOfConfusion(float depth, float focusDepth) {
  float focalLength = getFocalLength();
  depth *= 1000; // convert to mm
  focusDepth *= 1000;
  float baseCoC = SENSOR_SIZE * focalLength / (focusDepth - focalLength);
  float depthTerm = (depth - focusDepth) / depth;
  float CoC = baseCoC * depthTerm;

  return CoC * viewWidth / SENSOR_SIZE;
}

vec3 purkinje(vec3 color) {
  float shift = 1.0 - linearstep(0.03, 3.0, averageLuminanceSmooth);

  // https://jamesferwerda.com/wp-content/uploads/2015/06/j09_thompson02_jgt.pdf
  // https://github.com/tobspr/GLSL-Color-Spaces/blob/master/ColorSpaces.inc.glsl
  const mat3 xyzMatrix = mat3(
    0.4124564, 0.2126729, 0.0193339,
    0.3575761, 0.7151522, 0.119192 ,
    0.1804375, 0.072175 , 0.9503041
  );
  vec3 xyz = xyzMatrix * color;
  float scotopicLuminance =
    xyz.y * (1.33 * (1.0 + (xyz.y + xyz.z) / xyz.x) - 0.168);
  vec3 purkinjeColor =
    vec3(scotopicLuminance) * vec3(PURKINJE_R, PURKINJE_G, PURKINJE_B) / 255.0;

  return mix(color, purkinjeColor, shift * PURKINJE_STRENGTH);

}

#endif // CAMERA_GLSL
