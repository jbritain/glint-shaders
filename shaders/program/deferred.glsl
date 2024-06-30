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

  uniform float near;
  uniform float far;
  uniform vec3 sunPosition;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelViewInverse;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/tonemap.glsl"
  #include "/lib/sky.glsl"

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;

  void main() {
    

    color = texture(colortex0, texcoord);

    #include "/lib/screenPassUtil.glsl"

    if(floatCompare(depth, 1.0)){ // is sky
      color.rgb = getSky(normalize(eyePlayerPos), true); // replace with own sky
    } else {
      // color.rgb = getAtmosphere(color.rgb, eyePlayerPos);
    }
  }
#endif