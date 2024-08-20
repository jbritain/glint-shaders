#include "/lib/settings.glsl"

#ifdef vsh

  attribute vec4 mc_Entity;
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;
  uniform vec3 sunPosition;
  uniform float near;
  uniform float far;

  varying vec2 lmcoord;
  varying vec2 texcoord;
  varying vec4 glcolor;

  #include "/lib/util.glsl"
  #include "/lib/lighting/shadowBias.glsl"

  void main(){
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    gl_Position = ftransform();
    gl_Position.xyz = distort(gl_Position.xyz);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh
  uniform sampler2D lightmap;
  uniform sampler2D gtexture;

  varying vec2 lmcoord;
  varying vec2 texcoord;
  varying vec4 glcolor;

  void main(){
    vec4 color = texture(gtexture, texcoord) * glcolor;

	  gl_FragData[0] = color;
  }
  
#endif