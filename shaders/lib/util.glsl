// Same algorithm, but faster, thanks to Kneemund/Niemand
float linearizeDepth(float depth) {
    return ((near * far) / (depth * (near - far) + far)) / far;
}

bool floatCompare(float a, float b){
    return abs(a - b) < 0.001;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 encodeNormal(vec3 normal){
  return normal * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 encodedNormal){
  return (encodedNormal - 0.5) * 2.0;
}
#define PI 3.1415926535

// Creates a TBN matrix from a normal and a tangent
mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    // For DirectX normal mapping you want to switch the order of these 
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

// Creates a TBN matrix from just a normal
// The tangent version is needed for normal mapping because
// of face rotation
mat3 tbnNormal(vec3 normal) {
    vec3 tangent = normalize(cross(normal, normalize(vec3(0, 1, 1))));
    return tbnNormalTangent(normal, tangent);
}

#define clamp01(x) clamp(x, 0.0, 1.0)