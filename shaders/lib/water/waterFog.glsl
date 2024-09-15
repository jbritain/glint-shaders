#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

vec3 waterFog(vec3 color, vec3 frontPos, vec3 backPos){
  float dist = distance(frontPos, backPos);

  vec3 extinction = exp(-WATER_EXTINCTION * dist);

  color.rgb *= extinction;

  return color;
}

#endif