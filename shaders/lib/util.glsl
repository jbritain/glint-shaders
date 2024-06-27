// Same algorithm, but faster, thanks to Kneemund/Niemand
float linearizeDepth(float depth) {
    return ((near * far) / (depth * (near - far) + far)) / far;
}

bool floatCompare(float a, float b){
    return abs(a - b) < 0.0001;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
    vec4 homPos = projectionMatrix * vec4(position, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 encodeNormal(vec3 normal){
    return normal * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 encodedNormal){
    return normalize((encodedNormal * 2.0) - 1.0);
}

#define PI 3.1415926535