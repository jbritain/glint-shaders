#ifndef SPHEREMAP_INCLUDE
#define SPHEREMAP_INCLUDE

vec2 mapSphere(vec3 dir){
  dir = normalize(dir);
  dir = dir.xzy;

  float theta = atan(dir.z, dir.x);

  theta = mod(theta, 2 * PI);

  float phi = acos(dir.y);

  return vec2(
    theta / (2 * PI),
    phi / PI
  );
}

vec3 unmapSphere(vec2 uv){
  float theta = uv.x * 2 * PI;
  float phi = uv.y * PI;

  vec3 dir = normalize(vec3(
    sin(phi) * cos(theta),
    cos(phi),
    sin(phi) * sin(theta)
  ));

  dir = dir.xzy;
  return dir;
}

#endif