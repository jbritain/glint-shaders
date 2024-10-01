/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare.glsl
    - Cloud shadow map
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;
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

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform ivec2 eyeBrightnessSmooth;

  uniform bool hasSkylight;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/atmosphere/clouds.glsl"

  /* DRAWBUFFERS:6 */
  layout(location = 0) out vec4 color;

  void main() {
    if(!hasSkylight){
      color = vec4(0.0);
      return;
    }

    vec3 shadowScreenPos = vec3(texcoord, 1.0);
    vec3 shadowNDCPos = shadowScreenPos * 2.0 - 1.0;
    vec4 shadowHomPos = shadowProjectionInverse * vec4(shadowNDCPos, 1.0);
    vec3 shadowViewPos = shadowHomPos.xyz / shadowHomPos.w;

    vec3 feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
    vec3 rayPos;
    rayPlaneIntersection(feetPlayerPos + cameraPosition, lightVector, CUMULUS_LOWER_HEIGHT, rayPos);
    rayPos.y += 0.1;

    float jitter = 0.0;

    float totalDensity = getTotalDensityTowardsLight(rayPos, jitter, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, CUMULUS_SUBSAMPLES);
    totalDensity += getTotalDensityTowardsLight(rayPos, jitter, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, ALTOCUMULUS_SUBSAMPLES);
    totalDensity += getTotalDensityTowardsLight(rayPos, jitter, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, CIRRUS_SUBSAMPLES);

    vec3 totalTransmittance = exp(-totalDensity * CLOUD_EXTINCTION_COLOR);

    color.rgb = totalTransmittance;
    color.a = 1.0;
    show(totalTransmittance);
    // show(feetPlayerPos.xz);

    // color = vec4(1.0);
  }
#endif