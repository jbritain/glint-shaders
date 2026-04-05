/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
#include "/lib/common.glsl"

#ifdef vsh
out vec2 texcoord;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/material/material.glsl"
#include "/lib/util/blur.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

// #ifdef MIPMAP
const bool colortex0MipmapEnabled = true;
// #endif

void main() {
  bool inWater = isEyeInWater == 1;
  Material material;
  material = unpackMaterial(texture(colortex2, texcoord).rg);
  bool isWater = materialIsWater(material.id);
  float depth;

  if (inWater) {
    float depth = texture(depthtex0, texcoord).r;
  } else {
    float depth = texture(depthtex1, texcoord).r;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));

  color = texture(colortex0, texcoord);
  if (isWater || inWater) {
    float lod = smoothstep(0.0, 8.0, length(viewPos)) * 8;
    color = mix(
      color,
      blur13(colortex0, texcoord, int(lod), DIRECTION),
      clamp01(lod)
    );
  }

}

#endif
