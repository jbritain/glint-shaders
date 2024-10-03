/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare1.glsl
    - Sky environment map
*/

#include "/lib/settings.glsl"
#define HIGH_CLOUD_SAMPLES

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex9;

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
  uniform vec3 previousCameraPosition;

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
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/atmosphere/clouds.glsl"
  #include "/lib/util/spheremap.glsl"

  const bool colortex9MipmapEnabled = true; // for later

  /* DRAWBUFFERS:9 */
  layout(location = 0) out vec4 color;

  void main() {
    if(!hasSkylight){
      color = vec4(0.0);
      return;
    }

    vec3 dir = unmapSphere(texcoord);

    color.rgb = getSky(color, dir, false);

    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    vec3 cloudTransmittance;
    vec3 cloudScatter = getClouds(dir * far, 1.0, sunlightColor, skyLightColor, cloudTransmittance.rgb);

    color.rgb *= cloudTransmittance;
    color.rgb += cloudScatter;
  }
#endif