// SMAA by Ary
// https://github.com/TinyAry123/basepack-2

#ifndef SAMPLER_TEXELFETCH_CLAMPED
	#define SAMPLER_TEXELFETCH_CLAMPED true

	#define texelFetch(tex, xy, lod)               texelFetch(tex, clamp(xy, ivec2(0, 0), textureSize(tex, 0) - 1), lod)
	#define texelFetchOffset(tex, xy, lod, offset) texelFetch(tex, xy + offset, lod)
#endif

#define SMAA_CONTRAST_ADAPTION_COEFFICIENT 2.0

vec2 SMAAColorEdgeDetection(sampler2D colorTex, vec2 uv, vec2 bufferSize) {
    ivec2 texelCoord = ivec2(uv * bufferSize);
    vec4 delta;
    vec3 d;

    vec2 edges = vec2(0.0);

    vec3 colorCenter = texelFetch(colorTex, texelCoord, 0).rgb;

    delta.x = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(-1, 0)).xyz);
    delta.y = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(0, -1)).xyz);

    edges = step(0.0625, delta.xy);

    d.x = length(delta.xy);

    if(edges.x + edges.y > 0.0){
        delta.z = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(1, 0)).xyz);
        delta.w = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(0, 1)).xyz);

        d.y = length(delta.zw);

        delta.z = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(-2, 0)).xyz);
        delta.w = distance(colorCenter, texelFetchOffset(colorTex, texelCoord, 0, ivec2(0, -2)).xyz);

        d.z = length(delta.zw);

        edges = step(max(max(d.x, d.y), d.z), 2.0 * delta.xy);
    }

    return edges;
}

vec2 SMAADepthEdgeDetection(sampler2D depthTex, vec2 uv, vec2 bufferSize) { // Redundant linearisation of depth. Optimise later. 
    ivec2 texelCoord = ivec2(uv * bufferSize);
    vec4  delta;
    float currentDepth;

    vec2 edges = vec2(0.0);

    float depthCenter = linearizeDepth(texelFetch(depthTex, texelCoord, 0).r, far, near);

    currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2(-1,  0)).r, far, near);
    delta.x      = abs(depthCenter - currentDepth);

    currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2( 0, -1)).r, far, near);
    delta.y      = abs(depthCenter - currentDepth);

    edges = step(1.0, delta.xy);

    float temp1 = length(delta.xy);

    if (edges.x + edges.y > 0.0) {
        currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2( 1,  0)).r, far, near);
        delta.z      = abs(depthCenter - currentDepth);
        
        currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2( 0,  1)).r, far, near);
        delta.w      = abs(depthCenter - currentDepth);

        float temp2 = length(delta.zw);

        vec2 maxDelta = max(delta.xy, delta.zw);

        currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2(-2,  0)).r, far, near);
        delta.z      = abs(depthCenter - currentDepth);

        currentDepth = linearizeDepth(texelFetchOffset(depthTex, texelCoord, 0, ivec2( 0, -2)).r, far, near);
        delta.w      = abs(depthCenter - currentDepth);

        float temp3 = length(delta.zw);

        maxDelta         = max(maxDelta.xy, delta.zw);
        float finalDelta = max(max(temp1, temp2), temp3);

        edges = step(finalDelta, SMAA_CONTRAST_ADAPTION_COEFFICIENT * delta.xy);
    }

  return edges;
}

void SMAANormalEdgeDetection(out vec2 edges, sampler2D normalTex, vec2 uv, vec2 bufferSize); // Implement later. 