/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
layout(local_size_x = 8, local_size_y = 16) in;
const ivec3 workGroups = ivec3(32, 16, 1);

layout(r32ui) uniform uimage2D shadowImportanceMap;

#include "/lib/common.glsl"

void main() {
  ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
  vec2 texcoord = vec2(texelCoord + 0.5) / 256;
  
  vec4 neighbouringDepths = textureGather(undistortedShadowMapTex, texcoord);
  float depth = texelFetch(undistortedShadowMapTex, texelCoord, 0).r;

  float minDepth = minVec4(neighbouringDepths);
  float maxDepth = maxVec4(neighbouringDepths);

  if(depth == 0 || (maxDepth - minDepth < 1.0)){
    imageStore(shadowImportanceMap, texelCoord, uvec4(0));
    return;
  }

  vec3 shadowViewPos = screenSpaceToViewSpaceOrtho(vec3((texelCoord + 0.5) / 256.0, depth), shadowProjectionInverse);
  vec3 playerPos = transformView(shadowViewPos, shadowModelViewInverse);
  vec3 viewPos = transformView(playerPos, gbufferModelView);
  vec3 screenPos = viewSpaceToScreenSpace(viewPos);

  uint weight = 0;//uint((clamp01(-viewPos.z / far)) * 1000);

  // imageAtomicAdd(shadowImportanceMap, texelCoord, weight);
}
