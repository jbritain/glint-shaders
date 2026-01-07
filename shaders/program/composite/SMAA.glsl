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

uniform sampler2D blendWeightS, tempColS;
uniform layout(rgba16f) restrict writeonly image2D colorimg0;



void main() {
	ivec2 texel = ivec2(gl_GlobalInvocationID.xy);

	vec4 a = vec4(
		texelFetchOffset(blendWeightS, texel, 0, ivec2(1, 0)).w,
		texelFetchOffset(blendWeightS, texel, 0, ivec2(0, 1)).y,
		texelFetch(blendWeightS, texel, 0).zx
	);

	vec3 color;

	if (dot(a, vec4(1.0)) < 1.0e-5) {
		color = texelFetch(tempColS, texel, 0).rgb;
	} else {
		bool h = max(a.x, a.z) > max(a.y, a.w);

		vec4 blending_offset = h ? vec4(a.x, 0.0, a.z, 0.0) : vec4(0.0, a.y, 0.0, a.w);

		vec2 blending_weight = h ? a.xz : a.yw;
		blending_weight /= dot(blending_weight, vec2(1.0));

		vec2 coord = fma(vec2(texel), pixelSize, 0.5 * pixelSize);

		color = blending_weight.x * textureLod(tempColS, fma(blending_offset.xy, pixelSize, coord), 0.0).rgb;
		color += blending_weight.y * textureLod(tempColS, fma(blending_offset.zw, -pixelSize, coord), 0.0).rgb;
	}

	imageStore(colorimg0, texel, vec4(color, 0.0));
}