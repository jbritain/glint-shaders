# Passes

Diffuse lighting is done in gbuffers

## Deferred
### `deferred`
Sky

## Composites

## `final`
Tonemap

# Buffers
## `colortex0`
Main frame buffer

## `colortex1`
Opaques normal

## `colortex2`
Opaques lightmap

## `colortex3`
Opaques PBR

## `colortex4`
Translucents normal (alpha is 1.0 if block is water, otherwise 0.5)

## `colortex5`
Translucents lightmap

## `colortex6`
Translucents PBR

## `colortex7`
Translucents