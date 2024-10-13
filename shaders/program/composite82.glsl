/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/composite82.glsl
    - DoF Circle of Confusion Calculation
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
  uniform sampler2D depthtex0;
  uniform float centerDepthSmooth;

  uniform float near;
  uniform float far;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferProjection;

  uniform mat4 gbufferModelViewInverse;

  in vec2 texcoord;

  #include "/lib/util.glsl"
  #include "/lib/util/spaceConversions.glsl"

  float tentFilter(sampler2D sourceTexture, vec2 coord){
    vec2 offset = 0.5 / vec2(viewWidth, viewHeight);

    float usample = 0.0;
    usample += texture(sourceTexture, coord + offset * vec2(1.0)).r;
    usample += texture(sourceTexture, coord + offset * vec2(1.0, -1.0)).r;
    usample += texture(sourceTexture, coord + offset * vec2(-1.0)).r;
    usample += texture(sourceTexture, coord + offset * vec2(-1.0, 1.0)).r;

    usample /= 4.0;

    return usample;
  }

  /* DRAWBUFFERS:1 */
  layout(location = 0) out vec4 circleOfConfusion;

  void main() {
    float depth = tentFilter(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

    float dist = viewPos.z;

    const float tiltAngle = PI * TILT_ANGLE/180;

    #ifdef TILT_SHIFT
    dist = dist / cos(tiltAngle) + (viewPos.y * sin(tiltAngle)) / cos(tiltAngle);
    #endif

    float focusDist = screenSpaceToViewSpace(centerDepthSmooth);
    float CoC = clamp(1.0 - focusDist / dist, -1.0, 1.0);

    circleOfConfusion.rgb = vec3(0.0);
    circleOfConfusion.a = CoC * 0.5 + 0.5;
  }
#endif