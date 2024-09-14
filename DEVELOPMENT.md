
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
`colortex3` stars [gbuffers > deferred] translucents [gbuffers translucent>]
`colortex4` previous frame data - color rgb, opaque depth
`colortex5` unused
`colortex6` clouds

# Passes
`deferred` opaques shading, sky, cloud generation
`deferred1` cloud blur pass (horizontal)
`deferred2` cloud blur (vertical) and blending with opaques

`composite` some fog, translucency blending
`composite99` writing frame data for next frame to access (previous frame data)

`final` post processing