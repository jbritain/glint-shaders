// "Fast Improved 2D Perlin Noise" by TheTurk
// https://www.shadertoy.com/view/NlSGDz

#ifndef PERLIN_NOISE_GLSL
#define PERLIN_NOISE_GLSL

// fast high-quality hash https://www.shadertoy.com/view/wfVczm
uint hash(uvec2 key, uint seed) {
  uvec2 k = key;
  k *= 0x27d4eb2fu;
  k ^= k >> 16;
  k *= 0x85ebca77u;
  uint h = seed;
  h ^= k.x;
  h ^= h >> 16;
  h *= 0x9e3779b1u;
  h ^= k.y;
  h ^= h >> 16;
  h *= 0x9e3779b1u;
  h ^= h >> 16;
  h *= 0xed5ad4bbu;
  h ^= h >> 16;
  return h;
}

// generates a distinct seed for each octave
// that will behave like a 3rd coordinate
// when mixed into the final hash
uint hash(uint key, uint seed) {
  uint k = key;
  k *= 0x27d4eb2fu;
  k ^= k >> 16;
  k *= 0x85ebca77u;
  uint h = seed;
  h ^= k;
  h ^= h >> 16;
  h *= 0x9e3779b1u;
  return h;
}

vec2 gradient(uint h) {
  const vec2 gradients[4] = vec2[4](
    vec2(1.0, 1.0),
    vec2(-1.0, 1.0),
    vec2(1.0, -1.0),
    vec2(-1.0, -1.0)
  );
  return gradients[int(h & 3u)];
}

float interpolate(
  float value1,
  float value2,
  float value3,
  float value4,
  vec2 t
) {
  return mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y);
}

vec2 fade(vec2 t) {
  // 6t^5 - 15t^4 + 10t^3
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise(vec2 position, uint seed) {
  vec2 floorPosition = floor(position);
  vec2 fractPosition = position - floorPosition;
  uvec2 cellCoordinates = uvec2(ivec2(floorPosition));
  float value1 = dot(gradient(hash(cellCoordinates, seed)), fractPosition);
  float value2 = dot(
    gradient(hash(cellCoordinates + uvec2(1, 0), seed)),
    fractPosition - vec2(1.0, 0.0)
  );
  float value3 = dot(
    gradient(hash(cellCoordinates + uvec2(0, 1), seed)),
    fractPosition - vec2(0.0, 1.0)
  );
  float value4 = dot(
    gradient(hash(cellCoordinates + uvec2(1, 1), seed)),
    fractPosition - vec2(1.0, 1.0)
  );
  return interpolate(value1, value2, value3, value4, fade(fractPosition));
}

float perlinNoise(
  vec2 position,
  int octaveCount,
  float persistence,
  float lacunarity,
  uint seed
) {
  float value = 0.0;
  float amplitude = 1.0;
  for (int i = 0; i < octaveCount; i++) {
    uint s = hash(uint(i), seed);
    value += perlinNoise(position, s) * amplitude;
    amplitude *= persistence;
    position *= lacunarity;
  }
  return value;
}

vec2 curl(vec2 pos) {
  const float eps = rcp(maxVec2(textureSize(perlinnoisetex, 0)));

  float n1 = texture(perlinnoisetex, vec2(pos.x + eps, pos.y)).r;
  float n2 = texture(perlinnoisetex, vec2(pos.x - eps, pos.y)).r;

  float a = (n1 - n2) / (2.0 * eps);

  n1 = texture(perlinnoisetex, vec2(pos.x, pos.y + eps)).r;
  n2 = texture(perlinnoisetex, vec2(pos.x, pos.y - eps)).r;

  float b = (n1 - n2) / (2.0 * eps);

  return vec2(b, -a);
}

#endif
