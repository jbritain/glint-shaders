#include "/lib/settings.glsl"

#ifdef vsh

  in vec4 mc_Entity;
  in vec3 at_midBlock;

  uniform mat4 shadowProjection;
  uniform mat4 shadowModelView;
  uniform mat4 shadowModelViewInverse;
  uniform vec3 shadowLightPosition;
  uniform float near;
  uniform float far;
  uniform int worldTime;
  uniform int worldDay;
  uniform vec3 cameraPosition;

  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  flat out int materialID;
  out vec3 feetPlayerPos;

  #include "/lib/util.glsl"
  #include "/lib/lighting/shadowBias.glsl"
  #include "/lib/misc/sway.glsl"

  void main(){
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    materialID = int(mc_Entity.x + 0.5);

    vec3 shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
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

  uniform int worldTime;
  uniform int worldDay;

  uniform vec3 cameraPosition;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  flat in int materialID;
  in vec3 feetPlayerPos;

  #include "/lib/util.glsl"
  #include "/lib/water/waveNormals.glsl"
  #include "/lib/util/materialIDs.glsl"

  void main(){
    vec4 color = texture(gtexture, texcoord) * glcolor;

    if(materialIsWater(materialID)){
      color = WATER_COLOR;
      color.a = sqrt(getwaves(feetPlayerPos.xz + cameraPosition.xz, ITERATIONS_NORMAL));
    }
    

	  gl_FragData[0] = color;
  }
  
#endif