#ifndef COLOR_UTIL_GLSL
#define COLOR_UTIL_GLSL

// by belmu
// the goat
/*
    [References]:
        Wikipedia. (2022). YCoCg. https://en.wikipedia.org/wiki/YCoCg
        Wikipedia. (2023). Von Kries coefficient law. https://en.wikipedia.org/wiki/Von_Kries_coefficient_law
        Wikipedia. (2023). LMS color space. https://en.wikipedia.org/wiki/LMS_color_space
        Wikipedia. (2023). Academy Color Encoding System. https://en.wikipedia.org/wiki/Academy_Color_Encoding_System
        Wikipedia. (2023). Luma (video). https://en.wikipedia.org/wiki/Luma_(video)
        Wikipedia. (2023). sRGB. https://en.wikipedia.org/wiki/SRGB
*/

//////////////////////////////////////////////////////////
/*------------- COLOR CONVERSION MATRICES --------------*/
//////////////////////////////////////////////////////////

const mat3 SRGB_2_XYZ_MAT = mat3(
  0.4124564, 0.3575761, 0.1804375,
  0.2126729, 0.7151522, 0.072175 ,
  0.0193339, 0.119192 , 0.9503041
);

const mat3 XYZ_2_SRGB_MAT = mat3(
   3.2409699419, -1.5373831776, -0.4986107603,
  -0.9692436363,  1.8759675015,  0.0415550574,
   0.0556300797, -0.2039769589,  1.0569715142
);

const mat3 XYZ_2_AP0_MAT = mat3(
   1.0498110175,  0.0         , -0.0000974845,
  -0.4959030231,  1.3733130458,  0.0982400361,
   0.0         ,  0.0         ,  0.9912520182
);

const mat3 XYZ_2_AP1_MAT = mat3(
   1.6410233797, -0.3248032942, -0.2364246952,
  -0.6636628587,  1.6153315917,  0.0167563477,
   0.0117218943, -0.008284442 ,  0.9883948585
);

const mat3 AP0_2_XYZ_MAT = mat3(
   0.9525523959,  0.0         ,  0.0000936786,
   0.3439664498,  0.7281660966, -0.0721325464,
   0.0         ,  0.0         ,  1.0088251844
);

const mat3 AP1_2_XYZ_MAT = mat3(
   0.6624541811,  0.1340042065,  0.156187687 ,
   0.2722287168,  0.6740817658,  0.0536895174,
  -0.0055746495,  0.0040607335,  1.0103391003
);

const mat3 AP0_2_AP1_MAT = mat3(
   1.4514393161, -0.2365107469, -0.2149285693,
  -0.0765537734,  1.1762296998, -0.0996759264,
   0.0083161484, -0.0060324498,  0.9977163014
);

const mat3 AP1_2_AP0_MAT = mat3(
   0.6954522414,  0.1406786965,  0.1638690622,
   0.0447945634,  0.8596711185,  0.0955343182,
  -0.0055258826,  0.0040252103,  1.0015006723
);

const mat3 SRGB_2_AP1_MAT = mat3(
  0.6131324224, 0.3411640858, 0.0455034919,
  0.0701312622, 0.9226919042, 0.0127738147,
  0.0206155517, 0.1225777335, 0.9407840895
);

const mat3 D60_2_D65_CAT = mat3(
   0.987224  , -0.00611327,  0.0159533 ,
  -0.00759836,  1.00186   ,  0.00533002,
   0.00307257, -0.00509595,  1.08168
);

const mat3 D65_2_D60_CAT = mat3(
   1.01303   ,  0.00610531, -0.014971  ,
   0.00769823,  0.998165  , -0.00503203,
  -0.00284131,  0.00468516,  0.924507
);

const mat3 CONE_RESP_CAT02 = mat3(
  vec3(0.7328, 0.4296, -0.1624),
  vec3(-0.7036, 1.6975, 0.0061),
  vec3(0.003, 0.0136, 0.9834)
);

const mat3 CONE_RESP_CAT02_INV = inverse(CONE_RESP_CAT02);

const mat3 CONE_RESP_BRADFORD = mat3(
  vec3(0.8951, 0.2664, -0.1614),
  vec3(-0.7502, 1.7135, 0.0367),
  vec3(0.0389, -0.0685, 1.0296)
);

const vec3 AP1_RGB2Y = vec3(0.2722287168, 0.6740817658, 0.0536895174); // Desaturation Coefficients

const mat3 SRGB_2_AP1_ADAPTATION_MAT =
  SRGB_2_XYZ_MAT * D65_2_D60_CAT * XYZ_2_AP1_MAT;
const mat3 AP1_2_SRGB_ADAPTATION_MAT =
  AP1_2_XYZ_MAT * D60_2_D65_CAT * XYZ_2_SRGB_MAT;

//////////////////////////////////////////////////////////
/*----------------- COLOR CONVERSIONS ------------------*/
//////////////////////////////////////////////////////////

float luminanceAP1(vec3 color) {
  return dot(color, AP1_2_XYZ_MAT[1]);
}

float luminanceBT709(vec3 color) {
  return dot(color, SRGB_2_XYZ_MAT[1]);
}

vec3 linearToSrgb(vec3 linear) {
  vec3 higher = pow(abs(linear), vec3(0.41666666)) * 1.055 - 0.055;
  vec3 lower = linear * 12.92;
  return mix(higher, lower, step(linear, vec3(0.0031308)));
}

vec3 srgbToLinear(vec3 srgb) {
  vec3 higher = pow((srgb + 0.055) * 0.94786729, vec3(2.4));
  vec3 lower = srgb * 0.07739938;
  return mix(higher, lower, step(srgb, vec3(0.04045)));
}

vec3 linearToAP1(vec3 color) {
  return color * SRGB_2_AP1_ADAPTATION_MAT;
}

vec3 ap1ToLinear(vec3 color) {
  return color * AP1_2_SRGB_ADAPTATION_MAT;
}

vec3 srgbToLinearAlbedoAP1(vec3 color) {
  return srgbToLinear(color) * SRGB_2_AP1_MAT;
}

vec3 linearAlbedoAP1ToSrgb(vec3 color) {
  return linearToSrgb(color * AP1_2_XYZ_MAT * XYZ_2_SRGB_MAT);
}

vec3 fromYCoCg(vec3 color) {
  float r = color.x + color.y - color.z;
  float g = color.x + color.z;
  float b = color.x - color.y - color.z;
  return vec3(r, g, b);
}

vec3 toYCoCg(vec3 color) {
  float y = 0.25 * color.r + 0.5 * color.g + 0.25 * color.b;
  float co = 0.5 * color.r - 0.5 * color.b;
  float cg = -0.25 * color.r + 0.5 * color.g - 0.25 * color.b;
  return vec3(y, co, cg);
}
#endif
