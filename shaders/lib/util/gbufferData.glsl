#ifndef GBUFFER_DATA_INCLUDE
#define GBUFFER_DATA_INCLUDE

#include "/lib/util/packing.glsl"

void decodeGbufferData(in vec4 data1, in vec4 data2){
  vec2 decode1x = unpack2x8F(data1.x);
  vec2 decode1y = unpack2x8F(data1.y);
  vec2 decode1z = unpack2x8F(data1.z);
  vec2 decode1w = unpack2x8F(data1.w);

  vec2 decode2x = unpack2x8F(data2.x);
  vec2 decode2y = unpack2x8F(data2.y);
  vec2 decode2z = unpack2x8F(data2.z);
  vec2 decode2w = unpack2x8F(data2.w);

  albedo.rgb = vec3(decode1x.x, decode1x.y, decode1y.x);
  materialID = int(decode1y.y * 255 + 0.5) + 10000;
  if(materialID == 1000){
    materialID = 0;
  }
  faceNormal = decodeNormal(decode1z);
  lightmap = decode1w;

  mappedNormal = decodeNormal(decode2x);
  specularData = vec4(decode2y, decode2z);
}

#endif