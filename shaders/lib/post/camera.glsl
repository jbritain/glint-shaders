/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

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
  return 1.0;
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

#endif // CAMERA_GLSL
