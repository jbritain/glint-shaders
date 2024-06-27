vec3 viewPos = vec3(texcoord, texture(depthtex0, texcoord)); // screenPos

float depth = linearizeDepth(viewPos.z);

viewPos = viewPos * 2.0 - 1.0; // ndcPos
viewPos = projectAndDivide(gbufferProjectionInverse, viewPos);

vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;