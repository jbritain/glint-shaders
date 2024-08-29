#ifndef SKY_INCLUDE
#define SKY_INCLUDE

#include "/lib/atmosphere/eBrunetonAtmosphere.glsl"

#define SUN_VECTOR normalize(mat3(gbufferModelViewInverse) * sunPosition)

vec3 getSky(vec3 dir, bool includeSun){
    vec3 transmit;
    vec3 kCamera = vec3(0.0, 5.0 + cameraPosition.y/1000.0 + ATMOSPHERE.bottom_radius, 0.0);
    vec3 radiance = GetSkyRadiance(
        kCamera, dir, 0.0, SUN_VECTOR, transmit
    );
    return radiance;
}
#endif