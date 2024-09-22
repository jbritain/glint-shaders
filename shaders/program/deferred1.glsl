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
  uniform sampler2D depthtex0;

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

    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    cloudScatter.rgb = hasSkylight ? getClouds(eyePlayerPos, depth, sunlightColor, skyLightColor, cloudTransmittance.rgb) : vec3(0.0);
  }
#endif