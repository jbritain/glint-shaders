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
const vec2 workGroupsRender = vec2(0.5, 0.5);

layout(r32ui) uniform uimage2D shadowImportanceMap;

#include "/lib/common.glsl"
#include "/lib/material/material.glsl"

void main() {
  ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
  if (any(greaterThanEqual(texelCoord, ivec2(resolution)))) {
    return;
  }

  vec2 texcoord = texelCoord / (resolution * workGroupsRender);
  float depth0 = textureLod(depthtex0, texcoord, 0).r;
  float depth1 = textureLod(depthtex2, texcoord, 0).r;
  Gbuffer gbuffer = unpackGbuffer(texture(colortex1, texcoord).rgb);


  if(depth0 == 1.0){
    return;
  }


  for(int i = 0; i < (depth0 == depth1 ? 1 : 2); i++){
    float depth = ((i == 0) ? depth0 : depth1);
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    uint weight = 1000;
    weight += uint(10 / (1.0 - depth));
    vec3 shadowViewPos = transformView(
      transformView(viewPos, gbufferModelViewInverse),
      shadowModelView
    );
    vec3 shadowScreenPos = viewSpaceToScreenSpaceOrtho(
      shadowViewPos,
      shadowProjection
    );
    imageAtomicAdd(shadowImportanceMap, ivec2(shadowScreenPos.xy * 256), weight);
  }

  





  
}
