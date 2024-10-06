#ifndef DH_INCLUDE
#define DH_INCLUDE

bool DH_MASK = false;

#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
uniform sampler2D dhDepthTex1;

uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;

void dhOverride(inout float depth, inout vec3 viewPos, bool opaque){
  if(depth != 1.0) return;

  depth = opaque ? texture(dhDepthTex1, texcoord).r : texture(dhDepthTex0, texcoord).r;

  if(depth == 1.0) return;

  DH_MASK = true;

  vec3 screenPos = vec3(texcoord, depth);

  screenPos *= 2.0; screenPos -= 1.0; // ndcPos
  vec4 homPos = dhProjectionInverse * vec4(screenPos, 1.0);
  viewPos = homPos.xyz / homPos.w;
}

#else

void dhOverride(inout float depth, inout vec3 viewPos, bool opaque){
  return;
}

#endif

#endif