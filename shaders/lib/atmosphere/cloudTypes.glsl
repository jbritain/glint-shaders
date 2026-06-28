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

#ifndef CLOUD_TYPES_GLSL
#define CLOUD_TYPES_GLSL

#define CUMULUS_HEIGHT_FUNCTION 1
#define CUMULONIMBUS_HEIGHT_FUNCTION 2
float getHeightFunction(uint heightFunctionID, float heightInPlane) {
  switch (heightFunctionID) {
    case CUMULUS_HEIGHT_FUNCTION:
      heightInPlane /= 2.0;
      return pow2(
        linearstep(0.0, 0.15, heightInPlane) *
          pow2(1.0 - linearstep(0.15, 1.2, heightInPlane))
      );
    case CUMULONIMBUS_HEIGHT_FUNCTION:
      float column = pow2(1.0 - linearstep(0.0, 4.0, heightInPlane));
      float anvil =
        step(0.8, heightInPlane) * (1.0 - linearstep(0.8, 1.0, heightInPlane));

      // return column;
      return clamp01(column + anvil);
  }
}

struct Clouds {
  float ceilingAltitude;
  float baseAltitude;
  float coverageScale;
  float lowFrequencyScale;
  float highFrequencyScale;
  float coverageMin;
  float coverageMax;
  float density;
  float powderStrength;
  uint heightFunction;
};

Clouds interpolateCloudType(Clouds a, Clouds b, float factor) {
  return Clouds(
    mix(a.ceilingAltitude, b.ceilingAltitude, factor),
    mix(a.baseAltitude, b.baseAltitude, factor),
    mix(a.coverageScale, b.coverageScale, factor),
    mix(a.lowFrequencyScale, b.lowFrequencyScale, factor),
    mix(a.highFrequencyScale, b.highFrequencyScale, factor),
    mix(a.coverageMin, b.coverageMin, factor),
    mix(a.coverageMax, b.coverageMax, factor),
    mix(a.density, b.density, factor),
    mix(a.powderStrength, b.powderStrength, factor),
    frameCounter % 12 / 12.0 < factor
      ? b.heightFunction
      : a.heightFunction
  );
}

const Clouds testClouds = Clouds(
  700.0,
  100.0,
  32000,
  600,
  100,
  0.55,
  0.7,
  1.0,
  0.7,
  CUMULUS_HEIGHT_FUNCTION
);

const Clouds cumulusHumilis = Clouds(
  400,
  300.0,
  25000,
  300,
  40,
  0.5,
  0.7,
  1.0,
  0.3,
  CUMULUS_HEIGHT_FUNCTION
);

const Clouds cumulusMediocris = Clouds(
  600,
  300.0,
  25000,
  300,
  80,
  0.5,
  0.7,
  1.0,
  0.2,
  CUMULUS_HEIGHT_FUNCTION
);

const Clouds cumulonimbus = Clouds(
  1000,
  300.0,
  150000,
  1500,
  200,
  0.5,
  0.7,
  4.0,
  0.2,
  CUMULONIMBUS_HEIGHT_FUNCTION
);

// const Clouds cumulusCongestus = Clouds(
//   1200,
//   300.0,
//   50000,
//   600,
//   100,
//   0.5,
//   0.8,
//   5.0,
//   0.3
// );

#define defaultClouds testClouds

#endif
