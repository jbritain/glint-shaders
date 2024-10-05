#ifndef PARALLAX_INCLUDE
#define PARALLAX_INCLUDE

float getDepth(vec2 texcoord, vec2 dx, vec2 dy){
  return (1.0 - textureGrad(normals, texcoord, dx, dy).a);
}

// TODO: DEPTH WRITE AND SELF SHADOW
vec2 getParallaxTexcoord(vec2 texcoord, vec3 viewDir){
  vec2 dx = dFdx(texcoord);
  vec2 dy = dFdy(texcoord);

  float currentDepth = getDepth(texcoord, dx, dy);

  const float layers = 32.0;
  const float layerDepth = rcp(layers); // depth per layer

  vec2 topLeft = textureBounds.xy;
  vec2 bottomRight = textureBounds.zw;

  vec2 P = viewDir.xy * POM_HEIGHT;
  vec2 deltaTexcoord = -P * singleTexSize / layers;

  for(float i = 0.0; i < layers; i += 1.0){
    vec2 sampleCoord = texcoord + deltaTexcoord * i;
    sampleCoord = topLeft + mod(sampleCoord - topLeft, bottomRight - topLeft);

    float currentDepth = getDepth(sampleCoord, dx, dy);
    float currentLayerDepth = layerDepth * i;

    if(currentLayerDepth >= currentDepth){
      texcoord = sampleCoord;
      break;
    }
  }

  return texcoord;
}

#endif