/*

const int colortex0Format = RGB32F;  || scene colour
const int colortex1Format = RGBA16;  || albedo, face normal, lightmap
const int colortex2Format = RGBA16;  || mapped normal, specular map data
const int colortex3Format = RGBA16F; || stars [gbuffers > deferred] translucents [gbuffers translucent>]
const int colortex4Format = RGBA32F; || previous frame data - color rgb, opaque depth
const int colortex5Format = RGBA16F; || hand
const int colortex6Format = RGBA16F; || clouds

*/

const bool colortex4Clear = false;

const bool shadowHardwareFiltering = true;
const float shadowDistance = 160.0;

#define SKYLIGHT_STRENGTH 0.2
#define AMBIENT_STRENGTH 0.01
#define SUNLIGHT_STRENGTH 4.0

#define WATER_NORMALS

#define SSR
#define SSR_FADE
#define SSR_SAMPLES 4
#define ROUGH_REFLECTION_THRESHOLD 0.3

#define TORCH_COLOR vec3(0.8, 0.6, 0.5)

#define SHADOWS
#define TRANSPARENT_SHADOWS
#define SHADOW_DISTORTION 0.85
#define MAX_PENUMBRA_WIDTH 80.0
#define MIN_PENUMBRA_WIDTH 0.0
#define BLOCKER_SEARCH_SAMPLES 8
#define BLOCKER_SEARCH_RADIUS 5
#define SHADOW_SAMPLES 16 // [4 8 16 32 64]
#define SUBSURFACE_SCATTERING

//#define NORMAL_BIAS //Offsets the shadow sample position by the surface normal instead of towards the sun
const int shadowMapResolution = 2048; //Resolution of the shadow map. Higher numbers mean more accurate shadows. [128 256 512 1024 2048 4096 8192]
const float sunPathRotation = -40;

#define NORMAL_MAPS
#define SPECULAR_MAPS

#define FOG
#define FOG_POWER 8.0
#define FOG_START 0.2

#define CLOUDS
#define CLOUD_BLUR_RADIUS_THRESHOLD 4.0

#define FXAA
#define FXAA_SUBPIXEL 0.75 //[0.00 0.25 0.50 0.75 1.00]
#define FXAA_EDGE_SENSITIVITY 1 //[0 1 2]

#define BLOOM
#define BLOOM_RADIUS 1.0
#define BLOOM_STRENGTH 1.0

// #define REFRACTION
#define REFRACTION_AMOUNT 0.5

#define VOLUMETRIC_WATER
#define VOLUMETRIC_WATER_SAMPLES 10
#define VOLUMETRIC_WATER_SUBSAMPLES 4
#define WATER_EXTINCTION (vec3(0.7, 0.1, 0.05) * 3.0)
#define WATER_K 0.5