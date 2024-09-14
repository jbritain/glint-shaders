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
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;
  uniform sampler2D colortex3;
  uniform sampler2D colortex4;


  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;

  uniform int worldTime;

  uniform vec3 cameraPosition;

  uniform float wetness;
  uniform int isEyeInWater;

  uniform int frameCounter;

  uniform int viewWidth;
  uniform int viewHeight;

  uniform vec3 previousCameraPosition;

  in vec2 texcoord;

  vec3 albedo;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;

  vec3 mappedNormal;
  vec4 specularData;

  #include "/lib/util/gbufferData.glsl"
  #include "/lib/atmosphere/fog.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/water/waterFog.glsl"
  #include "/lib/util/screenSpaceRaytrace.glsl"
  #include "/lib/textures/blueNoise.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);
    decodeGbufferData(texture(colortex1, texcoord), texture(colortex2, texcoord));

    float translucentDepth = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex1, texcoord).r;

    vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(texcoord, opaqueDepth));
    vec3 opaqueEyePlayerPos = mat3(gbufferModelViewInverse) * opaqueViewPos;

    vec3 translucentViewPos = screenSpaceToViewSpace(vec3(texcoord, translucentDepth));
    vec3 translucentEyePlayerPos = mat3(gbufferModelViewInverse) * translucentViewPos;
    
    vec4 translucent = texture(colortex3, texcoord);

    bool inWater = isEyeInWater == 1;
    bool waterMask = materialIsWater(materialID);

    #ifdef REFRACTION
    if(waterMask){
      vec3 dir = normalize(translucentViewPos);
      vec3 refracted = normalize(refract(dir, mappedNormal, inWater ? 1.33 : (1.0 / 1.33)));

      vec3 refractedPos = vec3(0.0);
      float jitter = blueNoise(texcoord, frameCounter).r;
      traceRay(translucentViewPos, refracted, 32, jitter, true, refractedPos, false);
      refractedPos = clamp01(refractedPos);
      refractedPos.xy = mix(refractedPos.xy, texcoord, smoothstep(0.4, 0.5, distance(refractedPos.xy, vec2(0.5))));
        
      color.rgb = texture(colortex0, refractedPos.xy).rgb;
    }
    #endif

    if(waterMask == inWater && opaqueDepth != 1.0){
      color = getFog(color, opaqueEyePlayerPos);
    }

    if(inWater && !waterMask){
      color = waterFog(color, vec3(0.0), opaqueViewPos);
    }

    color.rgb = mix(color.rgb, translucent.rgb, translucent.a);
  }
#endif