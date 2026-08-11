#ifndef ATMOSPHERE_GLSL
#define ATMOSPHERE_GLSL

/*
    'Production Sky Rendering' by Andrew Helmer
    https://www.shadertoy.com/view/slSXRW
*/

const float sunRadius = 6.9634e8;
const float sunDistance = 1.496e11;
const float sunAngularRadius = sunRadius / sunDistance;
const float sunSolidAngle = TAU * (1.0 - cos(sunAngularRadius));
const vec3 sunLuminance = vec3(1.6e9);
const vec3 sunIlluminance = sunLuminance * sunSolidAngle;

const float moonRadius = 1737e3;
const float moonDistance = 384400e3;
const float moonAngularRadius = moonRadius / moonDistance;
const float moonSolidAngle = TAU * (1.0 - cos(moonAngularRadius));

const vec3 moonLuminance = sunIlluminance * 0.12;
const vec3 moonIlluminance = moonLuminance * moonSolidAngle;

// Units are in megametres.
const float groundRadiusMM = 6.36;
const float atmosphereRadiusMM = 6.46;

vec3 atmospherePos = vec3(
  0.0,
  groundRadiusMM + (cameraPosition.y + 5000) * 1e-6,
  0.0
);

const vec2 tLUTRes = vec2(256.0, 64.0);
const vec2 msLUTRes = vec2(32.0, 32.0);
// Doubled the vertical skyViewLUT res from the paper, looks way
// better for sunrise.
const vec2 skyViewLUTRes = vec2(200.0, 200.0);

const vec3 groundAlbedo = vec3(0.3);

// These are per megameter.
const vec3 rayleighScatteringBase = vec3(6.602, 12.39, 29.4);
const float rayleighAbsorptionBase = 0.0;

const float mieScatteringBase = 3.996;
const float mieAbsorptionBase = 4.4;

const vec3 ozoneAbsorptionBase = vec3(0.2341, 0.154, 0.0);

float getMiePhase(float cosTheta) {
  const float g = 0.8;
  const float scale = 3.0 / (8.0 * PI);

  float num = (1.0 - g * g) * (1.0 + cosTheta * cosTheta);
  float denom = (2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * cosTheta, 1.5);

  return scale * num / denom;
}

float getRayleighPhase(float cosTheta) {
  const float k = 3.0 / (16.0 * PI);
  return k * (1.0 + cosTheta * cosTheta);
}

void getScatteringValues(
  vec3 pos,
  out vec3 rayleighScattering,
  out float mieScattering,
  out vec3 extinction
) {
  float altitudeKM = (length(pos) - groundRadiusMM) * 1000.0;
  // Note: Paper gets these switched up.
  float rayleighDensity = exp(-altitudeKM / 8.0);
  float mieDensity = exp(-altitudeKM / 1.2);

  rayleighScattering = rayleighScatteringBase * rayleighDensity;
  float rayleighAbsorption = rayleighAbsorptionBase * rayleighDensity;

  mieScattering = mieScatteringBase * mieDensity;
  float mieAbsorption = mieAbsorptionBase * mieDensity;

  vec3 ozoneAbsorption =
    ozoneAbsorptionBase * max(0.0, 1.0 - abs(altitudeKM - 25.0) / 15.0);

  extinction =
    rayleighScattering +
    rayleighAbsorption +
    mieScattering +
    mieAbsorption +
    ozoneAbsorption;
}

float safeacos(const float x) {
  return acos(clamp(x, -1.0, 1.0));
}

// From
// https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
float rayIntersectSphere(vec3 ro, vec3 rd, float rad) {
  float b = dot(ro, rd);
  float c = dot(ro, ro) - rad * rad;
  if (c > 0.0f && b > 0.0) return -1.0;
  float discr = b * b - c;
  if (discr < 0.0) return -1.0;
  // Special case: inside sphere, use far discriminant
  if (discr > b * b) return -b + sqrt(discr);
  return -b - sqrt(discr);
}

/*
 * Same parameterization here.
 */
vec3 getValFromTLUT(sampler2D tex, vec2 bufferRes, vec3 pos, vec3 sunDir) {
  float height = length(pos);
  vec3 up = pos / height;
  float sunCosZenithAngle = dot(sunDir, up);
  vec2 uv = vec2(
    tLUTRes.x * clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
    tLUTRes.y *
      max(
        0.0,
        min(
          1.0,
          (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM)
        )
      )
  );
  uv /= bufferRes;
  return textureLod(tex, uv, 0).rgb;
}
vec3 getValFromMultiScattLUT(
  sampler2D tex,
  vec2 bufferRes,
  vec3 pos,
  vec3 sunDir
) {
  float height = length(pos);
  vec3 up = pos / height;
  float sunCosZenithAngle = dot(sunDir, up);
  vec2 uv = vec2(
    msLUTRes.x * clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
    msLUTRes.y *
      max(
        0.0,
        min(
          1.0,
          (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM)
        )
      )
  );
  uv /= bufferRes;
  return textureLod(tex, uv, 0).rgb;
}

vec3 getValFromSkyLUT(vec3 rayDir) {
  float height = atmospherePos.y;
  vec3 up = vec3(0.0, 1.0, 0.0);

  float horizonAngle = safeacos(
    sqrt(height * height - groundRadiusMM * groundRadiusMM) / height
  );
  float altitudeAngle = horizonAngle - acos(dot(rayDir, up)); // Between -PI/2 and PI/2
  float azimuthAngle; // Between 0 and 2*PI
  if (abs(altitudeAngle) > 0.5 * PI - 0.0001) {
    // Looking nearly straight up or down.
    azimuthAngle = 0.0;
  } else {
    vec3 right = vec3(1.0, 0.0, 0.0);
    vec3 forward = vec3(0.0, 0.0, -1.0);

    vec3 projectedDir = normalize(rayDir - up * dot(rayDir, up));
    float sinTheta = dot(projectedDir, right);
    float cosTheta = dot(projectedDir, forward);
    azimuthAngle = atan(sinTheta, cosTheta) + PI;
  }

  // Non-linear mapping of altitude angle. See Section 5.3 of the paper.
  float v =
    0.5 + 0.5 * sign(altitudeAngle) * sqrt(abs(altitudeAngle) * 2.0 / PI);
  vec2 uv = vec2(azimuthAngle / (2.0 * PI), v);

  return textureLod(skyViewLUTTex, uv, 0).rgb;
}

vec3 mapAerialPerspectivePos(vec3 viewPos) {
  vec3 pos;
  pos.xy = viewSpaceToScreenSpace(viewPos).xy;
  pos.z = clamp01(abs(viewPos.z) / 32000);
  return pos;
}

vec3 unmapAerialPerspectivePos(vec3 pos) {
  vec3 viewPos;
  viewPos.xy = screenSpaceToViewSpace(pos).xy;
  viewPos.z = -abs(pos.z) * 32000;
  return viewPos;
}

#endif // ATMOSPHERE_GLSL
