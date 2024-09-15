#ifndef WATER_FOG_INCLUDE
#define WATER_FOG_INCLUDE

const float waterAbsorbance = 0.1;

vec4 waterFog(vec4 color, vec3 frontPos, vec3 backPos){
  float distance = distance(frontPos, backPos);

  float transmittance = exp(-waterAbsorbance * distance);
  
  vec4 waterFogColor = vec4(WATER_COLOR.rgb, 1.0);
  // return mix(color, waterFogColor, 1.0 - transmittance);

  color.rgb = mix(color.rgb, WATER_COLOR.rgb, 1.0 - transmittance);
  color.a = (1.0 - (1.0 - color.a) * transmittance);

  return color;
}

#endif