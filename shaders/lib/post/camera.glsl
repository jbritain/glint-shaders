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

// REFERENCES
// https://placeholderart.wordpress.com/2014/12/15/implementing-a-physically-based-camera-automatic-exposure/
// https://bruop.github.io/exposure/

#define SENSOR_SENSITIVITY 100
#define CALIBRATION_CONSTANT 12.5
#define LENS_VIGNETTE 0.65

float getMeteringWeight(vec2 texcoord) {
  return 1.0;
}

#endif // CAMERA_GLSL
