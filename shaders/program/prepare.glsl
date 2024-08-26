#include "/lib/settings.glsl"

#ifdef vsh
  out vec2 texcoord;

  void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  }
#endif

#ifdef fsh
  uniform sampler2D colortex4;
  uniform sampler2D depthtex0;

  uniform vec3 cameraPosition;
  uniform vec3 previousCameraPosition;

  uniform mat4 gbufferPreviousProjection;
  uniform mat4 gbufferPreviousModelView;

  uniform mat4 gbufferProjection;
  uniform mat4 gbufferModelView;
  uniform mat4 gbufferProjectionInverse;
  uniform mat4 gbufferModelViewInverse;

  in vec2 texcoord;

  #include "/lib/util/spaceConversions.glsl"
  #include "/lib/util.glsl"

  vec3 viewSpaceToPreviousScreenSpace(vec3 viewPosition) {
	  vec3 screenPosition  = vec3(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y, gbufferPreviousProjection[2].z) * viewPosition + gbufferPreviousProjection[3].xyz;
	     screenPosition /= -viewPosition.z;

	return screenPosition * 0.5 + 0.5;
}

  /* DRAWBUFFERS:4 */
  layout(location = 0) out vec4 previousFrameData;

  void main() {
    mat4 gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView); // TODO: not this

    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenSpaceToViewSpace(vec3(texcoord, depth));
    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    eyePlayerPos += gbufferModelViewInverse[3].xyz + cameraPosition;
    eyePlayerPos -= gbufferPreviousModelViewInverse[3].xyz + previousCameraPosition;
    vec3 previousViewPos = mat3(gbufferPreviousModelView) * eyePlayerPos;
    vec3 previousScreenPos = viewSpaceToPreviousScreenSpace(previousViewPos);

    // if(clamp01(previousScreenPos.xy) == previousScreenPos.xy){ // check if within screen bounds
      previousFrameData = texture(colortex4, previousScreenPos.xy);
    // } else {
    //   previousFrameData = vec4(vec3(0.0), 1.0);
    // }

    

  }
#endif