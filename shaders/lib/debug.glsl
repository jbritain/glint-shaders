// bruce could never begin to imagine

#ifndef DEBUG_INCLUDE
#define DEBUG_INCLUDE

#ifdef DEBUG_ENABLE
layout (rgba8) uniform image2D debug;

void show(vec4 x){
  imageStore(debug, ivec2(gl_FragCoord.xy), x);
}

void show(vec3 x){
  imageStore(debug, ivec2(gl_FragCoord.xy), vec4(x, 1.0));
}

void show(vec2 x){
  imageStore(debug, ivec2(gl_FragCoord.xy), vec4(x, 0.0, 1.0));
}

void show(float x){
  imageStore(debug, ivec2(gl_FragCoord.xy), vec4(vec3(x), 1.0));
}

void show(bool x){
  show(float(x));
}

#else
void show(vec4 x){
}

void show(vec3 x){
}

void show(vec2 x){
}

void show(float x){
}

void show(bool x){
}
#endif

#endif