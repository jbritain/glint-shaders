// SMAA by Ary
// https://github.com/TinyAry123/basepack-2

#ifndef SAMPLER_TEXELFETCH_CLAMPED
	#define SAMPLER_TEXELFETCH_CLAMPED true

	#define texelFetch(tex, xy, lod)               texelFetch(tex, clamp(xy, ivec2(0, 0), textureSize(tex, 0) - 1), lod)
	#define texelFetchOffset(tex, xy, lod, offset) texelFetch(tex, xy + offset, lod)
#endif

void SMAASearchDiagonal1(out vec2 d, out vec2 e, sampler2D edgesTex, ivec2 texelCoord, ivec2 direction, vec2 bufferSize) {
	float edgeWeight = 1.0;
	int searchStep   = -1;

	while (searchStep < 180 && edgeWeight > 0.9) {
		searchStep++;
		texelCoord += direction;

		e = texelFetch(edgesTex, texelCoord, 0).xy;

		edgeWeight = 0.5 * (e.x + e.y);
	}

	d = vec2(searchStep, edgeWeight);
}

void SMAASearchDiagonal2(out vec2 d, out vec2 e, sampler2D edgesTex, vec2 uv, vec2 direction, vec2 bufferSize) {
	float edgeWeight = 1.0;
	int searchStep   = -1;

	uv.x += 0.25 / bufferSize.x;

	while (searchStep < 180 && edgeWeight > 0.9) {
		searchStep++;
		uv += direction / bufferSize;

		e   =  texture2D(edgesTex, uv).xy;
		e.x *= abs(5.0 * e.x - 3.75);
		e   =  floor(e + 0.5);

		edgeWeight = 0.5 * (e.x + e.y);
	}

	d = vec2(searchStep, edgeWeight);
}

#define texelFetchClamped(tex, xy, lod) texelFetch(tex, clamp(xy, ivec2(0), textureSize(tex, 0) - 1), lod)

vec2 SMAAAreaDiagonal(sampler2D areaTex, vec2 dist, vec2 e) {
	return texture2D(areaTex, (20.0 * e + dist + 0.5) * vec2(160.0, 560.0) + vec2(0.5, 0.0)).xy;
}

void SMAACalculateDiagonalWeights(out vec2 weights, sampler2D edgesTex, sampler2D areaTex, ivec2 texelCoord, vec2 uv, vec2 e, vec2 bufferSize) {
	vec4 d;
	vec2 end;

	weights = vec2(0.0);

	if (e.x > 0.0) {
		SMAASearchDiagonal1(d.xz, end, edgesTex, texelCoord, ivec2(-1,  1), bufferSize);
		d.x += 1.0 - step(0.9, -end.y);
	} else {
		d.xz = vec2(0.0);
	}

	SMAASearchDiagonal1(d.yw, end, edgesTex, texelCoord, ivec2( 1, -1), bufferSize);

	if (d.x + d.y > 2.0) {
		vec4 coords = uv.xyxy + vec4(0.25 - d.x, d.x, d.y, -(0.25 + d.y)) / bufferSize.xyxy;

		vec4 c =  vec4(texture2D(edgesTex, vec2(coords.x - 1.0 / bufferSize.x, coords.y)).xy, texture2D(edgesTex, vec2(coords.z + 1.0 / bufferSize.x, coords.w)).xy);
		c.xz   *= abs(5.0 * c.xz - 3.75);
		c.yxwz =  floor(c + 0.5);

		vec2 cc = (1.0 - step(0.9, d.zw)) * (2.0 * c.xz + c.yw);

		weights += SMAAAreaDiagonal(areaTex, d.xy, cc);
	}

	SMAASearchDiagonal2(d.xz, end, edgesTex, uv, vec2(-1.0, -1.0), bufferSize);

	if (texelFetchOffset(edgesTex, texelCoord, 0, ivec2( 1,  0)).x > 0.0) {
		SMAASearchDiagonal2(d.yw, end, edgesTex, uv, vec2( 1.0,  1.0), bufferSize);
		d.y += 1.0 - step(0.9, -end.y);
	} else {
		d.yw = vec2(0.0);
	}

	if (d.x + d.y > 2.0) {
		vec4 coords = uv.xyxy + vec4(-d.x, -d.x, d.y, d.y) / bufferSize.xyxy;

		vec4 c = vec4(texture2D(edgesTex, vec2(coords.x - 1.0 / bufferSize.x, coords.y)).y, texture2D(edgesTex, vec2(coords.x, coords.y - 1.0 / bufferSize.y)).x, texture2D(edgesTex, vec2(coords.z + 1.0 / bufferSize.x, coords.w)).yx);
		
		vec2 cc = (1.0 - step(0.9, d.zw)) * (2.0 * c.xz + c.yw);

		weights += SMAAAreaDiagonal(areaTex, d.xy, cc).yx;
	}
}

float SMAASearchLength(sampler2D searchTex, vec2 e, float offset) {
	return texelFetch(searchTex, ivec2(floor(vec2(32.0, -32.0) * e + vec2(66.0 * offset + 0.5, 32.5))), 0).x;
}

float SMAASearchXLeft(sampler2D edgesTex, sampler2D searchTex, vec2 uv, float end, vec2 bufferSize) {
	vec2 e = vec2(0.0, 1.0);

	while (uv.x > end && e.y > 0.8281 && e.x == 0.0) {
		e = texture2D(edgesTex, uv).xy;

		uv.x -= 2.0 / bufferSize.x;
	}

	return uv.x + (3.25 - (255.0 / 127.0) * SMAASearchLength(searchTex, e, 0.0)) / bufferSize.x;
}

float SMAASearchXRight(sampler2D edgesTex, sampler2D searchTex, vec2 uv, float end, vec2 bufferSize) {
	vec2 e = vec2(0.0, 1.0);

	while (uv.x < end && e.y > 0.8281 && e.x == 0.0) {
		e = texture2D(edgesTex, uv).xy;
		
		uv.x += 2.0 / bufferSize.x;
	}
	
	return uv.x - (3.25 - (255.0 / 127.0) * SMAASearchLength(searchTex, e, 0.5)) / bufferSize.x;
}

float SMAASearchYUp(sampler2D edgesTex, sampler2D searchTex, vec2 uv, float end, vec2 bufferSize) {
	vec2 e = vec2(1.0, 0.0);

	while (uv.y > end && e.x > 0.8281 && e.y == 0.0) {
		e = texture2D(edgesTex, uv).xy;

		uv.y -= 2.0 / bufferSize.y;
	}

	return uv.y + (3.25 - (255.0 / 127.0) * SMAASearchLength(searchTex, e.yx, 0.0)) / bufferSize.y;
}

float SMAASearchYDown(sampler2D edgesTex, sampler2D searchTex, vec2 uv, float end, vec2 bufferSize) {
	vec2 e = vec2(1.0, 0.0);

	while (uv.y < end && e.x > 0.8281 && e.y == 0.0) {
		e = texture2D(edgesTex, uv).xy;

		uv.y += 2.0 / bufferSize.y;
	}

	return uv.y - (3.25 - (255.0 / 127.0) * SMAASearchLength(searchTex, e.yx, 0.5)) / bufferSize.y;
}

void SMAAArea(out vec2 weights, sampler2D areaTex, vec2 dist, float e1, float e2) {
	weights = texture2D(areaTex, (16.0 * floor(4.0 * vec2(e1, e2) + 0.5) + dist + 0.5) / vec2(160.0, 560.0)).xy;
}

void SMAADetectHorizontalCornerPattern(inout vec2 weights, sampler2D edgesTex, vec3 coords, vec2 d, vec2 bufferSize) {
    vec2 leftRight = step(d.xy, d.yx);
	vec2 factor    = vec2(1.0);
    float rounding = 0.5 / (leftRight.x + leftRight.y);

	if (leftRight.x > 0.0) factor -= rounding * vec2(texture2D(edgesTex, vec2(coords.x, coords.y + 1.0 / bufferSize.y)).x, texture2D(edgesTex, vec2(coords.x, coords.y - 2.0 / bufferSize.y)).x);

	if (leftRight.y > 0.0) factor -= rounding * vec2(texture2D(edgesTex, coords.zy + vec2( 1.0,  1.0) / bufferSize).x, texture2D(edgesTex, coords.zy + vec2( 1.0, -2.0) / bufferSize).x);

    weights *= clamp(factor, 0.0, 1.0);
}

void SMAADetectVerticalCornerPattern(inout vec2 weights, sampler2D edgesTex, vec3 coords, vec2 d, vec2 bufferSize) {
    vec2 leftRight = step(d.xy, d.yx);
	vec2 factor    = vec2(1.0);
    float rounding = 0.5 / (leftRight.x + leftRight.y);

	if (leftRight.x > 0.0) factor -= rounding * vec2(texture2D(edgesTex, vec2(coords.x + 1.0 / bufferSize.x, coords.y)).y, texture2D(edgesTex, vec2(coords.x - 2.0 / bufferSize.x, coords.y)).y);

	if (leftRight.y > 0.0) factor -= rounding * vec2(texture2D(edgesTex, coords.xz + vec2( 1.0,  1.0) / bufferSize).y, texture2D(edgesTex, coords.xz + vec2(-2.0,  1.0) / bufferSize).y);

    weights *= clamp(factor, 0.0, 1.0);
}

vec4 SMAABlendingWeightCalculation(sampler2D edgesTex, sampler2D areaTex, sampler2D searchTex, vec2 uv, vec2 bufferSize) {
	ivec2 texelCoord = ivec2(uv * bufferSize);
	vec4 offsets[3];
	vec3 coords;
	vec2 d;
  vec4 weights = vec4(0.0);

	offsets[0] = uv.xyxy + vec4(-0.250, -0.125,  1.250, -0.125) / bufferSize.xyxy;
	offsets[1] = uv.xyxy + vec4(-0.125, -0.250, -0.125,  1.250) / bufferSize.xyxy;
	offsets[2] = vec4(offsets[0].xz, offsets[1].yw) + vec4(-256.0, 256.0, -256.0, 256.0) / bufferSize.xxyy;

	vec2 e = texelFetch(edgesTex, texelCoord, 0).xy;

	if (e.y > 0.0) {
		SMAACalculateDiagonalWeights(weights.xy, edgesTex, areaTex, texelCoord, uv, e, bufferSize);

		if (weights.x == -weights.y) {
			coords = vec3(SMAASearchXLeft(edgesTex, searchTex, offsets[0].xy, offsets[2].x, bufferSize), offsets[1].y, SMAASearchXRight(edgesTex, searchTex, offsets[0].zw, offsets[2].y, bufferSize));
			d      = abs(floor(bufferSize.x * (coords.xz - uv.x) + 0.5));

			SMAAArea(weights.xy, areaTex, sqrt(d), texture2D(edgesTex, coords.xy).x, texture2D(edgesTex, vec2(coords.z + 1.0 / bufferSize.x, coords.y)).x);
		
			coords.y = uv.y;
			SMAADetectHorizontalCornerPattern(weights.xy, edgesTex, coords, d, bufferSize);
		} else {
			e.x = 0.0;
		}
	} else {
		weights.xy = vec2(0.0);
	}

	if (e.x > 0.0) {
		coords = vec3(offsets[0].x, SMAASearchYUp(edgesTex, searchTex, offsets[1].xy, offsets[2].z, bufferSize), SMAASearchYDown(edgesTex, searchTex, offsets[1].zw, offsets[2].w, bufferSize));
		d      = abs(floor(bufferSize.y * (coords.yz - uv.y) + 0.5));

		SMAAArea(weights.zw, areaTex, sqrt(d), texture2D(edgesTex, coords.xy).y, texture2D(edgesTex, vec2(coords.x, coords.z + 1.0 / bufferSize.y)).y);
	
		coords.x = uv.x;
		SMAADetectVerticalCornerPattern(weights.zw, edgesTex, coords, d, bufferSize);
	} else {
		weights.zw = vec2(0.0);
	}

  return weights;
}