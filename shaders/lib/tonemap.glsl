vec3 gammaCorrect(vec3 col){
  return pow(col, vec3(2.2));
}

vec3 invGammaCorrect(vec3 col){
  return pow(col, vec3(1/2.2));
}

vec3 jodieReinhardTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c / (c + 1.0);

    return mix(c / (l + 1.0), tc, tc);
}

#define tonemap jodieReinhardTonemap