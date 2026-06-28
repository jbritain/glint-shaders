#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

// uniform list from Complementary
// https://github.com/ComplementaryDevelopment/ComplementaryReimagined/blob/main/shaders/lib/uniforms.glsl

/*----------------------------------------------------------------------------------------------
        _____                                                                    _____
        ( ___ )                                                                  ( ___ )
        |   |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|   |
        |   | ██╗   ██╗███╗   ██╗██╗███████╗ ██████╗ ██████╗ ███╗   ███╗███████╗ |   |
        |   | ██║   ██║████╗  ██║██║██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔════╝ |   |
        |   | ██║   ██║██╔██╗ ██║██║█████╗  ██║   ██║██████╔╝██╔████╔██║███████╗ |   |
        |   | ██║   ██║██║╚██╗██║██║██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║╚════██║ |   |
        |   | ╚██████╔╝██║ ╚████║██║██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████║ |   |
        |   |  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ |   |
        |___|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|___|
        (_____)                              (thanks to isuewo and SpacEagle17)  (_____)

---------------------------------------------------------------------------------------------*/

uniform float alphaTestRef;

uniform int blockEntityId;
uniform int currentRenderedItemId;
uniform int entityId;
uniform int frameCounter;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int heldItemId;
uniform int heldItemId2;
uniform int isEyeInWater;
uniform int moonPhase;
uniform int worldTime;
uniform int worldDay;
uniform int renderStage;

uniform bool hideGUI;

uniform float aspectRatio;
uniform float blindness;
uniform float darknessFactor;
uniform float darknessLightFactor;
uniform float maxBlindnessDarkness;
uniform float eyeAltitude;
uniform float frameTime;

#ifdef FREEZE_TIME
const float frameTimeCounter = 0.0;
#else
uniform float frameTimeCounter;
#endif

uniform float far;
uniform float near;
uniform float nightVision;
uniform float rainStrength;
uniform float thunderStrength;
uniform float screenBrightness;
uniform float viewHeight;
uniform float viewWidth;
uniform vec2 resolution;
uniform float fov;
uniform float horizontalFov;
uniform vec2 pixelSize;
uniform float wetness;
uniform float sunAngle;
uniform float playerMood;
uniform float constantMood;

uniform float centerDepthSmooth;

uniform ivec2 atlasSize;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 previousCameraPosition;
uniform vec3 skyColor;
uniform vec3 relativeEyePosition;
uniform vec3 eyePosition;

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;

uniform vec4 entityColor;
uniform vec4 lightningBoltPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

#ifdef VOXY
uniform mat4 vxProj;
uniform mat4 vxProjInv;
uniform int vxRenderDistance;
uniform sampler2D vxDepthTexOpaque;
uniform sampler2D vxDepthTexTrans;
#endif

uniform sampler2D colortex0;
uniform usampler2D colortex1;
uniform usampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform usampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;
uniform sampler2D colortex16;
uniform sampler2D colortex17;

uniform sampler2D colortex29;
uniform usampler2D colortex30;
uniform usampler2D colortex31;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D normals;
uniform sampler2D noisetex;
uniform sampler2D specular;
uniform sampler2D gtexture;

uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;
uniform vec3 cameraPositionFract;
uniform vec3 previousCameraPositionFract;

uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;
uniform sampler2DShadow shadowtex1HW;
uniform sampler2DShadow shadowtex0HW;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowcolor2;

uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;
uniform sampler2D skyViewLUTTex;
uniform sampler3D aerialPerspectiveLUTTex;

uniform sampler2D skyCloudMapTex;

uniform usampler2D undistortedShadowMapTex;
uniform usampler2D shadowImportanceMapTex;

uniform sampler2D perlinnoisetex;
uniform sampler3D bluenoisetex;

uniform sampler2D moontex;
uniform sampler2D startex;

uniform bool isDay;
uniform vec3 sunDir;
uniform vec3 moonDir;
uniform vec3 lightDir;
uniform vec3 worldSunDir;
uniform vec3 worldMoonDir;
uniform vec3 worldLightDir;

uniform sampler2D indirectRadiosityTex;
#ifndef GBUFFERS_VOXELS
uniform sampler2D radiosity_direct;
uniform sampler2D radiosity_direct_soft;
#endif

uniform usampler3D voxelMapTex;
uniform sampler3D floodfillVoxelMapTex1;
uniform sampler3D floodfillVoxelMapTex2;

uniform sampler3D lowFrequencyCloudNoiseTex;
uniform sampler3D highFrequencyCloudNoiseTex;
// uniform sampler2D cloudCoverageTex1;
// uniform sampler2D cloudCoverageTex2;
uniform sampler2D cloudCoverageTex;
// uniform sampler2D cloudProfileTex;

uniform sampler2D vanillacloudtex;

#endif // UNIFORMS_GLSL
