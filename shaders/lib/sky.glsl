// https://www.shadertoy.com/view/sssXWH

float SKY_HEIGHT = 0.2;
vec3  SUN_COLOR = vec3(1.0,0.9,0.7) * 8;
vec3  SKY_SCATTERING = vec3(0.1, 0.3, 0.7);
float SUN_ANGULAR_DIAMETER = 0.08;
#define SUN_VECTOR normalize(mat3(gbufferModelViewInverse) * sunPosition)

float atmosphereDepth(vec3 dir)
{
    return SKY_HEIGHT/ max(dir.y, 0.0);
}

vec3 getSun(vec3 dir)
{   
    float a = acos(dot(dir, SUN_VECTOR));
    if(dir == SUN_VECTOR){ // correct for dot product imprecision
      a = 0;
    }
    
    float t = 0.005;
    float e = smoothstep(SUN_ANGULAR_DIAMETER*0.5 + t, SUN_ANGULAR_DIAMETER*0.5, a);
    return SUN_COLOR * e;
}

vec3 transmittance(vec3 dir)
{
    return exp(-atmosphereDepth(dir) * SKY_SCATTERING);
}

vec3 getSky(vec3 dir){
    return mix(
        getSun(SUN_VECTOR) * transmittance(SUN_VECTOR), 
        getSun(dir),
        transmittance(dir)
    );
}
