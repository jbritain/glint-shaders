#include "/lib/common.glsl"

/*
SMAA by Lura!
https://github.com/Luracasmus/smaa-mc

Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
Copyright (C) 2024-2025 Luracasmus

Permission is hereby granted, free of charge, to any person obtaining a copy
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software. As clarification, there is no
requirement that the copyright notice and permission be included in binary
distributions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

uniform layout(rg8) restrict writeonly image2D edge;
uniform layout(rgba16) restrict writeonly image2D tempCol;

vec3 linear(vec3 srgb) {
	return mix(
		pow((srgb + 0.055) / 1.055, vec3(2.4)),
		srgb / 12.92,
		lessThanEqual(srgb, vec3(0.04045))
	);
}

vec3 srgb(vec3 linear) {
	return mix(
		1.055 * pow(linear, vec3(1.0/2.4)) - 0.055,
		12.92 * linear,
		lessThanEqual(linear, vec3(0.0031308))
	);
}

// https://www.wikiwand.com/en/articles/Color_difference
float redmean(vec3 a, vec3 b) {
	float r = step(0.5, mix(a.r, b.r, 0.5));
	vec3 d = a - b;

	return sqrt(dot(d*d, vec3(
		2.0 + r,
		4.0,
		3.0 - r
	)));
}

void main() {
	ivec2 texel = ivec2(gl_GlobalInvocationID.xy);

	vec3 color = texelFetch(colortex0, texel, 0).rgb;
	imageStore(tempCol, texel, vec4(color, 0.0));
  color = srgb(color);

	vec3 left = srgb(texelFetchOffset(colortex0, texel, 0, ivec2(-1, 0)).rgb);
	vec3 top = srgb(texelFetchOffset(colortex0, texel, 0, ivec2(0, -1)).rgb);

	vec4 delta;
	delta.xy = vec2(
		redmean(color, left),
		redmean(color, top)
	);

	bvec2 edges = greaterThanEqual(delta.xy, vec2(SMAA_THRESHOLD));

	if (any(edges)) {
		delta.zw = vec2(
			redmean(color, srgb(texelFetchOffset(colortex0, texel, 0, ivec2(1, 0)).rgb)), // right
			redmean(color, srgb(texelFetchOffset(colortex0, texel, 0, ivec2(0, 1)).rgb)) // bottom
		);

		vec2 delta_max = max(delta.xy, delta.zw);

		delta.zw = vec2(
			redmean(left, srgb(texelFetchOffset(colortex0, texel, 0, ivec2(-2, 0)).rgb)), // left-left
			redmean(top, srgb(texelFetchOffset(colortex0, texel, 0, ivec2(0, -2)).rgb)) // top-top
		);

		delta_max = max(delta_max.xy, delta.zw);

		const float local_contrast_adaptation_factor = 2.0;
		bvec2 temp = greaterThanEqual(delta.xy, (max(delta_max.x, delta_max.y) / local_contrast_adaptation_factor).xx);
		bvec2 result = bvec2(edges.x && temp.x, edges.y && temp.y); // gotta do this instead of result && temp on AMD :(

		if (any(result)) imageStore(edge, texel, vec4(
			result, 0.0, 0.0
		));
	}
}