#ifndef SPECULAR_SHADING_INCLUDE
#define SPECULAR_SHADING_INCLUDE

#include "/lib/util.glsl"
#include "/lib/util/material.glsl"

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float getNoHSquared(float NoL, float NoV, float VoL) {
    float radiusCos = 1.0 - (1.0 / 360.0);
		float radiusTan = tan(acos(radiusCos));
    
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));
    
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;
    
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

// trowbridge-reitz ggx
// https://mudstack.com/blog/tutorials/physically-based-rendering-study-part-2/
float calculateSpecularHighlight(vec3 N, vec3 V, vec3 L, float roughness){
  float alpha = roughness;
	float dotNHSquared = getNoHSquared(dotSafe(N, L), dotSafe(N, V), dotSafe(V, L));
	float distr = dotNHSquared * (alpha - 1.0) + 1.0;
	return alpha / (PI * pow2(distr));
}

vec3 schlick(Material material, float NoV){
  const vec3 f0 = material.f0;
  const vec3 f82 = material.f82;
  if(material.metalID == NO_METAL){ // normal schlick approx.
    return vec3(f0 + (1.0 - f0) * pow(1.0 - NoV, 5.0));
  } else { // lazanyi schlick - https://www.shadertoy.com/view/DdlGWM
    vec3 a = (823543./46656.) * (f0 - f82) + (49./6.) * (1.0 - f0);

    float p1 = 1.0 - NoV;
    float p2 = p1*p1;
    float p4 = p2*p2;

    return clamp01(f0 + ((1.0 - f0) * p1 - a * NoV * p2) * p4);
  }
}

vec3 shadeSpecular(vec3 color, vec2 lightmap, vec3 normal, vec3 viewPos, Material material){

  vec3 V = normalize(-viewPos);
  vec3 N = normal;
  vec3 L = normalize(shadowLightPosition);
  
  float NoV = dot(N, V);

  vec3 fresnel = schlick(material, NoV);

  // vec3 sunlight = getSunlight(feetPlayerPos, mappedNormal, faceNormal);

  vec3 sunlightColor = getSky(mat3(gbufferModelViewInverse) * L, true) * 0.005;

  vec3 specularHighlight = calculateSpecularHighlight(N, V, L, max(0.001, material.roughness)) * sunlightColor;

  color = mix(color, specularHighlight, clamp01(fresnel));

  return color;
}

#endif