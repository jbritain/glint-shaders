/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef PACKING_INCLUDE
#define PACKING_INCLUDE

#include "/lib/util.glsl"

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

vec2 unpack2x8F(in float pack) {
	vec2 xy; xy.x = modf((65535.0 / 256.0) * pack, xy.y);
	return xy * vec2(256.0 / 255.0, 1.0 / 255.0);
}

// https://jcgt.org/published/0003/02/01/
// ---------------------------------------------------------->
vec2 signNonZero(vec2 v) {
	return vec2(
		v.x >= 0.0 ? 1.0 : -1.0,
		v.y >= 0.0 ? 1.0 : -1.0
	);
}

vec2 encodeNormal(vec3 v) {
	vec2 p = v.xy * (1.0 / (abs(v.x) + abs(v.y) + abs(v.z)));
	p = v.z <= 0.0 ? ((1.0 - abs(p.yx)) * signNonZero(p)) : p;
	return 0.5 * p + 0.5;
}

vec3 decodeNormal(vec2 e) {
	e = 2.0 * e - 1.0;
	vec3 v = vec3(e.xy, 1.0 - abs(e.x) - abs(e.y));
	if (v.z < 0) v.xy = (1.0 - abs(v.yx)) * signNonZero(v.xy);
	return normalize(v);
}
// <----------------------------------------------------------

#endif