#ifndef PARALLAX_INCLUDE
#define PARALLAX_INCLUDE

float getDepth(vec2 texcoord){
  return (1.0 - texture(normals, texcoord).a);
}

// TODO: NOT GOOD
// TODO: DEPTH WRITE AND SELF SHADOW
vec2 getParallaxTexcoord(vec2 texcoord, vec3 viewDir){
  const float minLayers = 8.0;
  const float maxLayers = 32.0;
  float layers = mix(maxLayers, minLayers, max(dot(vec3(0.0, 0.0, 1.0), viewDir), 0.0));
  const float layerDepth = rcp(layers); // depth per layer

  float currentLayerDepth = 0.0;

  vec2 P = viewDir.xy * POM_HEIGHT;
  vec2 deltaTexcoord = P * singleTexSize / layers;
  float currentDepth = getDepth(texcoord);

  while(currentLayerDepth < currentDepth){
    vec2 previousTexcoord = texcoord;
    texcoord -= deltaTexcoord;
    currentDepth = getDepth(texcoord);
    currentLayerDepth += layerDepth;
  }

  vec2 previousTexcoord = texcoord + deltaTexcoord;

  float afterDepth = currentDepth - currentLayerDepth;
  float beforeDepth = getDepth(previousTexcoord) - currentLayerDepth + layerDepth;
  float weight = afterDepth / (afterDepth - beforeDepth);
  texcoord = previousTexcoord * weight + texcoord * (1.0 - weight);

  vec2 topLeft = textureBounds.xy;
  vec2 bottomRight = textureBounds.zw;
  texcoord = topLeft + mod(texcoord - topLeft, bottomRight - topLeft);
  return texcoord;
}

#endif