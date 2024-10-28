/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef ATMOSPHERE_COMMON_INCLUDE
#define ATMOSPHERE_COMMON_INCLUDE

vec3 sunVector = normalize(mat3(gbufferModelViewInverse) * sunPosition);
vec3 lightVector = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

float henyeyGreenstein(float g, float mu) {
  float gg = g * g;
	return (1.0 / (4.0 * PI))  * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * mu, 1.5));
}

float dualHenyeyGreenstein(float g1, float g2, float costh, float weight) {
  return mix(henyeyGreenstein(g1, costh), henyeyGreenstein(g2, costh), weight);
}

vec3 multipleScattering(float density, float costh, float g1, float g2, vec3 extinction, int octaves, float lobeWeight, float attenuation, float contribution, float phaseAttenuation){
  vec3 radiance = vec3(0.0);

  // float attenuation = 0.9;
  // float contribution = 0.5;
  // float phaseAttenuation = 0.7;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;

  for(int n = 0; n < octaves; n++){
    float phase = dualHenyeyGreenstein(g1 * c, g2 * c, costh, lobeWeight);
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

  float t = dot(N, P - O) / NoD;

  point = O + t*D;

  if(t < 0){
    return false;
  }

  return true;
}

const float earthRadius = 6371e3 - 1000;
const vec3 earthCentre = vec3(cameraPosition.x, -earthRadius, cameraPosition.z);
vec3 kCamera = vec3(0.0, 128 + cameraPosition.y + earthRadius, 0.0);

// https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d
bool raySphereIntersection(vec3 r0, vec3 rd, vec3 s0, float sr, inout vec3 point) {
    // - r0: ray origin
    // - rd: normalized ray direction
    // - s0: sphere center
    // - sr: sphere radius
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        return false;
    }
    float dist1 = (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
      
    float dist2 = (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);

    if(dist1 < 0.0) dist1 = dist2;
    if(dist2 < 0.0) dist2 = dist1;

    if(dist1 < 0.0) return false;

    float dist = min(dist1, dist2);

    point = r0 + dist * rd;
    return true;
}

// should be plug and play for rayPlaneIntersection
bool raySphereIntersectionPlanet(vec3 O, vec3 D, float height, inout vec3 point){
  float trueRadius = earthRadius + height;
  return raySphereIntersection(O, D, earthCentre, trueRadius, point);
}

#endif