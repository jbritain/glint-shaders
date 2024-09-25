#ifndef REFLECTIVE_SHADOW_MAP_INCLUDE
#define REFLECTIVE_SHADOW_MAP_INCLUDE

vec3 reflectShadowMap(vec3 faceNormal, vec3 feetPlayerPos, vec3 sunlightColor){
  vec3 worldFaceNormal = mat3(gbufferModelViewInverse) * faceNormal;

  vec4 shadowClipPos = getShadowClipPos(feetPlayerPos);
  vec3 cloudShadowScreenPos = getUndistortedShadowScreenPos(shadowClipPos, faceNormal).xyz;

  // assumption - if we are in cloud shadow, so is the indirect light caster
  vec3 cloudShadow = texture(colortex6, cloudShadowScreenPos.xy).rgb;

  if(cloudShadow * sunlightColor == 0.0){
    return vec3(0.0);
  }

  // assumption - if we are in direct sunlight, the indirect lighting will not be noticeable
  vec3 shadowScreenPos = getShadowScreenPos(shadowClipPos, faceNormal).xyz;
  if(shadow2D(shadowtex0HW, shadowScreenPos) == 1.0 && dot(worldFaceNormal, lightVector) > 0.9){
    return vec3(0.0);
  }

  float radius = GI_RADIUS;

  int samples = GI_SAMPLES;

  vec3 GI = vec3(0.0);

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter);
  float normalizationFactor = 2.0 * pow2(radius);

  for(int i = 0; i < samples; i++){
    vec2 offset = weightedVogelDiscSample(i, samples, jitter) * radius;

    vec4 offsetPos = shadowClipPos + vec4(offset, 0.0, 0.0);

    vec3 offsetScreenPos = getShadowScreenPos(offsetPos, faceNormal).xyz;

    vec3 flux = texture(shadowcolor0, offsetScreenPos.xy).rgb;
    vec3 sampleNormal = texture(shadowcolor1, offsetScreenPos.xy).yzx; // this is in world space

    if(sampleNormal.z == 1.0){ // material ID is in the r channel which we put into the z/b component, and it's 1.0 for entities
      continue;
    }

    // z component reconstruction
    sampleNormal = sampleNormal * 2.0 - 1.0;
    sampleNormal.z = sqrt(1.0 - dot(sampleNormal.xy, sampleNormal.xy));
    sampleNormal = normalize(sampleNormal);
    sampleNormal = mat3(shadowModelViewInverse) * sampleNormal;
    vec3 samplePos = texture(shadowcolor2, offsetScreenPos.xy).xyz;


    flux *= max0(dot(feetPlayerPos - samplePos, sampleNormal));
    flux *= max0(dot(worldFaceNormal, samplePos - feetPlayerPos));
    flux /= pow4(distance(samplePos, feetPlayerPos));
    flux *= pow2(float(i)/samples);

    GI += flux;
  }

  GI /= samples;
  GI *= normalizationFactor;
  // GI *= GI_BRIGHTNESS;

  GI *= sunlightColor * cloudShadow;

  return GI;
}

#endif