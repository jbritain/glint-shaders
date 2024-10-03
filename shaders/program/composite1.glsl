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
  uniform sampler2D colortex6;
  uniform sampler2D colortex7;
  uniform sampler2D colortex8;
  uniform sampler2D colortex9;

  uniform sampler2D shadowtex0;
  uniform sampler2D shadowtex1;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;

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

  uniform ivec2 eyeBrightnessSmooth;

  in vec2 texcoord;

  /* DRAWBUFFERS:80 */
  layout(location = 0) out vec4 fogData;
  layout(location = 1) out vec4 color;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util/noise.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/atmosphere/cloudFog.glsl"


  void main() {

    color = texture(colortex0, texcoord);

    // TODO: VOLUMETRIC FOG BEHIND TRANSLUCENTS
    if(isEyeInWater != 0){
      return;
    }

    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    
    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    vec3 fogTransmittance = vec3(1.0);

    vec3 fogScatter = hasSkylight ? getCloudFog(vec3(0.0), eyePlayerPos, depth, sunlightColor, skyLightColor, fogTransmittance) : vec3(0.0);

    vec3 screenPos = vec3(texcoord, depth);
    vec3 previousScreenPos = reproject(screenPos);
    previousScreenPos.z = texture(colortex4, previousScreenPos.xy).a;

    // TODO: ABANDON ACCUMULATING FOG
    if(clamp01(previousScreenPos.xy) == previousScreenPos.xy && depth == previousScreenPos.z){
      vec4 previousFogData = texture(colortex8, previousScreenPos.xy);

      fogScatter.rgb = mix(previousFogData.rgb, fogScatter.rgb, CLOUD_BLEND);
      fogTransmittance.rgb = mix(vec3(previousFogData.a), fogTransmittance, CLOUD_BLEND);
    }

    color.rgb = color.rgb * fogTransmittance.rgb + fogScatter.rgb;
    fogData.rgb = fogScatter;
    fogData.a = sum3(fogTransmittance) / 3.0;
  }
#endif