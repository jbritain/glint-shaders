#include "/lib/settings.glsl"
#include "/lib/util.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex0;
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex6;

  uniform sampler2D depthtex2;

  uniform sampler2D shadowtex0;
  uniform sampler2DShadow shadowtex0HW;
  uniform sampler2DShadow shadowtex1HW;
  uniform sampler2D shadowcolor0;
  uniform sampler2D shadowcolor1;
  uniform sampler2D shadowcolor2;

  uniform sampler2D noisetex;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;

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

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  /* DRAWBUFFERS:8 */
  layout(location = 0) out vec4 outGI;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/lighting/shadowBias.glsl"
  #include "/lib/atmosphere/sky.glsl"
  #include "/lib/lighting/getSunlight.glsl"
  #include "/lib/textures/blueNoise.glsl"
  #include "/lib/util/noise.glsl"

  void main() {
    #ifdef GLOBAL_ILLUMINATION
    float depth = texture(depthtex2, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    if(depth == 1.0){
      return;
    }

    vec3 sunlightColor; vec3 skyLightColor;
    getLightColors(sunlightColor, skyLightColor);

    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    vec3 worldFaceNormal = mat3(gbufferModelViewInverse) * faceNormal;

    vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);
    vec3 cloudShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos, faceNormal).xyz;

    // assumption - if we are in cloud shadow, so is the indirect light caster
    vec3 cloudShadow = texture(colortex6, cloudShadowScreenPos.xy).rgb;

    if(cloudShadow * sunlightColor == 0.0){
      return;
    }

    // assumption - if we are in direct sunlight, the indirect lighting will not be noticeable
    vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos, faceNormal).xyz;
    if(shadow2D(shadowtex0HW, shadowScreenPos) == 1.0 && dot(worldFaceNormal, lightVector) > 0.9){
      return;
    }

    float radius = GI_RADIUS;

    int samples = GI_SAMPLES;

    vec3 GI = vec3(0.0);

    for(int i = 0; i < samples; i++){
      vec2 noise = blueNoise(texcoord, i).xy;

      vec2 offset = vec2(
        radius * noise.x * sin(2 * PI * noise.y),
        radius * noise.x * cos(2 * PI * noise.y)
      );

      vec4 offsetPos = shadowClipPos + vec4(offset, 0.0, 0.0);

      vec3 offsetScreenPos = getShadowScreenPos(offsetPos, faceNormal).xyz;

      vec3 flux = texture(shadowcolor0, offsetScreenPos.xy).rgb;
      vec3 sampleNormal = texture(shadowcolor1, offsetScreenPos.xy).yzx; // this is in world space

      // z component reconstruction
      sampleNormal = sampleNormal * 2.0 - 1.0;
      sampleNormal.z = sqrt(1.0 - dot(sampleNormal.xy, sampleNormal.xy));
      sampleNormal = normalize(sampleNormal);
      sampleNormal = mat3(shadowModelViewInverse) * sampleNormal;
      vec3 samplePos = texture(shadowcolor2, offsetScreenPos.xy).xyz;


      flux *= max0(dot(feetPlayerPos - samplePos, sampleNormal));
      flux *= max0(dot(worldFaceNormal, samplePos - feetPlayerPos));
      flux /= pow4(distance(samplePos, feetPlayerPos));
      flux *= pow2(noise.x);

      GI += flux;
    }

    GI /= samples;
    GI *= GI_BRIGHTNESS;
    GI *= sunlightColor * cloudShadow;

    outGI.rgb = GI;
    #endif

  }
#endif