#ifndef CLOUD_NOISE_INCLUDE
#define CLOUD_NOISE_INCLUDE

uniform sampler3D cloudshapenoisetex;
uniform sampler3D clouderosionnoisetex;

// one 2D slice is a 128 by 128 image
#define CLOUD_SHAPE_TILE_SIZE 128
#define CLOUD_EROSION_TILE_SIZE 32

vec4 cloudShapeNoiseSample(vec3 texcoord){
  vec3 texelcoord = vec3(mod(texcoord, 1.0) * CLOUD_SHAPE_TILE_SIZE);
  // texelcoord = texelcoord.xzy;

  // texelcoord.z = round(texelcoord.z);
  
  // texelcoord.x += texelcoord.z * CLOUD_SHAPE_TILE_SIZE; // offset by z slices

  return texture(cloudshapenoisetex, texelcoord.xyz / CLOUD_SHAPE_TILE_SIZE);
}

vec4 cloudErosionNoiseSample(vec3 texcoord){
  vec3 texelcoord = vec3(mod(texcoord, 1.0) * CLOUD_EROSION_TILE_SIZE);
  // texelcoord = texelcoord.xzy;

  // texelcoord.z = round(texelcoord.z);
  
  // texelcoord.x += texelcoord.z * CLOUD_EROSION_TILE_SIZE; // offset by z slices

  return texture(clouderosionnoisetex, texelcoord.xyz / CLOUD_EROSION_TILE_SIZE);
}

#endif