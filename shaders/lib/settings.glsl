// #define DEBUG_ENABLE
// #define POST_PROCESS_DEBUG

#include "/lib/debug.glsl"

/*

const int colortex0Format = RGBA16F; || scene colour
const int colortex1Format = RGBA16;  || albedo, face normal, lightmap
const int colortex2Format = RGBA16;  || mapped normal, specular map data
const int colortex3Format = RGBA16F; || stars (parallax shadow in alpha) [gbuffers > deferred] translucents [gbuffers translucent>]
const int colortex4Format = RGBA32F; || previous frame data - color rgb, depth a
const int colortex5Format = RGBA16F; || hand
const int colortex6Format = RGB8;    || cloud shadow map
const int colortex7Format = RGBA16F; || cloud scattering (transmittance in alpha)
const int colortex8Format = RGBA16F;   || opaque specular, volumetrics
const int colortex9Format = RGB16F;  || sky environment map
const int colortex10Format = RGBA16F;  || global illumination
const int colortex11Format = RGBA16F;|| SMAA

*/

const bool shadowtex0Mipmap = true;
const bool shadowtex1Mipmap = true;
const bool shadowColor1Mipmap = true;

const float wetnessHalflife = 50.0;
const float centerDepthHalflife = 5.0;

const bool colortex4Clear = false;

const bool colortex10Clear = false;

const bool colortex7Clear = false;

const bool shadowHardwareFiltering = true;
const float shadowDistance = 192.0; // [16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 272.0 288.0 304.0 320.0 336.0 352.0 368.0 384.0 400.0 416.0 432.0 448.0 464.0 480.0 496.0 512.0]
const int shadowMapResolution = 2048; // [128 256 512 1024 2048 4096 8192]
const float sunPathRotation = -40.0; // [-90.0 -85.0 -80.0 -75.0 -70.0 -65.0 -60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0]

#define SKYLIGHT_STRENGTH 1.0
#define AMBIENT_STRENGTH 0.001
#define SUNLIGHT_STRENGTH 1.0
#define BLOCKLIGHT_STRENGTH 1.0

#define DIRECTIONAL_LIGHTMAPPING
#define BLOCKLIGHT_DIRECTIONAL_STRENGTH 0.25
#define SKYLIGHT_DIRECTIONAL_STRENGTH 1.0

#define SSR
#define SSR_FADE
#define SSR_SAMPLES 4 // [1 2 4 8 16 32 64]
#define ROUGH_REFLECTION_THRESHOLD 0.1 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
// #define BLUR_SPECULAR

#define BLOCKLIGHT_COLOR pow(vec3(255, 152, 54) / 255.0, vec3(2.2))

#define SHADOW_DISTORTION 0.85
#define SHADOW_BIAS 1.0
#define MAX_PENUMBRA_WIDTH 4.0
#define MIN_PENUMBRA_WIDTH 0.1
#define BLOCKER_SEARCH_SAMPLES 8
#define BLOCKER_SEARCH_RADIUS 0.5
#define SHADOW_SAMPLES 8 // [1 2 4 8 16 32 64]
#define SUBSURFACE_SCATTERING

#define NORMAL_MAPS
#define SPECULAR_MAPS

#define ATMOSPHERE_FOG
#define BORDER_FOG

#define CLOUDS
#define CUMULUS_CLOUDS
// #define ALTOCUMULUS_CLOUDS
#define CIRRUS_CLOUDS
// #define VANILLA_CLOUDS

#define CLOUD_SHADOWS

#define SKY_SATURATION 1.0

#define AA 2 // [0 1 2]

#if AA == 1
#define FXAA
#elif AA == 2
#define SMAA
#endif

// 
#define FXAA_SUBPIXEL 0.5 //[0.00 0.25 0.50 0.75 1.00]
#define FXAA_EDGE_SENSITIVITY 1 //[0 1 2]

#define BLOOM
#define BLOOM_RADIUS 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLOOM_STRENGTH 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define CUSTOM_WATER

#define REFRACTION
#define SNELLS_WINDOW

#define VOLUMETRIC_WATER
#define VOLUMETRIC_WATER_SAMPLES 10 // [5 10 15 20 25 30 35 40 45 50]
#define WATER_ABSORPTION vec3(0.3, 0.09, 0.04)
#define WATER_SCATTERING vec3(0.01, 0.06, 0.05)
#define WATER_G 0.6

#define CLOUD_FOG
#define CLOUD_FOG_SAMPLES 20 // [5 10 15 20 25 30 35 40 45 50]
#define CLOUD_FOG_SUBSAMPLES 4 // [4 5 6 7 8 9 10]

#define WAVE_DEPTH 0.3
#define WAVE_E 0.01
#define WATER_PARALLAX

#define SATURATION 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define EXPOSURE 20 // [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80]

#if EXPOSURE == 0
#define AUTO_EXPOSURE
#endif

// #define GLOBAL_ILLUMINATION
#define GI_SAMPLES 1 // [1 2 4 8 16 32]
#define GI_RESOLUTION 1.0 // [0.25 0.5 0.75 1.0]
// #define DISABLE_BLOCKLIGHT

#define CLOUD_BLEND 0.1

#define POM
#define POM_HEIGHT 0.25 // [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define POM_SAMPLES 32
#define PARALLAX_SHADOW_SAMPLES 8.0
#define POM_SHADOW

// #define DOF
// #define TILT_SHIFT
#define TILT_ANGLE 5.0 // [-180.0 -175.0 -170.0 -165.0 -160.0 -155.0 -150.0 -145.0 -140.0 -135.0 -130.0 -125.0 -120.0 -115.0 -110.0 -105.0 -100.0 -95.0 -90.0 -85.0 -80.0 -75.0 -70.0 -65.0 -60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 105.0 110.0 115.0 120.0 125.0 130.0 135.0 140.0 145.0 150.0 155.0 160.0 165.0 170.0 175.0]

// #define WATERMARK
#define GLINT_SHADERS 0 // [0 1]
#define WEBSITE 0 // [0 1]

// this is stupid
#ifdef CLOUD_SHADOWS
#endif

#ifdef DOF
#endif

#ifdef SMAA
#endif

#ifdef BLUR_SPECULAR
#endif