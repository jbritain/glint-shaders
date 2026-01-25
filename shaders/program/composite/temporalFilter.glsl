/*
    Copyright (c) 2025 Josh Britain (jbritain)
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

// ===========================================================================================

#ifdef fsh
in vec2 texcoord;

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 newHistory;

const ivec2 neighbourhoodOffsets[8] = ivec2[8](
  ivec2(1, 1),
  ivec2(1, -1),
  ivec2(-1, 1),
  ivec2(-1, -1),
  ivec2(1, 0),
  ivec2(0, 1),
  ivec2(-1, 0),
  ivec2(0, -1)
);

void main() {
  float depth = texture(depthtex0, texcoord).r;

  color = texture(colortex0, texcoord);

  float opaqueDepth = texture(depthtex1, texcoord).r;
  vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
  newHistory.a = screenSpaceToViewSpace(opaqueDepth);

  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  feetPlayerPos += cameraPosition;
  feetPlayerPos -= previousCameraPosition;
  vec3 previousViewPos = (gbufferPreviousModelView *
    vec4(feetPlayerPos, 1.0)).xyz;
  vec4 previousClipPos = gbufferPreviousProjection * vec4(previousViewPos, 1.0);
  vec3 previousScreenPos = previousClipPos.xyz / previousClipPos.w * 0.5 + 0.5;
  vec3 actualPreviousViewPos = previousViewPos;

  bool rejectSample = clamp01(previousScreenPos.xy) != previousScreenPos.xy;

  vec4 historyColor = texture(colortex5, previousScreenPos.xy);
  actualPreviousViewPos.z = screenSpaceToViewSpace(historyColor.a);
  // rejectSample = rejectSample || distance(previousViewPos, actualPreviousViewPos) > 0.1;

  // neighbourhood clamping
  vec3 maxCol = vec3(0.0);
  vec3 minCol = vec3(999999999.0);

  for (int i = 0; i < 8; i++) {
    vec3 neighbourhoodSample = texelFetch(
      colortex0,
      ivec2(gl_FragCoord.xy) + neighbourhoodOffsets[i],
      0
    ).rgb;
    maxCol = max(maxCol, neighbourhoodSample);
    minCol = min(minCol, neighbourhoodSample);
  }

  historyColor.rgb = clamp(historyColor.rgb, minCol, maxCol);

  float weight = rejectSample ? 0.0 : depth != opaqueDepth ? 0.5 : 0.7;

  color = mix(color, historyColor, weight);

  newHistory.rgb = color.rgb;
}

#endif
