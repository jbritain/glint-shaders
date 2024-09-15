// implemented following https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
// which is in turn an implementation of Sledgehammer Games' bloom used for COD Advanced Warfare

struct BloomTile {
  vec2 origin;
  int mipLevel;
  float scale;
};

const BloomTile tileA = BloomTile(vec2(0.0), 1, 0.5); // 1/2 scale
const BloomTile tileB = BloomTile(vec2(0.5 + 2/viewWidth, 0.0), 2, 0.25); // 1/4 scale
const BloomTile tileC = BloomTile(vec2(0.75 + 4/viewWidth, 0.0), 3, 0.125); // 1/8 scale
const BloomTile tileD = BloomTile(vec2(0.875 + 6/viewWidth, 0.0), 4, 0.0625); // 1/16 scale
const BloomTile tileE = BloomTile(vec2(0.9375 + 8/viewWidth, 0.0), 5, 0.03125); // 1/32 scale

BloomTile tiles[5] = BloomTile[5](tileA, tileB, tileC, tileD, tileE);

vec3 downSample(sampler2D sourceTexture, vec2 coord){
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i

  float x = 1.0 / float(viewWidth);
  float y = 1.0 / float(viewHeight);

  vec3 a = texture(sourceTexture, vec2(coord.x - 2*x, coord.y + 2*y)).rgb;
  vec3 b = texture(sourceTexture, vec2(coord.x,       coord.y + 2*y)).rgb;
  vec3 c = texture(sourceTexture, vec2(coord.x + 2*x, coord.y + 2*y)).rgb;
  vec3 d = texture(sourceTexture, vec2(coord.x - 2*x, coord.y)).rgb;
  vec3 e = texture(sourceTexture, vec2(coord.x,       coord.y)).rgb;
  vec3 f = texture(sourceTexture, vec2(coord.x + 2*x, coord.y)).rgb;
  vec3 g = texture(sourceTexture, vec2(coord.x - 2*x, coord.y - 2*y)).rgb;
  vec3 h = texture(sourceTexture, vec2(coord.x,       coord.y - 2*y)).rgb;
  vec3 i = texture(sourceTexture, vec2(coord.x + 2*x, coord.y - 2*y)).rgb;
  vec3 j = texture(sourceTexture, vec2(coord.x - x, coord.y + y)).rgb;
  vec3 k = texture(sourceTexture, vec2(coord.x + x, coord.y + y)).rgb;
  vec3 l = texture(sourceTexture, vec2(coord.x - x, coord.y - y)).rgb;
  vec3 m = texture(sourceTexture, vec2(coord.x + x, coord.y - y)).rgb;

  vec3 dsample = e * 0.125;
  dsample += (a+c+g+i) * 0.03125;
  dsample += (b+d+f+h) * 0.0625;
  dsample += (j+k+l+m) * 0.125;

  return dsample;
}

vec3 upSample(sampler2D sourceTexture, vec2 coord){
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |

  float x = BLOOM_RADIUS / viewWidth;
  float y = BLOOM_RADIUS / viewHeight;

  vec3 a = texture(sourceTexture, vec2(coord.x - x, coord.y + y)).rgb;
  vec3 b = texture(sourceTexture, vec2(coord.x,     coord.y + y)).rgb;
  vec3 c = texture(sourceTexture, vec2(coord.x + x, coord.y + y)).rgb;

  vec3 d = texture(sourceTexture, vec2(coord.x - x, coord.y)).rgb;
  vec3 e = texture(sourceTexture, vec2(coord.x,     coord.y)).rgb;
  vec3 f = texture(sourceTexture, vec2(coord.x + x, coord.y)).rgb;

  vec3 g = texture(sourceTexture, vec2(coord.x - x, coord.y - y)).rgb;
  vec3 h = texture(sourceTexture, vec2(coord.x,     coord.y - y)).rgb;
  vec3 i = texture(sourceTexture, vec2(coord.x + x, coord.y - y)).rgb;

  vec3 usample = e*4.0;
  usample += (b + d + f + h) * 2.0;
  usample += (a + c + g + i);
  usample /= 16.0;

  return usample;
}

// takes a texcoord within a bloom tile and scales it up to spread across the whole screen
vec2 scaleToBloomTile(vec2 coord, BloomTile tile){
  return (coord - tile.origin) / tile.scale;
}

// takes a full screen texcoord and scales it down to map to a bloom tile
vec2 scaleFromBloomTile(vec2 coord, BloomTile tile){
  return coord * tile.scale + tile.origin;
}

// // when downsampling, which bloom tile are we reading?
// bool getCurrentTile(vec2 coord, out BloomTile tile){
//   for(int i = 0; i < tiles.length(); i++){
//     tile = tiles[i];
//     if(coord.x < tile.origin.x + tile.scale && coord.x > tile.origin.x && coord.y < tile.scale){
//       return true;
//     }
//   }
//   return false;
// }