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

  uniform bool hasSkylight;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/atmosphere/common.glsl"
  #include "/lib/atmosphere/clouds.glsl"

  /* DRAWBUFFERS:6 */
  layout(location = 0) out vec4 color;

  void main() {
    vec3 shadowScreenPos = vec3(texcoord, 1.0);
    vec3 shadowNDCPos = shadowScreenPos * 2.0 - 1.0;
    vec4 shadowHomPos = shadowProjectionInverse * vec4(shadowNDCPos, 1.0);
    vec3 shadowViewPos = shadowHomPos.xyz / shadowHomPos.w;

    vec3 feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;

    vec3 a;
    rayPlaneIntersection(feetPlayerPos + cameraPosition, lightVector, CLOUD_LOWER_PLANE_HEIGHT, a);

    vec3 b;
    rayPlaneIntersection(feetPlayerPos + cameraPosition, lightVector, CLOUD_UPPER_PLANE_HEIGHT, b);

    const int samples = 10;
    vec3 increment = (b - a) / float(samples);

    vec3 rayPos = a;

    vec3 totalTransmittance = vec3(1.0);

    for (int i = 0; i < samples; i++){
      float density = getCloudDensity(rayPos) * length(increment);
      vec3 transmittance = exp(-density * CLOUD_EXTINCTION_COLOR);

      totalTransmittance *= transmittance;

      rayPos += increment;
    }

    color.rgb = totalTransmittance;
    color.a = 1.0;
  }
#endif