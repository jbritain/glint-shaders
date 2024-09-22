#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    texcoord /= VOLUMETRIC_RESOLUTION;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex0;
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex3;
  uniform sampler2D colortex4;
  uniform sampler2D colortex6;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;

  uniform sampler2D depthtex0;
  uniform sampler2D depthtex2;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowProjection;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform int worldTime;
  uniform int worldDay;

  uniform vec3 cameraPosition;

  uniform float far;
  uniform float wetness;
  uniform int isEyeInWater;

  uniform int frameCounter;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform ivec2 eyeBrightnessSmooth;

  uniform vec3 previousCameraPosition;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"

  /* DRAWBUFFERS:78 */
  layout(location = 0) out vec4 fogScatter;
  layout(location = 1) out vec4 fogTransmittance;

  void main() {
    if(clamp01(texcoord) != texcoord){
      return;
    }

    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    const int pixelsExpanded = int(1.0/VOLUMETRIC_RESOLUTION - 1.0);

    const ivec2 offsets[4] = ivec2[4](
      ivec2(0),
      ivec2(pixelsExpanded, 0),
      ivec2(0, pixelsExpanded),
      ivec2(pixelsExpanded, pixelsExpanded)
    );

    vec2 texcoord = floor(gl_FragCoord.xy / VOLUMETRIC_RESOLUTION) / vec2(viewWidth, viewHeight);

    float translucentDepth = max4(textureGatherOffsets(depthtex0, texcoord, offsets, 0));

    vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
    vec3 translucentEyePlayerPos = mat3(gbufferModelViewInverse) * translucentViewPos;
    
    if(isEyeInWater == 0.0){
      fogScatter.rgb = getCloudFog(vec3(0.0), translucentEyePlayerPos, translucentDepth, sunlightColor, skyLightColor, fogTransmittance.rgb);
    } else {
      fogScatter.rgb = vec3(0.0);
      fogTransmittance.rgb = vec3(1.0);
    }
    
  }
#endif