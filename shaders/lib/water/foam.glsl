#ifndef WATER_FOAM_GLSL
#define WATER_FOAM_GLSL

#include "/lib/water/waveNormals.glsl"

float getFoam(float shoreDist, vec3 worldPos) {
  float foamFactor = pow2(1.0 - shoreDist / 7.0);

  vec2 foamPos = worldPos.xz;
  foamPos.x +=
    sin(frameTimeCounter) * sin(foamPos.y) * 0.5 * (1.0 - foamFactor);
  foamPos.y +=
    sin(frameTimeCounter * 2) * sin(foamPos.x / 2) * 0.2 * (1.0 - foamFactor);
  foamPos = fract(foamPos / 50);
  float foam = texture(perlinnoisetex, foamPos).r;

  foam = linearstep(0.4, 1.0, foam);

  float foamMinThreshold = 0.2; //fract(frameTimeCounter * 0.01 + sin(foamPos.x / 5));
  float foamMaxThreshold = fract(foamMinThreshold + foamFactor * 0.2);

  foam = step(foamMinThreshold, foam) * step(foam, foamMaxThreshold);
  return foam;
}

#endif // WATER_FOAM_GLSL
