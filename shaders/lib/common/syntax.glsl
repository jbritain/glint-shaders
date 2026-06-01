#ifndef SYNTAX_GLSL
#define SYNTAX_GLSL

const float PI = 3.14159265358;
const float TAU = PI * 2.0;

#define discard discard;return

// macro wizardry by BruceKnowsHow
#define DEFINE_genFType(func)                                                  \
  func ( float ) func ( vec2 ) func ( vec3 ) func ( vec4 )
#define DEFINE_genVType(func) func ( vec2 ) func ( vec3 ) func ( vec4 )
#define DEFINE_genDType(func)                                                  \
  func ( double ) func ( dvec2 ) func ( dvec3 ) func ( dvec4 )
#define DEFINE_genIType(func)                                                  \
  func ( int ) func ( ivec2 ) func ( ivec3 ) func ( ivec4 )
#define DEFINE_genUType(func)                                                  \
  func ( uint ) func ( uvec2 ) func ( uvec3 ) func ( uvec4 )
#define DEFINE_genBType(func)                                                  \
  func ( bool ) func ( bvec2 ) func ( bvec3 ) func ( bvec4 )

#define rcp_(type)                                                             \
  type rcp(type x) {                                                           \
    return 1.0 / x;                                                            \
  }
#define pow2_(type)                                                            \
  type pow2(type x) {                                                          \
    return x * x;                                                              \
  }
#define pow3_(type)                                                            \
  type pow3(type x) {                                                          \
    return x * x * x;                                                          \
  }
#define pow4_(type)                                                            \
  type pow4(type x) {                                                          \
    x *= x;                                                                    \
    return x * x;                                                              \
  }
#define pow5_(type)                                                            \
  type pow5(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x;                                                        \
  }
#define pow6_(type)                                                            \
  type pow6(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x2;                                                       \
  }
#define pow7_(type)                                                            \
  type pow7(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x2 * x;                                                   \
  }
#define pow8_(type)                                                            \
  type pow8(type x) {                                                          \
    x *= x;                                                                    \
    x *= x;                                                                    \
    return x * x;                                                              \
  }

DEFINE_genFType(rcp_)
DEFINE_genFType(pow2_)
DEFINE_genFType(pow3_)
DEFINE_genFType(pow4_)
DEFINE_genFType(pow5_)
DEFINE_genFType(pow6_)
DEFINE_genFType(pow7_)
DEFINE_genFType(pow8_)

#define max0(x) max(x, 0.0)
#define max1(x) max(x, 1.0)
#define min0(x) min(x, 0.0)
#define min1(x) min(x, 1.0)

#define min3(x, y, z) min(x, min(y, z))
#define min4(x, y, z, w) min(min(x, y), min(z, w))

// TODO: this is not optimal
#define minVec2(v) min((v).x, (v).y)
#define minVec3(v) min((v).x, min((v).y, (v).z))
#define minVec4(v) min(min((v).x, (v).y), min((v).z, (v).w))

#define max3(x, y, z) max(x, max(y, z))
#define max4(x, y, z, w) max(max(x, y), max(z, w))

#define maxVec2(v) max((v).x, (v).y)
#define maxVec3(v) max((v).x, max((v).y, (v).z))
#define maxVec4(v) max(max((v).x, (v).y), max((v).z, (v).w))

#define sumVec2(v) ((v).x + (v).y)
#define sumVec3(v) ((v).x + (v).y + (v).z)
#define sumVec4(v) ((v).x + (v).y + ((v).z + (v).w))

#define clamp01(x) clamp(x, 0.0, 1.0)

#define saturate clamp01

#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)

float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float linearstep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

vec3 hsv(vec3 c) {
  const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);

  return c.z * mix(K.xxx, clamp01(p - K.xxx), c.y);
}

struct Volume {
  vec3 transmittance;
  vec3 scattering;
};

#define isbad(x) (any(isnan(x)) || any(isinf(x)))

vec3 maxMask(vec3 v) {
  return step(max(max(v.x, v.y), v.z), v);
}

vec2 maxMask(vec2 v) {
  return step(max(v.x, v.y), v);
}

vec3 minMask(vec3 v) {
  return step(min(min(v.x, v.y), v.z), v);
}

vec2 minMask(vec2 v) {
  return step(min(v.x, v.y), v);
}

#endif // SYNTAX_GLSL
