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
  }
#endif