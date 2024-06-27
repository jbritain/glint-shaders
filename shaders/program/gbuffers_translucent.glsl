#include "/lib/settings.glsl"

#ifdef vsh
  attribute vec2 mc_Entity;

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out vec3 normal;
  out float materialID;

  void main() {
    gl_Position = ftransform();
    materialID = mc_Entity.x;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh
  uniform sampler2D lightmap;
  uniform sampler2D gtexture;

  uniform float far;
  uniform float near;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in float materialID;
  in vec3 normal;

  #include "/lib/tonemap.glsl"
  #include "/lib/util.glsl"

  /* DRAWBUFFERS:045 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 outNormal;
  layout(location = 2) out vec4 outLightmap;

  void main() {
    

    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);

    bool isWater = floatCompare(materialID, 1.0);

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
  }
#endif