#

# Implementation Details
`block.properties` IDs are handled by [block-wrangler](https://camplowell.github.io/block_wrangler) in `block_properties.py`

Translucents are fully forward rendered in gbuffers.
Opaques are diffuse shaded in `deferred`.
Specular is only applied to the front layer (i.e not opaques behind translucents)

# Buffers

`colortex0` scene colour
`colortex1` gbuffer data - albedo, material ID, face normal, lightmap
`colortex2` gbuffer data - mapped normal, specular map data

# Passes
`deferred` diffuse shading, sky, cloud generation

`composite` specular lighting, cloud blur pass
`composite1` cloud blending

