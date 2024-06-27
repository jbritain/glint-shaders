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


  #include "/lib/util.glsl"
  #include "/lib/sky.glsl"
  #include "/lib/getSunlight.glsl"
  

  in vec2 texcoord;

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);
    #include "/lib/screenPassUtil.glsl"

    float transparentDepth = linearizeDepth(texture(depthtex1, texcoord).r);
    float opaqueDepth = linearizeDepth(texture(depthtex0, texcoord).r);

    vec4 tex4 = texture(colortex4, texcoord);
    vec3 normal = decodeNormal(tex4.rgb);
    bool isWater = tex4.a > 0.7;

    if(tex4.a > 0){ // don't operate on opaque pixels
      vec3 playerNormal = normalize(mat3(gbufferModelViewInverse) * normal);

      vec2 lightmap = texture(colortex5, texcoord).rg;

      float lightmapSky = lightmap.g;
      float lightmapBlock = lightmap.r;

      vec3 skyLight = getSky(vec3(0, 1, 0)) * SKYLIGHT_STRENGTH * lightmapSky;
      vec3 artificial = TORCH_COLOR * lightmapBlock;

      vec3 sunlightColor = getSky(SUN_VECTOR);

      float nDotL = clamp01(dot(normal, normalize(sunPosition)));
      vec3 direct = nDotL * getSunlight(eyePlayerPos + gbufferModelViewInverse[3].xyz, sunlightColor, normal);

      color.rgb *= (skyLight + direct + artificial + vec3(AMBIENT_STRENGTH));
      
    }

    
  }
#endif