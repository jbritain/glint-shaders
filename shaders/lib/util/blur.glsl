#ifndef BLUR_GLSL
#define BLUR_GLSL

// https://github.com/Experience-Monks/glsl-fast-gaussian-blur

vec4 blur13(sampler2D image, vec2 uv, float lod, vec2 direction) {
  vec2 resolution = textureSize(image, int(lod)).xy;
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(1.411764705882353) * direction;
  vec2 off2 = vec2(3.2941176470588234) * direction;
  vec2 off3 = vec2(5.176470588235294) * direction;
  color += textureLod(image, uv, lod) * 0.1964825501511404;
  color += textureLod(image, uv + off1 / resolution, lod) * 0.2969069646728344;
  color += textureLod(image, uv - off1 / resolution, lod) * 0.2969069646728344;
  color += textureLod(image, uv + off2 / resolution, lod) * 0.09447039785044732;
  color += textureLod(image, uv - off2 / resolution, lod) * 0.09447039785044732;
  color +=
    textureLod(image, uv + off3 / resolution, lod) * 0.010381362401148057;
  color +=
    textureLod(image, uv - off3 / resolution, lod) * 0.010381362401148057;
  return color;
}

#endif // BLUR_GLSL
