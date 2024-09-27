/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred3.glsl
    - Cloud generation
*/

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
  uniform sampler2D depthtex2;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float frameTimeCounter;
  uniform int worldTime;
  uniform int worldDay;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform float wetness;

  uniform float near;
  uniform float far;

  uniform int isEyeInWater;

  uniform bool hasSkylight;
  uniform vec3 fogColor;

  uniform ivec2 eyeBrightnessSmooth;

  in vec2 texcoord;

  /* DRAWBUFFERS:78 */
  layout(location = 0) out vec4 cloudScatter;
  layout(location = 1) out vec4 cloudTransmittance;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"


  void main() {
    if(clamp01(texcoord) != texcoord){
      return;
    }

    vec2 texcoord = floor(gl_FragCoord.xy / VOLUMETRIC_RESOLUTION) / vec2(viewWidth, viewHeight);

    const ivec2 offsets[4] = ivec2[4](
      ivec2(0),
      ivec2(1, 0),
      ivec2(0, 1),
      ivec2(1, 1)
    );

    float depth = max4(textureGatherOffsets(depthtex2, texcoord, offsets, 0));
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    cloudTransmittance.rgb = vec3(1.0);

    cloudScatter.rgb = hasSkylight ? getClouds(eyePlayerPos, depth, sunlightColor, skyLightColor, cloudTransmittance.rgb) : vec3(0.0);
  }
#endif