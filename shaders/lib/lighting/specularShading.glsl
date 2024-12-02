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
#include "/lib/lighting/brdf.glsl"


mat3 generateTBN(vec3 normal){
  vec3 tangent = normal.y == 1.0 ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(0.0, 1.0, 0.0), normal));
  vec3 bitangent = normalize(cross(tangent, normal));
  return mat3(tangent, bitangent, normal);
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

vec3 screenSpaceReflections(vec2 lightmap, vec3 normal, vec3 viewPos, Material material, out vec3 fresnel){

  vec3 reflectedColor = vec3(0.0);

  vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  if(material.roughness < 0.01){ // we only need to make one reflection sample for perfectly smooth surfaces

    float NoV = clamp01(dot(normal, normalize(-viewPos)));

    vec3 noise = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight), frameCounter).xyz;
    vec3 reflectedRay = reflect(normalize(viewPos), normal);
    bool hit;
    float fadeFactor;

    fresnel = schlick(material, NoV);

    vec3 reflection = SSRSample(viewPos, reflectedRay, lightmap.y, noise.z, material.roughness, hit, fadeFactor);
    if(hit){
      reflectedColor = reflection;
    } else {
      vec3 worldDir = mat3(gbufferModelViewInverse) * reflectedRay;
      vec2 environmentUV = mapSphere(worldDir);
      vec3 skyReflection = texture(colortex9, environmentUV).rgb;
      if(isEyeInWater == 1){
        skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(worldDir.y));
      } else {
        skyReflection *= lightmap.y;
      }

      reflectedColor = mix(reflection, skyReflection, fadeFactor);
    }
  } else { // we must take multiple samples

    // we need a TBN to get into tangent space for the VNDF
    mat3 tbn = generateTBN(normal);

    const int samples = SSR_SAMPLES;//int(mix(float(SSR_SAMPLES), 1.0, 1.0 - max3(fresnel)));

    float NoV = clamp01(dot(normal, normalize(-viewPos)));

    for(int i = 0; i < samples; i++){
      vec3 noise = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight), i + frameCounter * samples).xyz;
      vec3 roughNormal = tbn * (sampleVNDFGGX(normalize(-viewPos * tbn), vec2(material.roughness), noise.xy));
      vec3 reflectedRay = reflect(normalize(viewPos), roughNormal);
      bool hit;
      float fadeFactor;

      vec3 sampleFresnel = schlick(material, NoV);
      fresnel += sampleFresnel;

      vec3 reflection = SSRSample(viewPos, reflectedRay, lightmap.y, noise.z, material.roughness, hit, fadeFactor);
      if(hit){
        reflectedColor += reflection;
      } else {
        vec3 worldDir = mat3(gbufferModelViewInverse) * reflectedRay;
        vec2 environmentUV = mapSphere(worldDir);
        vec3 skyReflection = texture(colortex9, environmentUV).rgb;
        // vec3 skyReflection = getSky(worldDir, false);
        if(isEyeInWater == 1){
          skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(worldDir.y));
        } else {
          skyReflection *= lightmap.y;
        }

        reflectedColor += mix(reflection, skyReflection, fadeFactor);
      }
    }
    reflectedColor /= samples;
    fresnel /= samples;
  }

  return reflectedColor;
}

vec3 getSpecularColor(vec3 color, vec2 lightmap, vec3 normal, vec3 viewPos, Material material, out vec3 fresnel){
  fresnel = vec3(0.0);
  vec3 reflectedColor;

  #ifdef SSR

    if (material.roughness <= ROUGH_REFLECTION_THRESHOLD){
      reflectedColor = screenSpaceReflections(lightmap, normal, viewPos, material, fresnel);
    } else {
      reflectedColor = color;
    }
  
  #else
    if(material.roughness < 0.01){
      fresnel = schlick(material, clamp01(dot(normal, normalize(-viewPos))));

      vec3 reflectedDir = mat3(gbufferModelViewInverse) * reflect(normalize(viewPos), normal);
      vec2 environmentUV = mapSphere(reflectedDir);
      vec3 skyReflection = texture(colortex9, environmentUV).rgb;
      if(isEyeInWater == 1){
        skyReflection *= mix(exp(-WATER_ABSORPTION * max0(63 - cameraPosition.y)), exp(-WATER_ABSORPTION * 1024), 1.0 - clamp01(reflectedDir.y));
      } else {
        skyReflection *= lightmap.y;
      }

      reflectedColor.rgb = skyReflection;
    } else {
      reflectedColor = color;
    }
  #endif

  if(material.metalID != NO_METAL){
    reflectedColor.rgb *= material.albedo;
  }

  return reflectedColor;
}

#endif