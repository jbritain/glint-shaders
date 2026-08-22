/*
    Copyright (c) 2026 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/
#include "/lib/common.glsl"

#ifdef vsh
flat out uint weatherMask;
out vec2 texcoord;

#include "/mcwind/mcwind.glsl"

void main() {
  vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  #ifdef MCWIND
  vec3 feetPlayerPos = transformView(viewPos, gbufferModelViewInverse);
  float topWeight = clamp(feetPlayerPos.y / 16.0 + 0.5, 0.0, 1.0);
  feetPlayerPos += mcw_rainLean(feetPlayerPos + cameraPosition, topWeight);
  viewPos = transformView(feetPlayerPos, gbufferModelView);
  #endif
  gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
  if (gl_Color.b > gl_Color.r) {
    weatherMask = RAIN;
  } else {
    weatherMask = SNOW;
  }
  weatherMask = RAIN;
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif

// ==============================================================================================

#ifdef fsh

/* RENDERTARGETS: 17 */

layout(location = 0) out uint outWeatherMask;

flat in uint weatherMask;
in vec2 texcoord;

void main() {
  if (texture(gtexture, texcoord).a < alphaTestRef) {
    discard;
  }

  outWeatherMask = weatherMask;
}

#endif
