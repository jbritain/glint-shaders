#ifndef UTIL_INCLUDE
#define UTIL_INCLUDE

const float PI = radians(180.0);
const float TAU = radians(360.0);

#define clamp01(x) clamp(x, 0.0, 1.0)
#define max0(x) max(x, 0.0)

#define sum3(v) (((v).x + (v).y) + (v).z)
#define sum4(v) (((v).x + (v).y) + ((v).z + (v).w))

#define _rcp(x) (1.0 / x)
#define _log10(x, y) (log2(x) / log2(y))
#define _pow2(x) (x*x)
#define _pow3(x) (x*x*x)
#define _pow4(x) (x*x*x*x)
#define _pow5(x) (x*x*x*x*x)

float pow2(in float x) {
    return _pow2(x);
}
int pow2(in int x) {
    return _pow2(x);
}
vec2 pow2(in vec2 x) {
    return _pow2(x);
}
vec3 pow2(in vec3 x) {
    return _pow2(x);
}
vec4 pow2(in vec4 x) {
    return _pow2(x);
}

float pow3(in float x) {
    return _pow3(x);
}
int pow3(in int x) {
    return _pow3(x);
}
vec2 pow3(in vec2 x) {
    return _pow3(x);
}
vec3 pow3(in vec3 x) {
    return _pow3(x);
}
vec4 pow3(in vec4 x) {
    return _pow3(x);
}

float pow4(in float x) {
    return _pow4(x);
}
int pow4(in int x) {
    return _pow4(x);
}
vec2 pow4(in vec2 x) {
    return _pow4(x);
}
vec3 pow4(in vec3 x) {
    return _pow4(x);
}
vec4 pow4(in vec4 x) {
    return _pow4(x);
}

float pow5(in float x) {
    return _pow5(x);
}
int pow5(in int x) {
    return _pow5(x);
}
vec2 pow5(in vec2 x) {
    return _pow5(x);
}
vec3 pow5(in vec3 x) {
    return _pow5(x);
}
vec4 pow5(in vec4 x) {
    return _pow5(x);
}

float rcp(in float x) {
    return _rcp(x);
}
vec2 rcp(in vec2 x) {
    return _rcp(x);
}
vec3 rcp(in vec3 x) {
    return _rcp(x);
}
vec4 rcp(in vec4 x) {
    return _rcp(x);
}

float max2(vec2 x) {
    return max(x.x, x.y);
}

float min2(vec2 x){
    return min(x.x, x.y);
}

float max3(float x, float y, float z) {
    return max(x, max(y, z));
}
float max3(vec3 x) {
    return max(x.x, max(x.y, x.z));
}
float min3(float x, float y, float z) {
    return min(x, min(y, z));
}
float min3(vec3 x) {
    return min(x.x, min(x.y, x.z));
}
float mean(vec3 x) {
    return (x.x + x.y + x.z) * rcp(3.0);
}
float mean(vec4 x) {
    return (x.x + x.y + x.z + x.w) * rcp(4.0);
}

float max4(float x, float y, float z, float w) {
    return max(x, max(y, max(z, w)));
}
float max4(vec4 x) {
    return max(x.x, max(x.y, max(x.z, x.w)));
}
float min4(float x, float y, float z, float w) {
    return min(x, min(y, min(z, w)));
}
float min4(vec4 x) {
    return min(x.x, min(x.y, min(x.z, x.w)));
}

float log10(in float x) {
    return _log10(x, 10.0);
}
int log10(in int x) {
    return int(_log10(x, 10.0));
}
vec2 log10(in vec2 x) {
    return _log10(x, 10.0);
}
vec3 log10(in vec3 x) {
    return _log10(x, 10.0);
}
vec4 log10(in vec4 x) {
    return _log10(x, 10.0);
}

vec2 sincos(float x) { return vec2(sin(x), cos(x)); }

mat2 rotate(float a) {
    vec2 m;
    m.x = sin(a);
    m.y = cos(a);
	return mat2(m.y, -m.x,  m.x, m.y);
}

vec2 rotate(vec2 vector, float angle) {
	vec2 sc = sincos(angle);
	return vec2(sc.y * vector.x + sc.x * vector.y, sc.y * vector.y - sc.x * vector.x);
}

vec3 rotate(vec3 vector, vec3 axis, float angle) {
	// https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
	vec2 sc = sincos(angle);
	return sc.y * vector + sc.x * cross(axis, vector) + (1.0 - sc.y) * dot(axis, vector) * axis;
}

vec3 rotate(vec3 vector, vec3 from, vec3 to) {
	// where "from" and "to" are two unit vectors determining how far to rotate
	// adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

	float cosTheta = dot(from, to);
	if (abs(cosTheta) >= 0.9999) { return cosTheta < 0.0 ? -vector : vector; }
	vec3 axis = normalize(cross(from, to));

	vec2 sc = vec2(sqrt(1.0 - cosTheta * cosTheta), cosTheta);
	return sc.y * vector + sc.x * cross(axis, vector) + (1.0 - sc.y) * dot(axis, vector) * axis;
}

// Creates a TBN matrix from a normal and a tangent
mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

// Creates a TBN matrix from just a normal
// The tangent version is needed for normal mapping because
// of face rotation
mat3 tbnNormal(vec3 normal) {
    vec3 tangent = normalize(cross(normal, normalize(vec3(0, 1, 1))));
    return tbnNormalTangent(normal, tangent);
}

float linearizeDepth(float depth, float near, float far) {
  return (near * far) / (depth * (near - far) + far);
}

float delinearizeDepth(float depth, float near, float far){
    return ((near - depth) * far) / depth * (near - far);
}

vec3 setSaturationLevel(vec3 color, float level) {
	float luminance = dot(color, vec3(0.2125, 0.7154, 0.0721));
	vec3 newColor = max0(mix(vec3(luminance), color, level));
	
	return newColor;
}

vec3 hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	
	return c.z * mix(K.xxx, clamp01(p - K.xxx), c.y);
}

float quinticStep(float edge0, float edge1, float x) {
    x = clamp01((x - edge0) / (edge1 - edge0));
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

#define worldTimeCounter ((worldTime / 20.0) + (worldDay * 1200.0))
#define EBS (vec2(eyeBrightnessSmooth) / 240.0)


#endif