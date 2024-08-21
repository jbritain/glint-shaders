#define diagonal2(mat) vec2((mat)[0].x, (mat)[1].y)
#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, mat[2].z)

#define transMAD(mat, v) (     mat3(mat) * (v) + (mat)[3].xyz)
#define  projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 screenToViewSpace(vec2 texcoord, float depth){
  vec3 screenPos = vec3(texcoord, depth) * 2.0 - 1.0;

  return projMAD(gbufferProjectionInverse, screenPos) / (screenPos.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}