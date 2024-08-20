#ifndef PACKING_INCLUDE
#define PACKING_INCLUDE

// pack 4 8 bit floats into a 32 bit float
float pack4x8F(in vec4 a) {
	uvec4 v = uvec4(round(clamp01(a) * 255.0)) << uvec4(0, 8, 16, 24);
	
	return uintBitsToFloat(sum4(v));
}

vec4 unpack4x8F(in float encodedbuffer) {
	uvec4 decode     = uvec4(floatBitsToUint(encodedbuffer));
	      decode.yzw = decode.yzw >> uvec3(8, 16, 24);
	      decode.xyz = decode.xyz & 255;
	
	return vec4(decode) / 255.0;
}

// pack 2 16 bit floats into a 32 bit float
float pack2x16F(in vec2 a) {
	uvec2 v = uvec2(round(clamp01(a) * 65535.0)) << uvec2(0, 16);
	
	return uintBitsToFloat(v.x + v.y);
}

vec2 unpack2x16F(in float encodedbuffer) {
	uvec2 decode   = uvec2(floatBitsToUint(encodedbuffer));
	      decode.y = decode.y >> 16;
	      decode.x = decode.x & 65535;
	
	return vec2(decode) / 65535.0;
}

// pack 2 8 bit floats into a 16 bit float
float pack2x8F(in vec2 a) {
	return dot(floor(255.0 * a + 0.5), vec2(1.0 / 65535.0, 256.0 / 65535.0));
}

float pack2x8F(in float a, in float b){
  return pack2x8F(vec2(a, b));
}

vec2 unpack2x8F(in float encodedBuffer) {
  vec2 xy = vec2(0.0);
  xy.x = modf((65535.0 / 256.0) * encodedBuffer, xy.y);
	return xy * vec2(256.0 / 255.0, 1.0 / 255.0);
}

//-------------------------------------------------------------->>
// https://jcgt.org/published/0003/02/01/

vec2 signNotZero(vec2 v) {
  return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}

vec2 encodeNormal(vec3 n){
  // Project the sphere onto the octahedron, and then onto the xy plane
	vec2 p = n.xy * (1.0 / (abs(n.x) + abs(n.y) + abs(n.z)));

	// Reflect the folds of the lower hemisphere over the diagonals
	p = n.z <= 0.0 ? ((1.0 - abs(p.yx)) * signNotZero(p)) : p;

	// Scale to [0, 1]
	return 0.5 * p + 0.5;
}

vec3 decodeNormal(vec2 e){
  vec3 n = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
  if (n.z < 0) n.xy = (1.0 - abs(n.yx)) * signNotZero(n.xy);
  return normalize(n);
}
//--------------------------------------------------------------<<
#endif