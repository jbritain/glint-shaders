#ifndef END_SKY_INCLUDE
#define END_SKY_INCLUDE

vec3 endSky(vec3 dir){
  return vec3(0.5, 0.4, 1.0) * clamp01(dot(dir, lightVector) * 0.5 + 0.5) * 0.2 + 
  step(0.999, dot(dir, lightVector)) * 100;
}

#endif