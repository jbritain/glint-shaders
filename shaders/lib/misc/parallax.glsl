#ifndef PARALLAX_INCLUDE
#define PARALLAX_INCLUDE

#include "/lib/util/spaceConversions.glsl"
#include "/lib/textures/blueNoise.glsl"

float getDepth(vec2 texcoord, vec2 dx, vec2 dy){
  return (1.0 - textureGrad(normals, texcoord, dx, dy).a);
}

vec2 localToAtlas(vec2 texcoord){
  return (mod(texcoord, 1.0) * singleTexSize) + textureBounds.xy;
}

vec2 atlasToLocal(vec2 texcoord){
  return (texcoord - textureBounds.xy) / singleTexSize;
}

vec2 getParallaxTexcoord(vec2 texcoord, vec3 viewPos, mat3 tbnMatrix, out vec3 previousPos, vec2 dx, vec2 dy, float jitter){
  vec3 viewDir = normalize(-viewPos) * tbnMatrix;

  float currentDepth = getDepth(texcoord, dx, dy);

  const float layerDepth = rcp(POM_SAMPLES); // depth per layer

  vec3 rayStep = vec3(viewDir.xy * rcp(-viewDir.z) * POM_HEIGHT, 1.0) * layerDepth;
  vec3 pos = vec3(atlasToLocal(texcoord), 0.0);
  // pos += rayStep * jitter;

  float depth = getDepth(texcoord, dx, dy);
  if(depth < rcp(255.0)){
    previousPos = pos;
    return texcoord;
  }

  while(depth - pos.z > rcp(255.0)){
    previousPos = pos;
    depth = getDepth(localToAtlas(pos.xy), dx, dy);
    pos += rayStep;
  }

  return localToAtlas(pos.xy);
}

bool getParallaxShadow(vec3 pos, mat3 tbnMatrix, vec2 dx, vec2 dy, float jitter){
  vec3 lightDir = normalize(shadowLightPosition) * tbnMatrix;
  vec3 rayStep = vec3(lightDir.xy * rcp(lightDir.z) * POM_HEIGHT, -1.0) * pos.z * rcp(PARALLAX_SHADOW_SAMPLES);

  pos += rayStep * jitter;

  for(int i = 0; i < PARALLAX_SHADOW_SAMPLES; ++i){
    pos += rayStep;
    if(getDepth(localToAtlas(pos.xy), dx, dy) < pos.z) return true;
  }

  return false;
}

#endif