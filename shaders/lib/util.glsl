#ifndef UTIL_INCLUDE
#define UTIL_INCLUDE


#define PI 3.1415926535

#define clamp01(x) clamp(x, 0.0, 1.0)
#define rcp(x) 1.0/x

#define pow2(x) x*x

#define sum2(v) ((v).x + (v).y)
#define sum4(v) (((v).x + (v).y) + ((v).z + (v).w))

bool floatCompare(float a, float b){
    return abs(a - b) < 0.001;
}


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


#endif