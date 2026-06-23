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

out vec3 normal;
out vec3 playerPos;

void main() {
  normal = gl_Normal;
  gl_Position = ftransform();
  playerPos = transformView(
    (gbufferProjectionInverse * gl_Position).xyz,
    gbufferModelViewInverse
  );
}
#endif

// ==============================================================================================

#ifdef fsh

#include "/lib/util/gbuffer.glsl"
#include "/lib/material/material.glsl"
#include "/photonics/photonics.glsl"

in vec3 normal;
in vec3 playerPos;

/* RENDERTARGETS: 1,2 */

layout(location = 0) out uvec3 gbufferData;
layout(location = 1) out uvec2 materialData;

void main() {
  discard;
  // vec3 screenPos = gl_FragCoord.xyz;

  // Gbuffer gbuffer;

  // gbuffer.geometryNormal = normal;
  // gbuffer.surfaceNormal = normal;
  // gbuffer.lightmap = vec2(0.0);

  // vec3 worldPos = playerPos + cameraPosition;

  // RayJob ray = RayJob(
  //   worldPos - world_offset - 0.001f * normal, // Ray origin
  //   normalize(playerPos - gbufferModelViewInverse[3].xyz), // Ray direction
  //   vec3(0),
  //   vec3(0),
  //   vec3(0),
  //   false
  // );

  // ray_constraint = ivec3(ray.origin);
  // trace_ray(ray);

  // if (!ray.result_hit) discard;
  // if (ray.result_normal == vec3(0.0)) ray.result_normal = normal;

  // vec3 playerPos = ray.result_position + world_offset - cameraPosition;
  // vec3 hitViewPos = transformView(playerPos, gbufferProjection);
  // gl_FragDepth =
  //   0.5 *
  //     (-gbufferProjection[2].z * -hitViewPos.z + gbufferProjection[3].z) /
  //     -hitViewPos.z +
  //   0.5;

  // Material material = defaultMaterial;
  // material.albedo = pow(ray.result_color, vec3(2.2));
  // gbufferData = packGbuffer(gbuffer);
  // materialData = packMaterial(material);
}

#endif
