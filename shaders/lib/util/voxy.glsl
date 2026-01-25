#ifndef VOXY_GLSL
#define VOXY_GLSL

bool VOXY_MASK = false;

#ifdef VOXY



void voxyOverride(inout float depth, inout vec3 viewPos, vec2 texcoord, bool opaque){
  if(depth != 1.0){
    return;
  };

  if(opaque){
    depth = texture(vxDepthTexOpaque, texcoord).r;
  } else {
    depth = texture(vxDepthTexTrans, texcoord).r;
  }

  VOXY_MASK = depth != 1.0;

  viewPos = screenSpaceToViewSpace(vec3(texcoord, depth), vxProjInv);
}

#else

void voxyOverride(inout float depth, inout vec3 viewPos, vec2 texcoord, bool opaque){
  return;
}

#endif

#endif