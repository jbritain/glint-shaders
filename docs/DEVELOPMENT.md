
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
`colortex6` cloud shadow map (256x256)
`colortex7` cloud scattering (transmittance in alpha)
`colortex8` fog scattering (transmittance in alpha)
`colortex9` sky environment map (256x256)
`colortex10` global illumination

# Passes
`prepare` cloud shadow map
`prepare1` sky environment map

`deferred` rsm global illumination
`deferred1` global illumination filtering
`deferred2` opaques shading, sky
`deferred3` cloud generation
`deferred4` cloud upscaling (`volumetricUpscaling.glsl`)
`deferred5` cloud filtering and blending (`volumetricFilter.glsl`)

`composite` some fog, translucency blending
`composite1` cloud fog
`composite2` cloud fog upscaling (`volumetricUpscaling.glsl`)
`composite3` cloud fog filtering and blending (`volumetricFilter.glsl`)

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

# Things to know
- Sampling shadows in any program with `/lib/water/waterFog.glsl` included will make caustics very faint. This is so the fog doesn't look weird.