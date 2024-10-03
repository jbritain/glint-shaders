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
  }
#endif

#ifdef fsh
  uniform sampler2D colortex0;
  uniform sampler2D colortex4;
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;
  uniform sampler2D colortex9;

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

  /* DRAWBUFFERS:70 */
  layout(location = 0) out vec4 cloudData;
  layout(location = 1) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/clouds.glsl"


  void main() {

    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    color = texture(colortex0, texcoord);
    
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    vec3 cloudTransmittance = vec3(1.0);

    vec3 cloudScatter = getClouds(eyePlayerPos, depth, sunlightColor, skyLightColor, cloudTransmittance);

    vec3 screenPos = vec3(texcoord, depth);
    vec3 previousScreenPos = reproject(screenPos);
    previousScreenPos.z = texture(colortex4, previousScreenPos.xy).a;

    if(clamp01(previousScreenPos.xy) == previousScreenPos.xy && depth == previousScreenPos.z){
      vec4 previousCloudData = texture(colortex7, previousScreenPos.xy);

      cloudScatter.rgb = mix(previousCloudData.rgb, cloudScatter.rgb, CLOUD_BLEND);
      cloudTransmittance.rgb = mix(vec3(previousCloudData.a), cloudTransmittance, CLOUD_BLEND);
    }

    color.rgb = color.rgb * cloudTransmittance.rgb + cloudScatter.rgb;
    cloudData.rgb = cloudScatter;
    cloudData.a = sum3(cloudTransmittance) / 3.0;
  }
#endif