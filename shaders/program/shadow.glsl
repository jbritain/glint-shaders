#include "/lib/settings.glsl"

#ifdef vsh

  in vec4 mc_Entity;
  in vec3 at_midBlock;

  uniform mat4 shadowProjection;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;
  uniform vec3 shadowLightPosition;
  uniform float near;
  uniform float far;
  uniform int worldTime;
  uniform int worldDay;
  uniform vec3 cameraPosition;

  uniform bool hasSkylight;

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  flat out int materialID;
  out vec3 feetPlayerPos;
  out vec3 shadowViewPos;

  #include "/lib/util.glsl"
  #include "/lib/lighting/shadowBias.glsl"
  #include "/lib/misc/sway.glsl"

  void main(){

    if(!hasSkylight){
      gl_Position = vec4(1e2);
      return;
    }

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    materialID = int(mc_Entity.x + 0.5);

    shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    worldPos = getSway(materialID, worldPos, at_midBlock);
    feetPlayerPos = worldPos - cameraPosition;
    shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;

    gl_Position = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);

    
    gl_Position.xyz = distort(gl_Position.xyz);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh
  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D shadowtex1;

  uniform int worldTime;
  uniform int worldDay;
  uniform float frameTimeCounter;

  uniform vec3 cameraPosition;
  uniform vec3 shadowLightPosition;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 shadowProjectionInverse;
  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  flat in int materialID;
  in vec3 feetPlayerPos;
  in vec3 shadowViewPos;

  #include "/lib/util.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/lighting/shadowBias.glsl"

  void main(){
    vec4 color = texture(gtexture, texcoord) * glcolor;
    
    if(materialIsWater(materialID)){
      vec3 waveNormal = waveNormal(feetPlayerPos.xz + cameraPosition.xz, vec3(0.0, 1.0, 0.0), WAVE_E, WAVE_DEPTH);
      vec3 lightDir = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

      float opaqueDepth = getShadowDistance(texture(shadowtex1, gl_FragCoord.xy / shadowMapResolution).r); // how far away from the sun is the opaque fragment shadowed by the water?

      float waterDepth = shadowViewPos.z - opaqueDepth;

      vec3 refracted = refract(lightDir, waveNormal, 1.0/1.33);

      vec3 oldPos = feetPlayerPos;
      vec3 newPos = feetPlayerPos + refracted * waterDepth;

      // https://medium.com/@evanwallace/rendering-realtime-caustics-in-webgl-2a99a29a0b2c
      // I do not understand entirely what this does but it seems to work
      float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
      float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

      color.a = 1.0 - oldArea / newArea;
    }

	  gl_FragData[0] = color;
    gl_FragData[1] = vec4(clamp01(float(materialID - 10000) * rcp(255.0)), 0.0, 0.0, 1.0);
  }
  
#endif