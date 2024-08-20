vec3 shadeDiffuse(vec3 color, vec2 lmcoord, vec3 normal, vec3 faceNormal){
      float lightmapSky = (lmcoord.g - 1.0/32.0) * 16.0/15.0;
    float lightmapBlock = (lmcoord.r - 1.0/32.0) * 16.0/15.0;

    vec3 sunlightColor = getSky(SUN_VECTOR, true);
    vec3 skyLightColor = getSky(vec3(0, 1, 0), false);

    vec3 skyLight = skyLightColor * SKYLIGHT_STRENGTH * lightmapSky;
    vec3 artificial = TORCH_COLOR * lightmapBlock;
}