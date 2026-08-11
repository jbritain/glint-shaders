#ifndef RAINBOWS_GLSL
#define RAINBOWS_GLSL

#define RAINBOW_DISTANCE 200

vec3 getRainbow(vec3 viewPos) {
  float VoL = dot(normalize(viewPos), lightDir);

  if (length(viewPos) < RAINBOW_DISTANCE) {
    return vec3(0.0);
  }

  float angle = acos(-VoL) * 180 / PI;

  float h = (1.0 - linearstep(40.6, 42.5, angle)) * 0.7;
  const float s = 1.0;
  float v =
    smoothstep(40.2, 40.6, angle) * (1.0 - smoothstep(42.5, 42.9, angle));

  return rgb(vec3(h, s, v)) *
  sunlightColor *
  0.01 *
  clamp01((wetness - rainStrength) * 10);

  return vec3(0.0);
}

#endif // RAINBOWS_GLSL
