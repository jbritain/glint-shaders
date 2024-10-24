#ifndef SSGI_INCLUDE
#define SSGI_INCLUDE

#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/util/reproject.glsl"
#include "/lib/util/packing.glsl"

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

vec3 SSGI(vec3 viewPos, vec3 faceNormal){
  

  vec3 GI = vec3(0.0);

  vec3 normal = faceNormal;
  vec3 tangent;
  vec3 bitangent;

  computeFrisvadTangent(normal, tangent, bitangent);

  for(int i = 0; i < GI_SAMPLES; i++){
    // vec3 noise = interleavedGradientNoise3(floor(gl_FragCoord.xy), i + GI_SAMPLES * frameCounter);
    vec3 noise = blueNoise(texcoord, i).xyz;
    float cosTheta = sqrt(noise.x);
    float sinTheta = sqrt(1.0 - pow2(cosTheta));
    float phi = 2 * PI * noise.y;

    vec3 hemisphereNormal = vec3(
      cos(phi) * sinTheta,
      sin(phi) * sinTheta,
      cosTheta
    );



    vec3 rayDir = mat3(tangent, bitangent, normal) * hemisphereNormal;

    vec3 GIPos;
    if(!rayIntersects(viewPos + faceNormal * 0.1, rayDir, 8, noise.z, true, GIPos, true)){
      continue;
    }

    vec2 decode1z = unpack2x8F(texture(colortex1, GIPos.xy).z);
    vec3 hitFaceNormal = mat3(gbufferModelView) * decodeNormal(decode1z);

    if(dot(rayDir, hitFaceNormal) < 0.0){
      GI += texture(colortex4, GIPos.xy).rgb;
    }
  }
  
  return GI / float(GI_SAMPLES);
}

#endif