#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 geometryNormal;
  out vec3 tangent;
  out float materialID;
  out vec3 viewPos;

  attribute vec3 at_tangent;
  attribute vec2 mc_Entity;

  void main() {
    gl_Position = ftransform();
    materialID = mc_Entity.x;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    geometryNormal = gl_NormalMatrix * gl_Normal;
    tangent = gl_NormalMatrix * at_tangent;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform float near;
  uniform float far;
  uniform mat4 gbufferModelViewInverse;
  uniform vec3 sunPosition;
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2DShadow shadowtex0;
  uniform sampler2D shadowcolor0;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec3 geometryNormal;
  in vec4 glcolor;
  in vec3 tangent;
  in float materialID;
  in vec3 viewPos;

  #include "/lib/util.glsl"
  #include "/lib/tonemap.glsl"
  #include "/lib/sky.glsl"
  #include "/lib/getSunlight.glsl"

  

  /* DRAWBUFFERS:012 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 outNormal;
  layout(location = 2) out vec4 outLightmap;

  void main() {
    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = gammaCorrect(color.rgb);

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    if (color.a < 0.1) {
      discard;
    }

    vec3 normal = geometryNormal;

    #ifdef NORMAL_MAPS
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    mat3 tbnMatrix = tbnNormalTangent(geometryNormal, tangent);
    normal = tbnMatrix * mappedNormal;
    #endif

    float lightmapSky = lmcoord.g;
    float lightmapBlock = lmcoord.r;

    vec3 sunlightColor = getSky(SUN_VECTOR);
    vec3 skyLightColor = getSky(vec3(0, 1, 0));

    vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * lightmapSky;
    vec3 artificial = TORCH_COLOR * lightmapBlock;

    

    float nDotL = clamp01(dot(normal, normalize(sunPosition)));
    nDotL *= step(0.01, dot(geometryNormal, normalize(sunPosition)));
    vec3 direct = nDotL * getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, sunlightColor, normal);

    color.rgb *= (skyLight + direct + artificial + skyLightColor * AMBIENT_STRENGTH);

    
    

    outNormal.rgb = encodeNormal(normal);

    outLightmap = vec4(lmcoord, 0.0, 1.0);
  }
#endif