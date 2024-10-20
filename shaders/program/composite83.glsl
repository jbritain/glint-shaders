/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite83.glsl
    - DoF Blur
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
  #include "/lib/util/noise.glsl"

  const int kernelSampleCount = 22;
	const vec2 kernel[kernelSampleCount] = vec2[](
    vec2(0, 0),
    vec2(0.53333336, 0),
    vec2(0.3325279, 0.4169768),
    vec2(-0.11867785, 0.5199616),
    vec2(-0.48051673, 0.2314047),
    vec2(-0.48051673, -0.23140468),
    vec2(-0.11867763, -0.51996166),
    vec2(0.33252785, -0.4169769),
    vec2(1, 0),
    vec2(0.90096885, 0.43388376),
    vec2(0.6234898, 0.7818315),
    vec2(0.22252098, 0.9749279),
    vec2(-0.22252095, 0.9749279),
    vec2(-0.62349, 0.7818314),
    vec2(-0.90096885, 0.43388382),
    vec2(-1, 0),
    vec2(-0.90096885, -0.43388376),
    vec2(-0.6234896, -0.7818316),
    vec2(-0.22252055, -0.974928),
    vec2(0.2225215, -0.9749278),
    vec2(0.6234897, -0.7818316),
    vec2(0.90096885, -0.43388376)
  );

    // gets the 'most extreme' value
  float extremeFilter(sampler2D sourceTexture, vec2 coord){
    vec4 vals = textureGather(colortex1, coord, 3);

    float extremeVal = vals[0];

    for(int i = 1; i < 3; i++){
      if(abs(vals[i]) > abs(extremeVal)){
        extremeVal = vals[i];
      }
    }

    return extremeVal;
  }

  /* DRAWBUFFERS:1 */
  layout(location = 0) out vec4 bokeh;

  void main() {
    vec2 texcoord = texcoord * 2.0; // run at half res
    if(clamp01(texcoord) != texcoord) discard;

    bokeh.a = texture(colortex1, texcoord).a;

    float CoC = (bokeh.a - 0.5) / 0.5;

    const float radius = mix(0.0, 4.0, abs(CoC)); // pixels

    vec2 sampleRadius = radius / vec2(viewWidth, viewHeight);

    int samples = 0;

    for (int i = 0; i < kernelSampleCount; i++){
      vec2 offset = kernel[i] * sampleRadius;
      if(clamp01(texcoord + offset) != texcoord + offset){
        offset = vec2(0.0);
      }
      vec3 bokehSample = texture(colortex0, texcoord + offset).rgb;
      float sampleCoC = (texture(colortex1, texcoord + offset).a - 0.5) / 0.5;

      if(sign(sampleCoC) == sign(CoC)){
        bokeh.rgb += bokehSample;
        samples++;
      }      
    }

    bokeh.rgb /= float(samples);
  }
#endif