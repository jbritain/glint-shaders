/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_skybasic.glsl
    - Stars
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec4 starData;

  void main() {
    gl_Position = ftransform();
	  starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  in vec4 starData;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"

  /* DRAWBUFFERS:3 */
  layout(location = 0) out vec4 color;

  void main() {

    if(starData.a < 0.5){
      discard;
      return;
    }

    color = starData;
    // color.rgb *= vec3(4.0, 4.0, 5.0) * 20;
    color.rgb = invGammaCorrect(color.rgb);
  }
#endif