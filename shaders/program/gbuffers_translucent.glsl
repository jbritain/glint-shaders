#include "/lib/settings.glsl"

#ifdef vsh
  attribute vec2 mc_Entity;
  attribute vec3 at_tangent;

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 geometryNormal;
  out vec3 tangent;
  out float materialID;
  out vec3 viewPos;

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

  uniform sampler2D colortex0;
  uniform sampler2D colortex4;
  uniform sampler2D colortex5;
  uniform sampler2D depthtex0;
  uniform sampler2D depthtex1;
  uniform sampler2DShadow shadowtex0;
  uniform sampler2DShadow shadowtex1;
  uniform sampler2D shadowcolor0;

  uniform float near;
  uniform float far;
  uniform mat4 gbufferModelViewInverse;
  uniform vec3 sunPosition;
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;
  uniform mat4 gbufferProjectionInverse;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in float materialID;
  in vec3 geometryNormal;
  in vec3 tangent;
  in vec3 viewPos;

  #include "/lib/tonemap.glsl"
  #include "/lib/util.glsl"
  #include "/lib/sky.glsl"
  #include "/lib/getSunlight.glsl"

  /* DRAWBUFFERS:045 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 outNormal;
  layout(location = 2) out vec4 outLightmap;

  void main() {
    
    vec3 normal = geometryNormal;

    color = texture(gtexture, texcoord) * glcolor;
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

    bool isWater = floatCompare(materialID, 1.0);

    #ifdef NORMAL_MAPS
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding

    mat3 tbnMatrix = tbnNormalTangent(geometryNormal, tangent);
    normal = tbnMatrix * mappedNormal;
    #endif

    outNormal.rgb = encodeNormal(normal);

    outNormal.a = 0.5; // set alpha of normal to indicate translucents on this pixel

    if(isWater){ // water
      color = vec4(0.215, 0.356, 0.533, 0.75);
      outNormal.a = 1.0; // set alpha of normal to 1.0 to indicate water
    }

    if (color.a < 0.1) {
      discard;
    }
    color.rgb = gammaCorrect(color.rgb);
    outLightmap = vec4(lmcoord, 0.0, 1.0);

    vec3 playerNormal = normalize(mat3(gbufferModelViewInverse) * normal);

    float lightmapSky = lmcoord.g;
    float lightmapBlock = lmcoord.r;

    vec3 skyLight = getSky(vec3(0, 1, 0)) * SKYLIGHT_STRENGTH * lightmapSky;
    vec3 artificial = TORCH_COLOR * lightmapBlock;

    vec3 sunlightColor = getSky(SUN_VECTOR);

    float nDotL = clamp01(dot(normal, normalize(sunPosition)));
    nDotL *= step(0.01, dot(geometryNormal, normalize(sunPosition)));
    vec3 direct = nDotL * getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, sunlightColor, normal);

    color.rgb *= (skyLight + direct + artificial + vec3(AMBIENT_STRENGTH));

    
  }
#endif