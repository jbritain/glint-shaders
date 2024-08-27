/*

const int colortex0Format = RGB32F;  || scene colour
const int colortex1Format = RGBA16;  || albedo, face normal, lightmap
const int colortex2Format = RGBA16;  || mapped normal, specular map data
const int colortex3Format = RGBA16F; || clouds
const int colortex4Format = RGBA32F; || previous frame data

*/

const bool colortex4Clear = false;
const bool shadowHardwareFiltering = true;


#define SKYLIGHT_STRENGTH 0.5
#define AMBIENT_STRENGTH 0.02
#define SUNLIGHT_STRENGTH 0.1

#define BLOOM
#define BLOOM_AMOUNT 0.2 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_BLUR 1.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0]

#define SSR_FADE
#define SSR_SAMPLES 4
#define ROUGH_REFLECTION_THRESHOLD 0.3

#define TORCH_COLOR vec3(0.8, 0.6, 0.5)

#define WATER_COLOR vec4(0.015, 0.04, 0.098, 0.5)

#define SHADOWS
#define TRANSPARENT_SHADOWS
#define SHADOW_DISTORT_ENABLED //Toggles shadow map distortion
#define SHADOW_DISTORT_FACTOR 0.1 //Distortion factor for the shadow map. Has no effect when shadow distortion is disabled. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define SHADOW_BIAS 1.00 //Increase this if you get shadow acne. Decrease this if you get peter panning. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]
//#define NORMAL_BIAS //Offsets the shadow sample position by the surface normal instead of towards the sun
const int shadowMapResolution = 2048; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]
const float sunPathRotation = -40;

#define NORMAL_MAPS