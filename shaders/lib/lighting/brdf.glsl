/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    
    By jbritain
    https://jbritain.net
                                            
*/

#ifndef BRDF_GLSL
#define BRDF_GLSL

#include "/lib/atmosphere/atmosphere.glsl"
#include "/lib/material/material.glsl"

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float getNoHSquared(float NoL, float NoV, float VoL, float radius) {
  float radiusCos = cos(radius);
  float radiusTan = tan(radius);

  float RoL = 2.0 * NoL * NoV - VoL;
  if (RoL >= radiusCos) return 1.0;

  float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
  float NoTr = rOverLengthT * (NoV - RoL * NoL);
  float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

  float triple = sqrt(
    clamp(
      1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,
      0.0,
      1.0
    )
  );

  float NoBr = rOverLengthT * triple,
    VoBr = rOverLengthT * (2.0 * triple * NoV);
  float NoLVTr = NoL * radiusCos + NoV + NoTr,
    VoLVTr = VoL * radiusCos + 1.0 + VoTr;
  float p = NoBr * VoLVTr,
    q = NoLVTr * VoLVTr,
    s = VoBr * NoLVTr;
  float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
  float xDenom =
    p * p +
    s * (s - 2.0 * p) +
    NoLVTr *
      ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
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

// robobo dredged this up from somewhere
float areaLightNormalization(float roughness, float LoH, float radius) {
  // Decima: Still in flux
  float roughnessSquaredLoH = roughness * roughness * (LoH + 0.001);
  return roughnessSquaredLoH /
  (roughnessSquaredLoH + 0.25 * radius * (2.0 * roughness + radius));
}

float schlickGGX(float NoV, float K) {
  float nom = NoV;
  float denom = NoV * (1.0 - K) + K;

  return nom / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float K) {
  float NoV = max(dot(N, V), 1e-6);
  float NoL = max(dot(N, L), 1e-6);
  float ggx1 = schlickGGX(NoV, K);
  float ggx2 = schlickGGX(NoL, K);

  return ggx1 * ggx2;
}

// TODO: HCM

// Ray Tracing Gems II - "The Schlick Fresnel Approximation"
vec3 schlick(vec3 f0, float cosTheta, float roughness) {
  // roughness term as suggested by sebastian lagarde
  // https://seblagarde.wordpress.com/2011/08/17/hello-world/
  // TODO: see if someone has come up with a better approximation for this
  return mix(f0, max(vec3(1.0 - roughness), f0), clamp01(pow5(1.0 - cosTheta)));
}

vec3 schlickLazanyi(vec3 f0, vec3 f82, float cosTheta, float roughness) {
  // Hoffman, N. - "Fresnel equations considered harmful"
  vec3 a = 823543.0 / 46656.0 * (f0 - f82) + 49.0 / 6.0 * (1.0 - f0);

  const float alpha = 6;

  return mix(
    f0,
    max(vec3(1.0 - roughness), f0),
    clamp01(pow5(1.0 - cosTheta)) - a * cosTheta * pow(1 - cosTheta, alpha)
  );
}

vec3 fresnel(Material material, float NoV) {
  if (material.metalID == NO_METAL || material.metalID == OTHER_METAL) {
    return clamp01(schlick(material.f0, NoV, 0.0));
  } else {
    return clamp01(
      schlickLazanyi(
        metalF0[material.metalID],
        metalF82[material.metalID],
        NoV,
        0.0
      )
    )
          #ifdef ALBEDO_METAL_TINT
        * material.albedo
      #endif
    ;
  }
}

vec3 fresnelRoughness(Material material, float NoV) {
  if (material.metalID == NO_METAL || material.metalID == OTHER_METAL) {
    return clamp01(schlick(material.f0, NoV, material.roughness));
  } else {
    return clamp01(
      schlickLazanyi(
        metalF0[material.metalID],
        metalF82[material.metalID],
        NoV,
        material.roughness
      )) 
      #ifdef ALBEDO_METAL_TINT
        * material.albedo
      #endif
    ;
  }
}

vec3 brdf(
  Material material,
  vec3 surfaceNormal,
  vec3 geometryNormal,
  vec3 viewPos
) {
  vec3 L = lightDir;
  float faceNoL = clamp01(dot(geometryNormal, L));
  float mappedNoL = clamp01(dot(surfaceNormal, L));

  float NoL = clamp01(mappedNoL * smoothstep(0.0, 0.1, faceNoL));
  if (NoL <= 0.0) {
    return vec3(0.0);
  }

  vec3 V = normalize(-viewPos);
  vec3 N = surfaceNormal;
  vec3 H = normalize(L + V);

  float NoV = dot(N, V);
  float VoL = dot(V, L);
  float HoV = dot(H, V);

  float alpha = max(1e-3, material.roughness);
  float NoHSquared = getNoHSquared(
    NoL,
    NoV,
    VoL,
    // TODO: use pulsar angular radius in end
    isDay
      ? sunAngularRadius
      : moonAngularRadius
  );
  float NoH = sqrt(NoHSquared);

  vec3 F = clamp01(fresnel(material, HoV));

  // trowbridge-reitz ggx
  float denominator = NoHSquared * (pow2(alpha) - 1.0) + 1.0;
  float D = max0(pow2(alpha) / (PI * pow2(denominator)));

  float G = max0(geometrySmith(N, V, L, material.roughness));

  if (material.metalID != NO_METAL) {
    F *= material.albedo;
  }

  vec3 specular = F * D * G / (4.0 * NoV + 1e-6); // not divided by NoL to cancel multiplication by it later

  // commented out below is an attempt at hammon's diffuse model
  // I scrapped it because I cannot tell the different visually between it and lambert
  // float facing = 0.5 + 0.5 * VoL;
  // float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NoH) / max(1e-6, NoH));
  // float _smooth = 1.05 * (1.0 - pow5(1.0 - NoL)) * (1.0 - pow5(1.0 - NoV));
  // float single = mix(_smooth, rough, material.roughness) / PI;
  // float multi = 0.1159 * material.roughness;
  vec3 diffuse = NoL * material.albedo / PI; // * (single + material.albedo * multi);

  if (material.metalID != NO_METAL) diffuse = vec3(0.0);

  return (specular + diffuse) *
  areaLightNormalization(
    max(0.001, material.roughness),
    dot(L, H),
    sunAngularRadius
  );
}

vec3 diffuseBRDF(
  Material material,
  vec3 surfaceNormal,
  vec3 geometryNormal,
  vec3 viewPos
) {
  if (material.metalID != NO_METAL) {
    return vec3(0.0);
  }

  vec3 L = lightDir;
  float faceNoL = clamp01(dot(geometryNormal, L));
  float mappedNoL = clamp01(dot(surfaceNormal, L));

  if (faceNoL <= 0.0) {
    return vec3(0.0);
  }

  vec3 V = normalize(-viewPos);
  vec3 H = normalize(L + V);
  float HoV = dot(H, V);

  return material.albedo /
  PI *
  clamp01(mappedNoL * smoothstep(0.0, 0.1, faceNoL));
}

vec3 specularBRDF(
  Material material,
  vec3 surfaceNormal,
  vec3 geometryNormal,
  vec3 viewPos
) {
  vec3 L = lightDir;
  float faceNoL = clamp01(dot(geometryNormal, L));
  float mappedNoL = clamp01(dot(surfaceNormal, L));

  float NoL = clamp01(mappedNoL * smoothstep(0.0, 0.1, faceNoL));

  if (NoL <= 0.0) {
    return vec3(0.0);
  }

  vec3 V = normalize(-viewPos);
  vec3 N = surfaceNormal;
  vec3 H = normalize(L + V);

  float NoV = dot(N, V);
  float VoL = dot(V, L);
  float HoV = dot(H, V);

  float alpha = max(1e-3, material.roughness);
  float NoHSquared = getNoHSquared(
    NoL,
    NoV,
    VoL,
    isDay
      ? sunAngularRadius
      : moonAngularRadius
  );
  // float NoHSquared = pow2(dot(N, H));

  vec3 F = clamp01(fresnel(material, HoV));

  // trowbridge-reitz ggx
  float denominator = NoHSquared * (pow2(alpha) - 1.0) + 1.0;
  float D = max0(pow2(alpha) / (PI * pow2(denominator)));

  float G = max0(geometrySmith(N, V, L, material.roughness));

  if (material.metalID != NO_METAL) {
    F *= material.albedo;
  }

  vec3 specular = F * D * G / (4.0 * NoV + 1e-6);

  return max0(
    specular *
      areaLightNormalization(
        max(0.001, material.roughness),
        dot(L, H),
        sunAngularRadius
      )
  );

}

#endif // BRDF_GLSL
