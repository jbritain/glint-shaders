[!WARNING] This file may be out of date as I frequently forget to update it.

# Implementation Details
`block.properties` IDs are handled by [block-wrangler](https://camplowell.github.io/block_wrangler) in `block_properties.py`

Translucents are fully forward rendered in gbuffers.
Clouds are blended with translucents in gbuffers as well, however since we don't have depth info for clouds we have to guess whether to blend or not.
Opaques are shaded in `deferred`.
GBuffer data (albedo, PBR, normals) is packed into two buffers.

# Buffers

`colortex0` scene colour
`colortex1` gbuffer data - albedo, material ID, face normal, lightmap
`colortex2` gbuffer data - mapped normal, specular map data
`colortex3` stars [gbuffers > deferred] translucents [gbuffers translucent>composite89] bloom [composite90>]
`colortex4` previous frame data - color RGB, depth A (non-clearing)
`colortex5` hand
`colortex6` cloud shadow map (256x256)
`colortex7` cloud scattering RGB, cloud transmittance A (non-clearing)
`colortex8` volumetric stuff, opaque specular
`colortex9` sky environment map (256x256)
`colortex10` global illumination RGB, opaque parallax shadowing A
`colortex11` SMAA

`shadowcolor0` shadow colour
`shadowcolor1` water mask R

# Passes
`prepare` cloud shadow map
`prepare1` sky environment map

`deferred`  global illumination
`deferred1` global illumination filtering
`deferred2` global illumination filtering
`deferred3` opaques shading, sky
`deferred4` opaques specular shading
`deferred5` clouds

`composite` atmospheric and water fog, translucency blending
`composite1` cloud fog
`composite2` cloud fog blur pass 1
`composite3` cloud fog blending

`composite82` DoF circle of confusion calculation
`composite83` DoF blur
`composite84` DoF blending
`composite85` SMAA edge detection
`composite86` SMAA blend weight calculation
`composite87` SMAA blending

`composite88` luminance calculation for auto exposure
`composite89` writing frame data for next frame to access (previous frame data), blending hand, auto exposure

`composite90` bloom downsample full>A
`composite91` bloom downsample A>B
`composite92` bloom downsample B>C
`composite93` bloom downsample C>D
`composite94` bloom downsample D>E

`composite95` bloom upsample E>D
`composite96` bloom upsample D>C
`composite97` bloom upsample C>B
`composite98` bloom upsample B>A
`composite99` bloom upsample A>full

`final` post processing