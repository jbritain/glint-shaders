/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/deferred4.glsl
    - Cloud generation
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
  uniform sampler2D colortex8;

  uniform float viewWidth;
  uniform float viewHeight;

  #include "/lib/util.glsl"

  vec3 selectiveBlur(sampler2D image, vec2 uv, vec2 resolution){
    float x = rcp(viewWidth) * 2.0;
    float y = rcp(viewHeight) * 2.0;

    vec3 blur;
    float totalWeight;
    float weight;

    vec4 e = texture(image, vec2(uv.x,     uv.y));
    weight = 4.0;
    blur += e.rgb * weight;
    totalWeight += weight;

    vec4 b = texture(image, vec2(uv.x,     uv.y + y));
    weight = 1.0 - abs(b.a - e.a) * 2.0;
    blur += b.rgb * weight;
    totalWeight += weight;

    vec4 d = texture(image, vec2(uv.x - x, uv.y));
    weight = 1.0 - abs(d.a - e.a) * 2.0;
    blur += d.rgb * weight;
    totalWeight += weight;

    vec4 f = texture(image, vec2(uv.x + x, uv.y));
    weight = 1.0 - abs(f.a - e.a) * 2.0;
    blur += f.rgb * weight;
    totalWeight += weight;

    vec4 h = texture(image, vec2(uv.x,     uv.y - y));
    weight = 1.0 - abs(h.a - e.a) * 2.0;
    blur += h.rgb * weight;
    totalWeight += weight;


    vec4 a = texture(image, vec2(uv.x - x, uv.y + y));
    weight = 1.0 - abs(a.a - e.a);
    blur += a.rgb * weight;
    totalWeight += weight;
    
    vec4 c = texture(image, vec2(uv.x + x, uv.y + y));
    weight = 1.0 - abs(c.a - e.a);
    blur += c.rgb * weight;
    totalWeight += weight;

    vec4 g = texture(image, vec2(uv.x - x, uv.y - y));
    weight = 1.0 - abs(g.a - e.a);
    blur += g.rgb * weight;
    totalWeight += weight;

    vec4 i = texture(image, vec2(uv.x + x, uv.y - y));
    weight = 1.0 - abs(i.a - e.a);
    blur += i.rgb * weight;
    totalWeight += weight;

    // usample += (b + d + f + h) * 2.0;
    // usample += (a + c + g + i);

    return blur / totalWeight;
  }

  in vec2 texcoord;



  /* DRAWBUFFERS:08 */
  layout(location = 0) out vec4 color;



  void main() {
    color = texture(colortex0, texcoord);
    color.rgb += selectiveBlur(colortex8, texcoord, vec2(viewWidth, viewHeight));
  }
#endif