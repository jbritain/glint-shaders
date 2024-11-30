/*
    Copyright (c) 2024 Joshua Britain
    Licensed under the GNU General Public License, Version 3

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net
*/

#ifndef SPECULAR_SHADING_INCLUDE
#define SPECULAR_SHADING_INCLUDE

#include "/lib/util.glsl"
#include "/lib/util/material.glsl"
#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/textures/blueNoise.glsl"
#include "/lib/util/uvmap.glsl"

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float getNoHSquared(float NoL, float NoV, float VoL, float radius) {
  float radiusCos = cos(radius);
	float radiusTan = tan(radius);
  
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

float schlickGGX(float NoV, float K) {
  float nom   = NoV;
  float denom = NoV * (1.0 - K) + K;

  return nom / denom;
}
  
float geometrySmith(vec3 N, vec3 V, vec3 L, float K) {
  float NoV = max(dot(N, V), 0.0);
  float NoL = max(dot(N, L), 0.0);
  float ggx1 = schlickGGX(NoV, K);
  float ggx2 = schlickGGX(NoL, K);

  return ggx1 * ggx2;
}

// trowbridge-reitz ggx
// https://mudstack.com/blog/tutorials/physically-based-rendering-study-part-2/
float calculateSpecularHighlight(vec3 N, vec3 V, vec3 L, float roughness){
  float alpha = roughness;
	float dotNHSquared = getNoHSquared(dot(N, L), dot(N, V), dot(V, L), ATMOSPHERE.sun_angular_radius);
	float distr = dotNHSquared * (alpha - 1.0) + 1.0;
	return alpha / (PI * pow2(distr));
}

mat3 generateTBN(vec3 normal){
  vec3 tangent = normal.y == 1.0 ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(0.0, 1.0, 0.0), normal));
  vec3 bitangent = normalize(cross(tangent, normal));
  return mat3(tangent, bitangent, normal);
}

vec3 schlick(Material material, float NoV){
  const vec3 f0 = material.f0;
  const vec3 f82 = material.f82;
  if(material.metalID == NO_METAL){ // normal schlick approx.
    return vec3(f0 + (1.0 - f0) * pow5(1.0 - NoV));
  } else { // lazanyi schlick - https://www.shadertoy.com/view/DdlGWM
    vec3 a = (823543./46656.) * (f0 - f82) + (49./6.) * (1.0 - f0);

    float p1 = 1.0 - NoV;
    float p2 = p1*p1;
    float p4 = p2*p2;

    return clamp01(f0 + ((1.0 - f0) * p1 - a * NoV * p2) * p4);
  }
}

// by Zombye
// https://discordapp.com/channels/237199950235041794/525510804494221312/1118170604160421918
vec3 sampleVNDFGGX(
  vec3 viewerDirection, // Direction pointing towards the viewer, oriented such that +Z corresponds to the surface normal
  vec2 alpha, // Roughness parameter along X and Y of the distribution
  vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
  // Transform viewer direction to the hemisphere configuration
  viewerDirection = normalize(vec3(alpha * viewerDirection.xy, viewerDirection.z));

  // Sample a reflection direction off the hemisphere
  const float tau = 6.2831853; // 2 * pi
  float phi = tau * xy.x;
  float cosTheta = fma(1.0 - xy.y, 1.0 + viewerDirection.z, -viewerDirection.z);
  float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
  vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

  // Evaluate halfway direction
  // This gives the normal on the hemisphere
  vec3 halfway = reflected + viewerDirection;

  // Transform the halfway direction back to hemiellispoid configuation
  // This gives the final sampled normal
  return normalize(vec3(alpha * halfway.xy, halfway.z));
}

vec3 SSRSample(vec3 viewOrigin, vec3 viewRay, float skyLightmap, float jitter, float roughness, out bool hit, out float fadeFactor){
  vec3 reflectionPos = vec3(0.0);

  vec3 worldDir = mat3(gbufferModelViewInverse) * viewRay;
  vec2 environmentUV = mapSphere(normalize(worldDir));


  vec3 reflectedColor = vec3(0.0);
  hit = rayIntersects(viewOrigin, viewRay, roughness < 0.01 ? 4 : 8, jitter, true, reflectionPos, true);

  if(texelFetch(colortex4, ivec2(reflectionPos.xy * vec2(viewWidth, viewHeight)), 0).a >= 1.0){
    hit = false;
    fadeFactor = 1.0;
    return vec3(0.0);
  }

  if(roughness == 0.0){
    reflectedColor = texture(colortex4, reflectionPos.xy).rgb;
  } else {
    reflectedColor = textureLod(colortex4, reflectionPos.xy, mix(2, 8, smoothstep(roughness, 0.0, ROUGH_REFLECTION_THRESHOLD))).rgb;
  }

  #ifdef SSR_FADE
  fadeFactor = smoothstep(0.8, 1.0, max2(abs(reflectionPos.xy - 0.5)) * 2);
  #else
  fadeFactor = float(!hit);
  #endif
  
  return reflectedColor;
}

vec4 screenSpaceReflections(in vec4 reflectedColor, vec2 lightmap, vec3 normal, vec3 viewPos, Material material, vec3 fresnel){

  vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  if(material.roughness < 0.01){ // we only need to make one reflection sample for perfectly smooth surfaces
    vec3 reflectedRay = reflect(normalize(viewPos), normal);
    float jitter = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight), frameCounter).x;
    bool hit;
    float fadeFactor;

    reflectedColor.rgb = SSRSample(viewPos, reflectedRay, lightmap.y, jitter, material.roughness, hit, fadeFactor);

    if(!hit || fadeFactor > 0.0){
      vec3 worldDir = mat3(gbufferModelViewInverse) * reflectedRay;
      vec2 environmentUV = mapSphere(normalize(worldDir));
      vec3 skyReflection = texture(colortex9, environmentUV).rgb;
      if(isEyeInWater == 1){
        skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(worldDir.y));
      } else {
        skyReflection *= lightmap.y;
      }
      reflectedColor.rgb = mix(reflectedColor.rgb, skyReflection, fadeFactor);
    }

  } else { // we must take multiple samples

    // we need a TBN to get into tangent space for the VNDF
    mat3 tbn = generateTBN(normal);

    const int samples = SSR_SAMPLES;//int(mix(float(SSR_SAMPLES), 1.0, 1.0 - max3(fresnel)));

    float skyWeight = 0.0;

    for(int i = 0; i < samples; i++){
      vec3 noise = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight), i + frameCounter * samples).xyz;
      vec3 roughNormal = tbn * (sampleVNDFGGX(normalize(-viewPos * tbn), vec2(material.roughness), noise.xy));
      vec3 reflectedRay = reflect(normalize(viewPos), roughNormal);
      bool hit;
      float fadeFactor;
      vec3 originalColor = reflectedColor.rgb;
      vec3 reflection = SSRSample(viewPos, reflectedRay, lightmap.y, noise.z, material.roughness, hit, fadeFactor);
      if(hit){
        reflectedColor.rgb += reflection;
      } else {
        vec3 worldDir = mat3(gbufferModelViewInverse) * reflectedRay;
        vec2 environmentUV = mapSphere(worldDir);
        vec3 skyReflection = texture(colortex9, environmentUV).rgb;
        if(isEyeInWater == 1){
          skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(worldDir.y));
        } else {
          skyReflection *= lightmap.y;
        }

        reflectedColor.rgb += mix(originalColor.rgb, skyReflection, fadeFactor);
      }
    }
    reflectedColor /= SSR_SAMPLES;
  }

  #ifdef gbuffers_hand
    reflectedColor.a = 1.0; // not sure why I need to do this
  #endif

  return reflectedColor;
}

vec4 getSpecularShading(vec4 color, vec2 lightmap, vec3 normal, vec3 viewPos, Material material, vec3 sunlight, vec3 skyLightColor, vec3 fresnel){
  vec3 V = normalize(-viewPos);
  vec3 N = normal;
  vec3 L = normalize(shadowLightPosition);
  
  float NoV = dot(N, V);

  vec3 specularHighlight = calculateSpecularHighlight(N, V, L, max(material.roughness, 0.0001)) * sunlight * clamp01(geometrySmith(N, V, L, material.roughness));

  vec4 reflectedColor = vec4(0.0, 0.0, 0.0, 1.0);

  #ifdef SSR
  if (material.roughness <= ROUGH_REFLECTION_THRESHOLD){
    reflectedColor = screenSpaceReflections(reflectedColor, lightmap, normal, viewPos, material, fresnel);
  } else {
    reflectedColor = color;
  }
  
  #else
  if(material.roughness < 0.01){
    vec3 reflectedDir = mat3(gbufferModelViewInverse) * reflect(normalize(viewPos), normal);
    vec2 environmentUV = mapSphere(reflectedDir);
    vec3 skyReflection = texture(colortex9, environmentUV).rgb;
    if(isEyeInWater == 1){
      skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(worldDir.y));
    } else {
      skyReflection *= lightmap.y;
    }

    reflectedColor.rgb = skyReflection;
  } else {
    reflectedColor = color;
  }
  #endif

  reflectedColor.rgb += specularHighlight;

  if(material.metalID != NO_METAL){
    reflectedColor.rgb *= material.albedo;
  }

  return reflectedColor;
}

vec4 shadeSpecular(in vec4 color, vec2 lightmap, vec3 normal, vec3 viewPos, Material material, vec3 sunlight, vec3 skyLightColor){
  if(material.roughness == 1.0){
    return color;
  }

  vec3 V = normalize(-viewPos);
  vec3 N = normal;
  
  float NoV = dot(N, V);

  vec3 fresnel = schlick(material, NoV);
  vec4 reflectedColor = getSpecularShading(color, lightmap, normal, viewPos, material, sunlight, skyLightColor, fresnel);

  if(reflectedColor == vec4(-1.0)){
    reflectedColor = color;
  }

  color = mix(color, reflectedColor, vec4(clamp01(fresnel), clamp01(length(fresnel))));
  return color;
}

#endif