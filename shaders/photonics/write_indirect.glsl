writeonly uniform image2D indirectRadiosity;

void write_indirect(vec3 color) {
    imageStore(indirectRadiosity, ivec2(gl_FragCoord.xy), vec4(color, 1.0));
}