# Glint
A work in progress shaderpack for Minecraft.

![](/docs/assets/ss1.png)

## Features
- LabPBR support
- Fully forward rendered translucents even with SSR
- PCSS 'Variable Penumbra' shadows
- Volumetric clouds, fog, and water
- Cloud shadows
- Global illumination
- Auto exposure
- Nice bloom

## The To-Do List
- Cloud shape overhaul
- Biome based weather
- iPBR
- Ambient Occlusion
- Motion blur
- Skyboxes/atmospherics for other dimensions
- Floodfill
- Improve performance
- ~~TAA~~

## Known Issues
- Banners don't render well
- Colours are ghastly
- Reflections on hand broken
- Ghosting on clouds when player moves
- Artifacts in atmospheric fog near the horizon
- Water waves broken on AMD
- Artifacts around edge of screen with DoF enabled
- GI noisy and bad

## Acknowledgements
- Eric Bruneton - [Precomputed Atmospheric Scattering](https://ebruneton.github.io/precomputed_atmospheric_scattering/)
- [Capt. Tatsu](https://bitslablab.com/) - FXAA from [BSL Shaders](https://bitslablab.com/bslshaders/)
- [Ary](https://github.com/TinyAry123) - SMAA Implementation
- [Jessie-LC](https://github.com/Jessie-LC) - [various utility functions](https://github.com/Jessie-LC/open-source-utility-code)
- [Tech](https://github.com/TechDevOnGitHub) - Help with subsurface scattering
- [Belmu](https://github.com/BelmuTM) - Reference code for SSR
- [Zombye](https://github.com/Zombye) - GGX VNDF Sampler
- [Moments in Graphics](http://momentsingraphics.de) - [blue noise texture](http://momentsingraphics.de/BlueNoise.html)
- [Experience.Monks](https://github.com/Experience-Monks) - [Fast Gaussian Blur Functions](https://github.com/Experience-Monks/glsl-fast-gaussian-blur)
- [Sebastian Lague](https://www.youtube.com/@SebastianLague) & [SimonDev](https://www.youtube.com/@simondev758) - YouTube videos used for reference on clouds.
- [Geurrilla Games](https://www.guerrilla-games.com/) - [Area light sources for specular highlights](https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa)
- The members of the ShaderLABS Discord server who have helped me get this far learning how to do all this
- Many other people, there are links scattered throughout the code