#ifndef SPACE_CONVERSIONS_INCLUDE
#define SPACE_CONVERSIONS_INCLUDE

float linearizeDepth(float depth, float near, float far) {
  return (near * far) / (depth * (near - far) + far);
}

vec3 screenSpaceToViewSpace(vec3 screenPosition) {
	screenPosition = screenPosition * 2.0 - 1.0;

	vec3 viewPosition  = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * screenPosition.xy + gbufferProjectionInverse[3].xy, gbufferProjectionInverse[3].z);

  viewPosition /= gbufferProjectionInverse[2].w * screenPosition.z + gbufferProjectionInverse[3].w;

	return viewPosition;
}

float screenSpaceToViewSpace(float depth) {
	depth = depth * 2.0 - 1.0;
	return gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * depth + gbufferProjectionInverse[3].w);
}

vec3 viewSpaceToScreenSpace(vec3 viewPosition) {
	vec3 screenPosition  = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * viewPosition + gbufferProjection[3].xyz;
	     screenPosition /= -viewPosition.z;

	return screenPosition * 0.5 + 0.5;
}

float viewSpaceToScreenSpace(float depth) {
	return ((gbufferProjection[2].z * depth + gbufferProjection[3].z) / -depth) * 0.5 + 0.5;
}

vec3 viewSpaceToSceneSpace(in vec3 viewPosition) {
    return mat3(gbufferModelViewInverse) * viewPosition + gbufferModelViewInverse[3].xyz;
}

#endif