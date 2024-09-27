/*
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

    /program/discard.glsl
    - For gbuffer passes which should be disabled
*/

#include "/lib/settings.glsl"

#ifdef vsh
void main(){
  gl_Position = vec3(1e10);
}
#endif
#ifdef fsh
void main(){
  discard;
}
#endif