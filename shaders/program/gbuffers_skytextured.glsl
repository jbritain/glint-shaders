/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_skytextured.glsl
    - Moon
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;
  out vec4 glcolor;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform float alphaTestRef;

  uniform sampler2D gtexture;

  in vec2 texcoord;
  in vec4 glcolor;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"

  /* DRAWBUFFERS:3 */
  layout(location = 0) out vec4 color;

  void main() {

    // remove bloom around moon by checking saturation since it's coloured while the moon is greyscale
    color = texture(gtexture, texcoord) * glcolor;
    vec3 color2 = hsv(color.rgb);

    if(color2.g > 0.5){
      discard;
    }

    if (color.a < 0.1) {
      discard;
    }


    // color.rgb *= vec3(4.0, 4.0, 5.0);
    color.rgb *= (0.5, 0.5, 1.0);
    color.rgb = gammaCorrect(color.rgb);
  }
#endif