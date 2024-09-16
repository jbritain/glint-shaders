
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
`colortex4` previous frame data - color rgb, opaque depth
`colortex5` hand
`colortex6` clouds

# Passes
`deferred` opaques shading, sky, cloud generation
`deferred1` cloud blur pass (horizontal)
`deferred2` cloud blur (vertical) and blending with opaques

`composite` some fog, translucency blending

`composite89` writing frame data for next frame to access (previous frame data), blending hand

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