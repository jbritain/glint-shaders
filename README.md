# Credits
- Eric Bruneton - [Precomputed Atmospheric Scattering](https://ebruneton.github.io/precomputed_atmospheric_scattering/) (combined texture from [Ebin](https://github.com/BruceKnowsHow/ebin-shader))

# Implementation Details
`block.properties` IDs are handled by [block-wrangler](https://camplowell.github.io/block_wrangler) in `block_properties.py`

Translucents are fully forward rendered in gbuffers.
Opaques are diffuse shaded in `deferred`.

# Buffers

`colortex0` scene colour
`colortex1` gbuffer data - albedo, material ID, face normal, lightmap
`colortex2` gbuffer data - mapped normal, specular map data
`colortex3` clouds
`colortex4` previous frame data - color rgb, depth

# Passes
`deferred` diffuse shading, sky, cloud generation (and blending)

`composite99` writing frame data for next frame to access (previous frame data)

`final` post processing