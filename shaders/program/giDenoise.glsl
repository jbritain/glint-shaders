/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/giDenoise.glsl
    - denoises GI with a trous wavelet filter

    **THIS PROGRAM RUNS MULTIPLE TIMES**
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
  const bool colortex10MipmapEnabled = true;

  #include "/lib/util/packing.glsl"

  in vec2 texcoord;

  uniform sampler2D colortex10;
  uniform sampler2D colortex1;
  uniform sampler2D depthtex0;

  uniform float viewWidth;
  uniform float viewHeight;

  #define A_TROUS_SAMPLES 25
  #define A_TROUS_C_PHI 3.3
  #define A_TROUS_P_PHI 5.5

  const float kernel[A_TROUS_SAMPLES] = float[](
    1.0, 4.0, 7.0, 4.0, 1.0,
    1.0, 16.0, 26.0, 16.0, 4.0,
    7.0, 26.0, 41.0, 26.0, 7.0,
    4.0, 16.0, 26.0, 16.0, 4.0,
    1.0, 4.0, 7.0, 4.0, 1.0
  );

  const ivec2 offsets[A_TROUS_SAMPLES] = ivec2[](
    ivec2(-2, -2), ivec2(-1, -2), ivec2(0, -2), ivec2(1, -2), ivec2(2, -2),
    ivec2(-2, -1), ivec2(-1, -1), ivec2(0, -1), ivec2(1, -1), ivec2(2, -1),
    ivec2(-2,  0), ivec2(-1,  0), ivec2(0,  0), ivec2(1,  0), ivec2(2,  0),
    ivec2(-2,  1), ivec2(-1,  1), ivec2(0,  1), ivec2(1,  1), ivec2(2,  1),
    ivec2(-2,  2), ivec2(-1,  2), ivec2(0,  2), ivec2(1,  2), ivec2(2,  2)
  );

  vec3 getNormal(ivec2 uv){
    return decodeNormal(unpack2x8F(texelFetch(colortex1, uv, 0).z));
  }

  /* RENDERTARGETS: 10 */
  layout(location = 0) out vec4 outGI;

  void main(){
    outGI.a = texture(colortex10, texcoord).a;

    if(max3(textureLod(colortex10, texcoord, 4).rgb) < 1e-6){
      outGI.rgb = vec3(0.0);
      return;
    }

    vec3 sum = vec3(0.0);

    ivec2 tx = ivec2(texcoord * vec2(viewWidth, viewHeight));
    vec4 cval = texelFetch(colortex10, tx, 0);
    
    vec3 nval = getNormal(tx);
    float pval = texelFetch(depthtex0, tx, 0).r;

    float cumW = 0.0;

    for(int i = 0; i < A_TROUS_SAMPLES; i++){
      ivec2 uv = tx + offsets[i];

      float ptmp = texelFetch(depthtex0, uv, 0).r;
      vec3 ntmp = getNormal(uv);

      float nW = dot(nval, ntmp);
      if(nW < 1e-3){
        continue;
      }

      vec4 ctmp = texelFetch(colortex10, uv, 0);
      vec3 t = cval.rgb - ctmp.rgb;

      float cW = max0(min(1.0 - dot(t, t) / A_TROUS_C_PHI, 1.0));
      float pt = abs(pval - ptmp);
      float pW = max0(min(1.0 - pt / A_TROUS_P_PHI, 1.0));
      float weight = cW * pW * nW * kernel[i];

      sum += ctmp.rgb * weight;
      cumW += weight;
    }
    outGI.rgb = sum / cumW;
  }

#endif