/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/shadow.glsl
    - Shadow map
*/

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
  out vec3 normal;
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
    normal = gl_NormalMatrix * gl_Normal; // shadow view space

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

  uniform int renderStage;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  flat in int materialID;
  in vec3 feetPlayerPos;
  in vec3 shadowViewPos;
  in vec3 normal;

  #include "/lib/util.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/materialIDs.glsl"
  #include "/lib/lighting/shadowBias.glsl"

  /* DRAWBUFFERS:012 */
  layout(location = 0) out vec4 color;
  layout(location = 1) out vec4 shadowData;
  layout(location = 2) out vec4 worldPos;

  void main(){
    color = texture(gtexture, texcoord) * glcolor;
    
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
    
    float encodedMaterialID = clamp01(float(materialID - 10000) * rcp(255.0));
    vec2 encodedNormal = normal.xy * 0.5 + 0.5;

    // so we can detect entities casting shadows since for stuff like GI it looks wrong
    if(renderStage == MC_RENDER_STAGE_ENTITIES){
      encodedMaterialID = 1.0;
    }

    shadowData = vec4(encodedMaterialID, encodedNormal, 1.0);
    worldPos = vec4(feetPlayerPos, 0.0);
  }
  
#endif