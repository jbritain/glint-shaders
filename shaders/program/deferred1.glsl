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
  uniform sampler2D depthtex0;
  uniform sampler2D colortex1;
  uniform sampler2D colortex2;

  uniform sampler2DShadow shadow;
  uniform sampler2D shadowtex0;

  uniform float near;
  uniform float far;
  uniform vec3 sunPosition;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferModelView;
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;


  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/sky.glsl"
  #include "/lib/getSunlight.glsl"


  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);

    #include "/lib/screenPassUtil.glsl"

    if(!floatCompare(depth, 1.0)){
      vec3 normal = decodeNormal(texture(colortex1, texcoord).rgb);
      vec3 playerNormal = normalize(mat3(gbufferModelViewInverse) * normal);

      vec2 lightmap = texture(colortex2, texcoord).rg;

      float lightmapSky = lightmap.g;
      float lightmapBlock = lightmap.r;

      vec3 ambient = getSky(vec3(0, 1, 0)) * AMBIENT_STRENGTH * lightmapSky;
      vec3 artificial = TORCH_COLOR * lightmapBlock;

      vec3 sunlightColor = getSky(SUN_VECTOR);

      float nDotL = clamp01(dot(normal, normalize(sunPosition)));
      vec3 direct = nDotL * getSunlight(eyePlayerPos, sunlightColor, normal);

      color.rgb *= (ambient + direct + artificial);
      //color.rgb = vec3(clamp01(nDotL));
    }
    
  }
#endif