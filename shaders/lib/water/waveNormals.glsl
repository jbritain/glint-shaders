/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#ifndef WAVE_NORMALS_GLSL
#define WAVE_NORMALS_GLSL

// "Very fast procedural ocean" by afl_ext
// https://www.shadertoy.com/view/MdXyzX
// https://opensource.org/license/mit

#define DRAG_MULT 0.2 // changes how much waves pull on the water
#define WAVE_E 0.1
#define WAVE_DEPTH 0.3 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Calculates wave value and its derivative,
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  x = mod(x, 2 * PI);
  float wave = exp(sin(x) - 1.0) * 0.5;
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float waveHeight(vec2 position) {
  float wavePhaseShift = length(position) * 0.1; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 1.0; // frequency of the wave, this will change every iteration
  float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
  float weight = 1.0; // weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for (int i = 0; i < 16; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(mod(iter, 2 * PI)), cos(mod(iter, 2 * PI)));

    // calculate wave data
    vec2 res = wavedx(
      position,
      p,
      frequency,
      frameTimeCounter * timeMultiplier + wavePhaseShift
    );

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }

  // calculate and return
  return sumOfValues / sumOfWeights;
}

vec3 rotate(vec3 vector, vec3 from, vec3 to) {
  // where "from" and "to" are two unit vectors determining how far to rotate
  // adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

  float cosTheta = dot(from, to);
  if (abs(cosTheta) >= 0.9999) {
    return cosTheta < 0.0
      ? -vector
      : vector;
  }
  vec3 axis = normalize(cross(from, to));

  vec2 sc = vec2(sqrt(1.0 - cosTheta * cosTheta), cosTheta);
  return sc.y * vector +
  sc.x * cross(axis, vector) +
  (1.0 - sc.y) * dot(axis, vector) * axis;
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
// returned value is in world space
vec3 waveNormal(vec2 pos, vec3 worldFaceNormal, float heightmapFactor) {
  // if(abs(dot(worldFaceNormal, vec3(0.0, 1.0, 0.0))) <= 0.1){
  // return worldFaceNormal;
  // }

  vec2 ex = vec2(WAVE_E, 0);
  float H = waveHeight(pos.xy) * WAVE_DEPTH * heightmapFactor;

  vec3 a = vec3(pos.x, H, pos.y);
  vec3 waveNormal = normalize(
    cross(
      a -
        vec3(
          pos.x - WAVE_E,
          waveHeight(pos.xy - ex.xy) * WAVE_DEPTH * heightmapFactor,
          pos.y
        ),
      a -
        vec3(
          pos.x,
          waveHeight(pos.xy + ex.yx) * WAVE_DEPTH * heightmapFactor,
          pos.y + WAVE_E
        )
    )
  );

  // rotate to align with face normal since the normal calculation assumes a surface facing straight up
  waveNormal = rotate(waveNormal, vec3(0.0, 1.0, 0.0), worldFaceNormal);
  return normalize(waveNormal);
}

vec3 getWaterParallaxNormal(
  vec3 playerPos,
  vec3 worldNormal,
  float jitter,
  float heightmapFactor
) {
  #ifdef WATER_PARALLAX
  // we know no wave is ever more than WAVE_DEPTH above the surface
  // so we shift the ray forwards until it is WAVE_DEPTH above the surface
  float fractionalDistance;
  fractionalDistance = (abs(playerPos.y) - WAVE_DEPTH) / abs(playerPos.y);
  vec3 origin = playerPos * fractionalDistance;

  vec3 increment = (playerPos - origin) / float(WATER_PARALLAX_SAMPLES);

  bool intersect = false;

  vec3 rayPos = origin;

  rayPos += increment * jitter;

  for (int i = 0; i < WATER_PARALLAX_SAMPLES; i++) {
    float waveHeight = waveHeight(rayPos.xz + cameraPosition.xz) + playerPos.y;

    // turns out you can just build binary refinement into the loop this is goated
    bool intersect = playerPos.y < 0 == rayPos.y < waveHeight;
    if (intersect) {
      increment /= 2;
    }

    rayPos += increment * (intersect ? -1 : 1);

  }

  return waveNormal(rayPos.xz + cameraPosition.xz, worldNormal, 1.0);

  #endif

  return waveNormal(
    playerPos.xz + cameraPosition.xz,
    worldNormal,
    heightmapFactor
  );
}

#endif // WAVE_NORMALS_GLSL
