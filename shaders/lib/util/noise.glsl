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

#endif