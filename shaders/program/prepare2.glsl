/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3
    
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/prepare2.glsl
    - Sky irradiance map
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
  uniform sampler2D colortex9;
  uniform sampler2D colortex12;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowProjection;

  uniform vec3 sunPosition;
  uniform vec3 shadowLightPosition;
  uniform vec4 lightningBoltPosition;

  uniform int worldTime;
  uniform int worldDay;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform float far;
  uniform float wetness;
  uniform float thunderStrength;
  uniform int isEyeInWater;

  uniform float viewWidth;
  uniform float viewHeight;

  uniform int frameCounter;

  uniform ivec2 eyeBrightnessSmooth;

  uniform bool hasSkylight;

  uniform sampler2D noisetex;

  in vec2 texcoord;

  /* RENDERTARGETS: 12 */
  layout(location = 0) out vec3 color;

  #include "/lib/util.glsl"
  #include "/lib/util/uvmap.glsl"
  #include "/lib/textures/blueNoise.glsl"

  // from bliss, which means it's probably by chocapic
  // https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
  void computeFrisvadTangent(in vec3 n, out vec3 f, out vec3 r){
    if(n.z < -0.9) {
      f = vec3(0.,-1,0);
      r = vec3(-1, 0, 0);
    } else {
      float a = 1./(1.+n.z);
      float b = -n.x*n.y*a;
      f = vec3(1. - n.x*n.x*a, b, -n.x) ;
      r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
  }

  void main() {
    vec3 oldColor = texture(colortex12, texcoord).rgb;

    const int samples = 8;

    vec3 dir = unmapSphere(texcoord);
    vec3 tangent;
    vec3 bitangent;
    computeFrisvadTangent(dir, tangent, bitangent);

    mat3 tbd = mat3(tangent, bitangent, dir);

    for(int i = 0; i < samples; i++){
      vec2 noise = i % 2 == 1 ? blueNoise(texcoord, i % 2 + frameCounter * samples).xy : blueNoise(texcoord, i % 2 + frameCounter * samples).yz;

      float cosTheta = sqrt(noise.x);
      float sinTheta = sqrt(1.0 - noise.x); // thanks veka
      float phi = 2 * PI * noise.y;

      vec3 hemisphereDir = vec3(
        cos(phi) * sinTheta,
        sin(phi) * sinTheta,
        cosTheta
      );

      vec3 sampleDir = tbd * hemisphereDir;

      vec2 sampleCoord = mapSphere(sampleDir);

      vec3 skySample = texture(colortex9, sampleCoord).rgb / (cosTheta / PI);
    }

    color.rgb /= samples;

    if(frameCounter > 1){
      color.rgb = mix(oldColor, color.rgb, 0.1);
    }


    show(color.rgb);
  }
#endif