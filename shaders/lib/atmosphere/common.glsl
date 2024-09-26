#ifndef ATMOSPHERE_COMMON_INCLUDE
#define ATMOSPHERE_COMMON_INCLUDE

vec3 sunVector = normalize(mat3(gbufferModelViewInverse) * sunPosition);
vec3 lightVector = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

float henyeyGreenstein(float g, float mu) {
  float gg = g * g;
	return (1.0 / (4.0 * PI))  * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * mu, 1.5));
}

float dualHenyeyGreenstein(float g, float costh, float weight) {
  return mix(henyeyGreenstein(-g, costh), henyeyGreenstein(g, costh), weight);
}

vec3 multipleScattering(float density, float costh, float g, vec3 extinction, int octaves, float lobeWeight){
  vec3 radiance = vec3(0.0);

  float attenuation = 0.5;
  float contribution = 0.5;
  float phaseAttenuation = 0.1;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;

  for(int n = 0; n < octaves; n++){
    float phase = dualHenyeyGreenstein(g * c, costh, lobeWeight);
    radiance += b * phase * exp(-density * extinction * a);

    a *= attenuation;
    b *= contribution;
    c *= (1.0 - phaseAttenuation);
  }

  return radiance;
}

// O is the ray origin, D is the direction
// height is the height of the plane
bool rayPlaneIntersection(vec3 O, vec3 D, float height, inout vec3 point){
  vec3 N = vec3(0.0, sign(O.y - height), 0.0); // plane normal vector
  vec3 P = vec3(0.0, height, 0.0); // point on the plane

  float NoD = dot(N, D);
  if(NoD == 0.0){
    return false;
  }

  float t = dot(N, P - O)/NoD;
  if(t < 0){
    return false;
  }


  point = O + t*D;
  return true;
}

#endif