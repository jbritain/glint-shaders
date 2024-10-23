/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef GBUFFER_DATA_INCLUDE
#define GBUFFER_DATA_INCLUDE

#include "/lib/util/packing.glsl"
#include "/lib/util/material.glsl"

struct GbufferData {
  Material material;
  int materialID;
  vec3 faceNormal;
  vec2 lightmap;
  vec3 mappedNormal;
};

void decodeGbufferData(in vec4 data1, in vec4 data2, out GbufferData data){
  vec2 decode1x = unpack2x8F(data1.x);
  vec2 decode1y = unpack2x8F(data1.y);
  vec2 decode1z = unpack2x8F(data1.z);
  vec2 decode1w = unpack2x8F(data1.w);

  vec2 decode2x = unpack2x8F(data2.x);
  vec2 decode2y = unpack2x8F(data2.y);
  vec2 decode2z = unpack2x8F(data2.z);
  vec2 decode2w = unpack2x8F(data2.w);

  data.material = materialFromSpecularMap(vec3(decode1x.x, decode1x.y, decode1y.x), vec4(decode2y, decode2z));

  data.materialID = int(decode1y.y * 255 + 0.5) + 10000;
  if(data.materialID == 10000){
    data.materialID = 0;
  }
  data.faceNormal = mat3(gbufferModelView) * decodeNormal(decode1z);
  data.lightmap = decode1w;

  data.mappedNormal = mat3(gbufferModelView) * decodeNormal(decode2x);
  
}

#endif