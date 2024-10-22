/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef NOISE_INCLUDE
#define NOISE_INCLUDE

// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
// adapted with help from balint and hardester
float interleavedGradientNoise(vec2 coord){
	return fract(52.9829189 * fract(0.06711056 * coord.x + (0.00583715 * coord.y)));
}

float interleavedGradientNoise(vec2 coord, int frame){
	return interleavedGradientNoise(coord + 5.588238 * (frame & 63));
}

vec3 interleavedGradientNoise3(vec2 coord, int frame){
    float h1 = interleavedGradientNoise(coord, frame);
    float h2 = interleavedGradientNoise(coord + 9.0, frame);
    float h3 = interleavedGradientNoise(coord + 10.0, frame);

    return vec3(h1, h2, h3);
}

float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

#define bayer4(a) (Bayer2(a * 0.5) * 0.25 + Bayer2(a))
#define bayer8(a) (Bayer4(a * 0.5) * 0.25 + Bayer2(a))

#endif