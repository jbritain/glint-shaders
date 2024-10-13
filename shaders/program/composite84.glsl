/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite84.glsl
    - DoF Blending
*/

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
  uniform sampler2D colortex1;

  uniform float near;
  uniform float far;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 texcoord;

  #include "/lib/util.glsl"

  vec3 tentFilter(sampler2D sourceTexture, vec2 coord){
    vec2 offset = 0.5 / vec2(viewWidth, viewHeight);

    vec3 usample = vec3(0.0);
    usample += texture(sourceTexture, coord + offset * vec2(1.0)).rgb;
    usample += texture(sourceTexture, coord + offset * vec2(1.0, -1.0)).rgb;
    usample += texture(sourceTexture, coord + offset * vec2(-1.0)).rgb;
    usample += texture(sourceTexture, coord + offset * vec2(-1.0, 1.0)).rgb;

    usample /= 4.0;

    return usample;
  }

  /* DRAWBUFFERS:0 */
  layout(location = 0) out vec4 color;
  

  void main() {
    vec4 bokeh = vec4(tentFilter(colortex1, texcoord / 2.0), texture(colortex1, texcoord / 2.0).a);
    color = texture(colortex0, texcoord);

    float CoC = (bokeh.a - 0.5) / 0.5;


    float DoFStrength = smoothstep(0.1, 1.0, abs(CoC));
    color.rgb = mix(color.rgb, bokeh.rgb, DoFStrength);
  }
#endif