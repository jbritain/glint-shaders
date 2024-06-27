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

  uniform float near;
  uniform float far;
  uniform vec3 sunPosition;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelViewInverse;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/sky.glsl"


  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    color = texture(colortex0, texcoord);

    #include "/lib/screenPassUtil.glsl"

    if(!floatCompare(depth, 1.0)){
      vec3 normal = decodeNormal(texture(colortex1, texcoord).rgb);
      vec3 playerNormal = normalize(mat3(gbufferModelViewInverse) * normal);

      vec2 lightmap = texture(colortex2, texcoord).rg;

      float lightmapSky = lightmap.r;
      float lightmapBlock = lightmap.g;

      vec3 ambient = getSky(playerNormal) * AMBIENT_STRENGTH;
      vec3 direct = dot(normal, normalize(sunPosition)) * getSky(SUN_VECTOR);

      color.rgb *= (ambient + direct);
    }
    
  }
#endif