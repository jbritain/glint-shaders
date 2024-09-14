#ifndef SWAY_INCLUDE
#define SWAY_INCLUDE

#include "/lib/util/materialIDs.glsl"

vec3 getWave(vec3 pos){
  float magnitude = 0.1;

  float d0 = sin(worldTimeCounter);
  float d1 = sin(worldTimeCounter * 0.5);
  float d2 = sin(worldTimeCounter * 0.25);

  vec3 wave;
  wave.x = sin(0.2 + d0 + d1 - pos.x + pos.y + pos.z) * magnitude;
  wave.y = sin(0.05 + d1 + d2 + pos.x - pos.y + pos.z) * magnitude * 0.2;
  wave.z = sin(0.4 + d2 + d0 + pos.x + pos.y - pos.z) * magnitude;

  return wave;
}

vec3 upperSway(vec3 pos, vec3 midblock){ // top halves of double high plants
float waveMult = (1.0 - smoothstep(-64, 64, midblock.y)) * 0.5 + 0.5;
  return pos + getWave(pos) * waveMult;
}

vec3 lowerSway(vec3 pos, vec3 midblock){ // bottom halves of double high plants
  float waveMult = (1.0 - smoothstep(-64, 64, midblock.y)) * 0.5;

  return pos + getWave(pos) * waveMult;
}

vec3 hangingSway(vec3 pos, vec3 midblock){ // stuff hanging from a block
  float waveMult = smoothstep(-64, 64, midblock.y);
  return pos + getWave(pos + midblock / 64) * waveMult;
}

vec3 floatingSway(vec3 pos){ // stuff on the water
  return pos + getWave(pos * vec3(1.0, 1.0, 0.0));
}

vec3 fullSway(vec3 pos){ // leaves, mainly
  return pos + getWave(pos);
}

vec3 getSway(int materialID, vec3 pos, vec3 midblock){
  switch(materialSwayType(materialID).value){
    case 1:
      return upperSway(pos, midblock);
    case 2:
      return lowerSway(pos, midblock);
    case 3:
      return hangingSway(pos, midblock);
    case 4:
      return floatingSway(pos);
    case 5:
      return fullSway(pos);
    default:
      return pos;
  }
}

#endif