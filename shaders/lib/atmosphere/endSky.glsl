#ifndef END_SKY_INCLUDE
#define END_SKY_INCLUDE

vec3 endSky(vec3 dir, bool includeSun){
  return vec3(0.5, 0.4, 1.0) * clamp01(dot(dir, lightVector) * 0.5 + 0.5) * 0.01 + 
  step(0.9989, dot(dir, lightVector)) * step(dot(dir, lightVector), 0.999) * 100 * float(includeSun);
}

#endif