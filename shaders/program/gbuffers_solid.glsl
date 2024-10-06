/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/gbuffers_solid.glsl
    - Solid terrain
    - Solid entities
*/

#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 lmcoord;
  out vec2 texcoord;
  out vec4 glcolor;
  out mat3 tbnMatrix;
  flat out int materialID;
  out vec3 viewPos;

  out vec2 singleTexSize;
  out ivec2 pixelTexSize;
  out vec4 textureBounds;

  uniform int worldTime;
  uniform int worldDay;
  uniform float frameTimeCounter;

  uniform mat4 gbufferModelView;
  uniform mat4 gbufferModelViewInverse;

  uniform mat4 gbufferProjection;

  uniform vec3 cameraPosition;

  uniform ivec2 atlasSize;

  in vec4 at_tangent;
  in vec2 mc_Entity;
  in vec3 at_midBlock;
  in vec2 mc_midTexCoord;

  #include "/lib/util.glsl"
  #include "/lib/misc/sway.glsl"

  void main() {
    materialID = int(mc_Entity.x + 0.5);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    tbnMatrix[0] = normalize(gl_NormalMatrix * at_tangent.xyz);
    tbnMatrix[2] = normalize(gl_NormalMatrix * gl_Normal);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * at_tangent.w);

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    worldPos = getSway(materialID, worldPos, at_midBlock);
    feetPlayerPos = worldPos - cameraPosition;
    viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;

    gl_Position = gbufferProjection * vec4(viewPos, 1.0);

    vec2 halfSize      = abs(texcoord - mc_midTexCoord);
    textureBounds = vec4(mc_midTexCoord.xy - halfSize, mc_midTexCoord.xy + halfSize);

    singleTexSize = halfSize * 2.0;
    pixelTexSize  = ivec2(singleTexSize * atlasSize);
  }
#endif
//------------------------------------------------------------------
#ifdef fsh

  uniform sampler2D lightmap;
  uniform sampler2D gtexture;
  uniform sampler2D normals;
  uniform sampler2D specular;

  uniform vec4 entityColor;

  uniform float alphaTestRef;

  uniform vec3 cameraPosition;
  uniform vec3 shadowLightPosition;

  uniform mat4 gbufferModelViewInverse;
  uniform mat4 gbufferProjection;
  uniform mat4 gbufferProjectionInverse;

  in vec2 lmcoord;
  in vec2 texcoord;
  in vec4 glcolor;
  in mat3 tbnMatrix;
  flat in int materialID;
  in vec3 viewPos;

  uniform float viewWidth;
  uniform float viewHeight;

  in vec2 singleTexSize;
  in ivec2 pixelTexSize;
  in vec4 textureBounds;

  #include "/lib/util.glsl"
  #include "/lib/post/tonemap.glsl"
  #include "/lib/util/packing.glsl"
  #include "/lib/misc/parallax.glsl"

  vec3 getMappedNormal(vec2 texcoord){
    vec3 mappedNormal = texture(normals, texcoord).rgb;
    mappedNormal = mappedNormal * 2.0 - 1.0;
    mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
    
    return tbnMatrix * mappedNormal;
  }

  /* RENDERTARGETS: 1,2,10 */
  layout(location = 0) out vec4 outData1; // albedo, material ID, face normal, lightmap
  layout(location = 1) out vec4 outData2; // mapped normal, specular map data
  layout(location = 2) out vec4 outData3; // nothing in the rgb but parallax shadow in the a

  void main() {
    float parallaxSunlight = 1.0;
    #ifdef POM
    vec2 texcoord = texcoord;
    vec2 dx = dFdx(texcoord);
    vec2 dy = dFdy(texcoord);
    vec3 parallaxPos;
    if(length(viewPos) < 32.0){
      vec2 pomJitter = blueNoise(gl_FragCoord.xy / vec2(viewWidth, viewHeight)).rg;
      texcoord = getParallaxTexcoord(texcoord, viewPos, tbnMatrix, parallaxPos, dx, dy, pomJitter.x);
      #ifdef POM_SHADOW
      parallaxSunlight = getParallaxShadow(parallaxPos, tbnMatrix, dx, dy, pomJitter.y) ? smoothstep(length(viewPos), 0.0, 32.0) : 1.0;
      #endif
    }
    #endif
    outData3 = vec4(0.0, 0.0, 0.0, parallaxSunlight);

    vec4 color;
    color = texture(gtexture, texcoord) * glcolor;
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
    color.rgb = gammaCorrect(color.rgb);

    if (color.a < alphaTestRef) {
      discard;
    }

    vec2 lightmap = (lmcoord - 1.0/32.0) * 16.0/15.0;

    #ifdef NORMAL_MAPS
      vec3 mappedNormal = getMappedNormal(texcoord);
    #else
      vec3 mappedNormal = faceNormal;
    #endif


    // encode gbuffer data
    outData1.x = pack2x8F(color.r, color.g);
    outData1.y = pack2x8F(color.b, clamp01(float(materialID - 10000) * rcp(255.0)));
    outData1.z = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * tbnMatrix[2]));
    outData1.w = pack2x8F(lightmap);

    #ifdef SPECULAR_MAPS
    vec4 specularData = texture(specular, texcoord);
    #else
    vec4 specularData= vec4(0.0);
    #endif

    outData2.x = pack2x8F(encodeNormal(mat3(gbufferModelViewInverse) * mappedNormal));
    outData2.y = pack2x8F(specularData.rg);
    outData2.z = pack2x8F(specularData.ba);
  }
#endif