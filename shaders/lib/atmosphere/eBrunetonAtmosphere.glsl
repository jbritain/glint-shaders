#ifndef ATMOSPHERE_INCLUDE
#define ATMOSPHERE_INCLUDE

#include "/lib/atmosphere/common.glsl"

uniform sampler3D atmospheretex;

const int TRANSMITTANCE_TEXTURE_WIDTH = 256;
const int TRANSMITTANCE_TEXTURE_HEIGHT = 64;
const int SCATTERING_TEXTURE_R_SIZE = 32;
const int SCATTERING_TEXTURE_MU_SIZE = 128;
const int SCATTERING_TEXTURE_MU_S_SIZE = 32;
const int SCATTERING_TEXTURE_NU_SIZE = 8;
const int IRRADIANCE_TEXTURE_WIDTH = 64;
const int IRRADIANCE_TEXTURE_HEIGHT = 16;
const int COMBINED_TEXTURE_WIDTH = 256;
const int COMBINED_TEXTURE_HEIGHT = 128;
const int COMBINED_TEXTURE_DEPTH = 33;

vec4 transmittanceLookup(vec2 coord) {
  coord = clamp(coord, vec2(0.5 / TRANSMITTANCE_TEXTURE_WIDTH, 0.5 / TRANSMITTANCE_TEXTURE_HEIGHT), vec2((TRANSMITTANCE_TEXTURE_WIDTH - 0.5) / TRANSMITTANCE_TEXTURE_WIDTH, (TRANSMITTANCE_TEXTURE_HEIGHT - 0.5) / TRANSMITTANCE_TEXTURE_HEIGHT));

	return texture(atmospheretex, vec3(coord, 32.5 / 33.0));
}

vec4 irradianceLookup(vec2 coord) {
  coord = clamp(coord, vec2(0.5 / IRRADIANCE_TEXTURE_WIDTH, 0.5 / IRRADIANCE_TEXTURE_HEIGHT), vec2((IRRADIANCE_TEXTURE_WIDTH - 0.5) / IRRADIANCE_TEXTURE_WIDTH, (IRRADIANCE_TEXTURE_HEIGHT - 0.5) / IRRADIANCE_TEXTURE_HEIGHT));

	return texture(atmospheretex, vec3(coord, 32.5 / 33.0));
}

vec4 scatteringLookup(vec3 coord){
  return texture(atmospheretex, coord);
}

// https://ebruneton.github.io/precomputed_atmospheric_scattering/

/*
Copyright (c) 2017 Eric Bruneton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// DEFINITIONS
// ===========================================================================================


#define TRANSMITTANCE_TEXTURE atmotransmittancetex
#define IRRADIANCE_TEXTURE atmoirradiancetex
#define SCATTERING_TEXTURE atmoscatteringtex
// #define single_mie_scattering_texture atmoscatteringtex

const float m = 1.0;
const float nm = 1.0;
const float rad = 1.0;
const float sr = 1.0;
const float watt = 1.0;
const float lm = 1.0;

const float km = 1000.0 * m;
const float m2 = m * m;
const float m3 = m * m * m;
const float pi = PI * rad;
const float deg = pi / 180.0;
const float watt_per_square_meter = watt / m2;
const float watt_per_square_meter_per_sr = watt / (m2 * sr);
const float watt_per_square_meter_per_nm = watt / (m2 * nm);
const float watt_per_square_meter_per_sr_per_nm =
    watt / (m2 * sr * nm);
const float watt_per_cubic_meter_per_sr_per_nm =
    watt / (m3 * sr * nm);
const float cd = lm / sr;
const float kcd = 1000.0 * cd;
const float cd_per_square_meter = cd / m2;
const float kcd_per_square_meter = kcd / m2;

// An ATMOSPHERE layer of width 'width', and whose density is defined as
//   'exp_term' * exp('exp_scale' * h) + 'linear_term' * h + 'constant_term',
// clamped to [0,1], and where h is the altitude.
struct DensityProfileLayer {
  float width;
  float exp_term;
  float exp_scale;
  float linear_term;
  float constant_term;
};

// An ATMOSPHERE density profile made of several layers on top of each other
// (from bottom to top). The width of the last layer is ignored, i.e. it always
// extend to the top ATMOSPHERE boundary. The profile values vary between 0
// (null density) to 1 (maximum density).
struct DensityProfile {
  DensityProfileLayer layers[2];
};

struct AtmosphereParameters {
    // The solar irradiance at the top of the atmosphere.
    vec3 solar_irradiance;
    // The sun's angular radius. Warning: the implementation uses approximations
    // that are valid only if this angle is smaller than 0.1 radians.
   float sun_angular_radius;
    // The distance between the planet center and the bottom of the atmosphere.
   float bottom_radius;
    // The distance between the planet center and the top of the atmosphere.
   float top_radius;
    // The density profile of air molecules, i.e. a function from altitude to
    // dimensionless values between 0 (null density) and 1 (maximum density).
//    DensityProfile rayleigh_density;
    // The scattering coefficient of air molecules at the altitude where their
    // density is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The scattering coefficient at altitude h is equal to
    // 'rayleigh_scattering' times 'rayleigh_density' at this altitude.
    vec3 rayleigh_scattering;
    // The density profile of aerosols, i.e. a function from altitude to
    // dimensionless values between 0 (null density) and 1 (maximum density).
//    DensityProfile mie_density;
    // The scattering coefficient of aerosols at the altitude where their density
    // is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The scattering coefficient at altitude h is equal to
    // 'mie_scattering' times 'mie_density' at this altitude.
    vec3 mie_scattering;
    // The extinction coefficient of aerosols at the altitude where their density
    // is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The extinction coefficient at altitude h is equal to
    // 'mie_extinction' times 'mie_density' at this altitude.
//    vec3 mie_extinction;
    // The asymetry parameter for the Cornette-Shanks phase function for the
    // aerosols.
   float mie_phase_function_g;
    // The density profile of air molecules that absorb light (e.g. ozone), i.e.
    // a function from altitude to dimensionless values between 0 (null density)
    // and 1 (maximum density).
//    DensityProfile absorption_density;
    // The extinction coefficient of molecules that absorb light (e.g. ozone) at
    // the altitude where their density is maximum, as a function of wavelength.
    // The extinction coefficient at altitude h is equal to
    // 'absorption_extinction' times 'absorption_density' at this altitude.
//    vec3 absorption_extinction;
    // The average albedo of the ground.
    vec3 ground_albedo;
    // The cosine of the maximum Sun zenith angle for which atmospheric scattering
    // must be precomputed (for maximum precision, use the smallest Sun zenith
    // angle yielding negligible sky light radiance values. For instance, for the
    // Earth case, 102 degrees is a good choice - yielding mu_s_min = -0.2).
   float mu_s_min;
};

const AtmosphereParameters ATMOSPHERE = AtmosphereParameters(
    // The solar irradiance at the top of the atmosphere.
    vec3(0.9420, 1.0269, 1.0242),
    // The sun's angular radius. Warning: the implementation uses approximations
    // that are valid only if this angle is smaller than 0.1 radians.
	  0.004675,
    // The distance between the planet center and the bottom of the atmosphere.
    earthRadius,
    // The distance between the planet center and the top of the atmosphere.
    6371e3 + 11e4,
    // The density profile of air molecules, i.e. a function from altitude to
    // dimensionless values between 0 (null density) and 1 (maximum density).
//    DensityProfile(DensityProfileLayer[2](DensityProfileLayer(0.000000,0.000000,0.000000,0.000000,0.000000),DensityProfileLayer(0.000000,1.000000,-0.125000,0.000000,0.000000))),
    // The scattering coefficient of air molecules at the altitude where their
    // density is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The scattering coefficient at altitude h is equal to
    // 'rayleigh_scattering' times 'rayleigh_density' at this altitude.
    vec3(0.005802, 0.013558, 0.033100),
    // The density profile of aerosols, i.e. a function from altitude to
    // dimensionless values between 0 (null density) and 1 (maximum density).
//    DensityProfile(DensityProfileLayer[2](DensityProfileLayer(0.000000,0.000000,0.000000,0.000000,0.000000),DensityProfileLayer(0.000000,1.000000,-0.833333,0.000000,0.000000))),
    // The scattering coefficient of aerosols at the altitude where their density
    // is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The scattering coefficient at altitude h is equal to
    // 'mie_scattering' times 'mie_density' at this altitude.
    vec3(0.003996, 0.003996, 0.003996),
    // The extinction coefficient of aerosols at the altitude where their density
    // is maximum (usually the bottom of the atmosphere), as a function of
    // wavelength. The extinction coefficient at altitude h is equal to
    // 'mie_extinction' times 'mie_density' at this altitude.
//    vec3(0.004440, 0.004440, 0.004440),
    // The asymetry parameter for the Cornette-Shanks phase function for the
    // aerosols.
   0.800000,
    // The density profile of air molecules that absorb light (e.g. ozone), i.e.
    // a function from altitude to dimensionless values between 0 (null density)
    // and 1 (maximum density).
//    DensityProfile(DensityProfileLayer[2](DensityProfileLayer(25.000000,0.000000,0.000000,0.066667,-0.666667),DensityProfileLayer(0.000000,0.000000,0.000000,-0.066667,2.666667))),
    // The extinction coefficient of molecules that absorb light (e.g. ozone) at
    // the altitude where their density is maximum, as a function of wavelength.
    // The extinction coefficient at altitude h is equal to
    // 'absorption_extinction' times 'absorption_density' at this altitude.
//    vec3(0.000650, 0.001881, 0.000085),
    // The average albedo of the ground.
    vec3(0.1),
    // The cosine of the maximum Sun zenith angle for which atmospheric scattering
    // must be precomputed (for maximum precision, use the smallest Sun zenith
    // angle yielding negligible sky light radiance values. For instance, for the
    // Earth case, 102 degrees is a good choice - yielding mu_s_min = -0.2).
   -0.2
);

const vec3 SKY_SPECTRAL_RADIANCE_TO_LUMINANCE = vec3(114974.916437,71305.954816,65310.548555);
const vec3 SUN_SPECTRAL_RADIANCE_TO_LUMINANCE = vec3(98242.786222,69954.398112,66475.012354);

float ClampCosine(float mu) {
  return clamp(mu, -1.0, 1.0);
}

float ClampDistance(float d) {
  return max(d, 0.0 * m);
}

float ClampRadius(in AtmosphereParameters ATMOSPHERE, float r) {
  return clamp(r, ATMOSPHERE.bottom_radius, ATMOSPHERE.top_radius);
}

float SafeSqrt(float a) {
  return sqrt(max(a, 0.0 * m2));
}

float DistanceToTopAtmosphereBoundary(float r, float mu) {
  float discriminant = r * r * (mu * mu - 1.0) +
      ATMOSPHERE.top_radius * ATMOSPHERE.top_radius;
  return ClampDistance(-r * mu + SafeSqrt(discriminant));
}

float DistanceToBottomAtmosphereBoundary(float r, float mu) {
  float discriminant = r * r * (mu * mu - 1.0) +
      ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius;
  return ClampDistance(-r * mu - SafeSqrt(discriminant));
}

float GetTextureCoordFromUnitRange(float x, int texture_size) {
  return 0.5 / float(texture_size) + x * (1.0 - 1.0 / float(texture_size));
}

float GetCombinedTextureCoordFromUnitRange(float x, float original_texture_size, float combined_texture_size) {
    return 0.5 / combined_texture_size + x * (original_texture_size / combined_texture_size - 1.0 / combined_texture_size);
}
// ===========================================================================================

// TRANSMITTANCE LOOKUP
// ===========================================================================================


vec2 GetTransmittanceTextureUvFromRMu(float r, float mu) {
	// Distance to top atmosphere boundary for a horizontal ray at ground level.
	float H = sqrt(ATMOSPHERE.top_radius * ATMOSPHERE.top_radius - ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius);

	// Distance to the horizon.
	float rho = SafeSqrt(r * r - ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius);

	// Distance to the top atmosphere boundary for the ray (r,mu), and its minimum
	// and maximum values over all mu - obtained for (r,1) and (r,mu_horizon).
	float d = DistanceToTopAtmosphereBoundary(r, mu);
	float d_min = ATMOSPHERE.top_radius - r;
	float d_max = rho + H;
	
	float x_mu = (d - d_min) / (d_max - d_min);
	float x_r = rho / H;
	return vec2(GetCombinedTextureCoordFromUnitRange(x_mu, TRANSMITTANCE_TEXTURE_WIDTH, COMBINED_TEXTURE_WIDTH),
                    GetCombinedTextureCoordFromUnitRange(x_r, TRANSMITTANCE_TEXTURE_HEIGHT, COMBINED_TEXTURE_HEIGHT));
}

vec3 GetTransmittanceToTopAtmosphereBoundary(float r, float mu) {
  vec2 uv = GetTransmittanceTextureUvFromRMu( r, mu);
  return vec3(transmittanceLookup(uv));
}

vec3 GetTransmittance(
  float r, float mu, float d, bool ray_r_mu_intersects_ground) {

  float r_d = ClampRadius(ATMOSPHERE, sqrt(d * d + 2.0 * r * mu * d + r * r));
  float mu_d = ClampCosine((r * mu + d) / r_d);

  if (ray_r_mu_intersects_ground) {
    return min(
        GetTransmittanceToTopAtmosphereBoundary(r_d, -mu_d) /
        GetTransmittanceToTopAtmosphereBoundary(r, -mu),
        vec3(1.0));
  } else {
    return min(
        GetTransmittanceToTopAtmosphereBoundary(r, mu) /
        GetTransmittanceToTopAtmosphereBoundary(r_d, mu_d),
        vec3(1.0));
  }
}

vec3 GetTransmittanceToSun(float r, float mu_s) {
	float sin_theta_h = ATMOSPHERE.bottom_radius / r;
	float cos_theta_h = -sqrt(max(1.0 - sin_theta_h * sin_theta_h, 0.0));

	return GetTransmittanceToTopAtmosphereBoundary(r, mu_s) *
		smoothstep(-sin_theta_h * ATMOSPHERE.sun_angular_radius, sin_theta_h * ATMOSPHERE.sun_angular_radius, mu_s - cos_theta_h);
}
// ===========================================================================================

// SCATTERING LOOKUP
// ===========================================================================================
float RayleighPhaseFunction(float nu) {
  float k = 3.0 / (16.0 * PI * sr);
  return k * (1.0 + nu * nu);
}

float MiePhaseFunction(float g, float nu) {
  float k = 3.0 / (8.0 * PI * sr) * (1.0 - g * g) / (2.0 + g * g);
  return k * (1.0 + nu * nu) / pow(1.0 + g * g - 2.0 * g * nu, 1.5);
}

vec4 GetScatteringTextureUvwzFromRMuMuSNu(float r, float mu, float mu_s, float nu,
    bool ray_r_mu_intersects_ground) {

  // Distance to top ATMOSPHERE boundary for a horizontal ray at ground level.
  float H = sqrt(ATMOSPHERE.top_radius * ATMOSPHERE.top_radius -
      ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius);
  // Distance to the horizon.
  float rho =
      SafeSqrt(r * r - ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius);
  float u_r = GetCombinedTextureCoordFromUnitRange(rho / H, SCATTERING_TEXTURE_R_SIZE, COMBINED_TEXTURE_DEPTH);

  // Discriminant of the quadratic equation for the intersections of the ray
  // (r,mu) with the ground (see RayIntersectsGround).
  float r_mu = r * mu;
  float discriminant =
      r_mu * r_mu - r * r + ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius;
  float u_mu;
  if (ray_r_mu_intersects_ground) {
    // Distance to the ground for the ray (r,mu), and its minimum and maximum
    // values over all mu - obtained for (r,-1) and (r,mu_horizon).
    float d = -r_mu - SafeSqrt(discriminant);
    float d_min = r - ATMOSPHERE.bottom_radius;
    float d_max = rho;
    u_mu = 0.5 - 0.5 * GetTextureCoordFromUnitRange(d_max == d_min ? 0.0 :
        (d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2);
  } else {
    // Distance to the top ATMOSPHERE boundary for the ray (r,mu), and its
    // minimum and maximum values over all mu - obtained for (r,1) and
    // (r,mu_horizon).
    float d = -r_mu + SafeSqrt(discriminant + H * H);
    float d_min = ATMOSPHERE.top_radius - r;
    float d_max = rho + H;
    u_mu = 0.5 + 0.5 * GetTextureCoordFromUnitRange(
        (d - d_min) / (d_max - d_min), SCATTERING_TEXTURE_MU_SIZE / 2);
  }

  float d = DistanceToTopAtmosphereBoundary(ATMOSPHERE.bottom_radius, mu_s);
  float d_min = ATMOSPHERE.top_radius - ATMOSPHERE.bottom_radius;
  float d_max = H;
  float a = (d - d_min) / (d_max - d_min);
  float D = DistanceToTopAtmosphereBoundary(ATMOSPHERE.bottom_radius, ATMOSPHERE.mu_s_min);
  float A = (D - d_min) / (d_max - d_min);
  // An ad-hoc function equal to 0 for mu_s = mu_s_min (because then d = D and
  // thus a = A), equal to 1 for mu_s = 1 (because then d = d_min and thus
  // a = 0), and with a large slope around mu_s = 0, to get more texture 
  // samples near the horizon.
  float u_mu_s = GetTextureCoordFromUnitRange(
      max(1.0 - a / A, 0.0) / (1.0 + a), SCATTERING_TEXTURE_MU_S_SIZE);

  float u_nu = (nu + 1.0) / 2.0;
  return vec4(u_nu, u_mu_s, u_mu, u_r);
}

	vec3 GetExtrapolatedSingleMieScattering(vec4 scattering) {
		if (scattering.r == 0.0) return vec3(0.0);
		
		return scattering.rgb * scattering.a / scattering.r
			* (ATMOSPHERE.rayleigh_scattering.r / ATMOSPHERE.mie_scattering.r)
			* (ATMOSPHERE.mie_scattering / ATMOSPHERE.rayleigh_scattering);
	}
// ===========================================================================================
// GROUND IRRADIANCE LOOKUP
// ===========================================================================================
vec2 GetIrradianceTextureUvFromRMuS(float r, float mu_s) {
	float x_r = (r - ATMOSPHERE.bottom_radius) / (ATMOSPHERE.top_radius - ATMOSPHERE.bottom_radius);
	float x_mu_s = mu_s * 0.5 + 0.5;

	return vec2(GetTextureCoordFromUnitRange(x_mu_s, IRRADIANCE_TEXTURE_WIDTH), GetTextureCoordFromUnitRange(x_r, IRRADIANCE_TEXTURE_HEIGHT));
}

vec3 GetIrradiance(
    float r, float mu_s) {
    float x_r = (r - ATMOSPHERE.bottom_radius) / (ATMOSPHERE.top_radius - ATMOSPHERE.bottom_radius);
    float x_mu_s = mu_s * 0.5 + 0.5;
    vec2 uv = vec2(GetCombinedTextureCoordFromUnitRange(x_mu_s, IRRADIANCE_TEXTURE_WIDTH, COMBINED_TEXTURE_WIDTH),
                    GetCombinedTextureCoordFromUnitRange(x_r, IRRADIANCE_TEXTURE_HEIGHT, COMBINED_TEXTURE_HEIGHT) + TRANSMITTANCE_TEXTURE_HEIGHT / COMBINED_TEXTURE_HEIGHT);
  return vec3(irradianceLookup(uv));
}
// ===========================================================================================

// RENDERING
// ===========================================================================================

vec3 GetSolarRadiance() {
  return ATMOSPHERE.solar_irradiance /
      (PI * ATMOSPHERE.sun_angular_radius * ATMOSPHERE.sun_angular_radius);
}

bool RayIntersectsGround(in AtmosphereParameters ATMOSPHERE,
    float r, float mu) {
  return mu < 0.0 && r * r * (mu * mu - 1.0) +
      ATMOSPHERE.bottom_radius * ATMOSPHERE.bottom_radius >= 0.0 * m2;
}

vec3 GetCombinedScattering(
    float r, float mu, float mu_s, float nu,
    bool ray_r_mu_intersects_ground,
    out vec3 single_mie_scattering) {
    vec4 uvwz = GetScatteringTextureUvwzFromRMuMuSNu(r, mu, mu_s, nu, ray_r_mu_intersects_ground);
    
    float tex_coord_x = uvwz.x * float(SCATTERING_TEXTURE_NU_SIZE - 1);
    float tex_x = floor(tex_coord_x);
    float lerp = tex_coord_x - tex_x;

    vec3 uvw0 = vec3((tex_x + uvwz.y) / float(SCATTERING_TEXTURE_NU_SIZE), uvwz.z, uvwz.w);
    vec3 uvw1 = vec3((tex_x + 1.0 + uvwz.y) / float(SCATTERING_TEXTURE_NU_SIZE), uvwz.z, uvwz.w);
    
    uvw0.z *= float(SCATTERING_TEXTURE_NU_SIZE) / float(SCATTERING_TEXTURE_NU_SIZE + 1.0);
    uvw1.z *= float(SCATTERING_TEXTURE_NU_SIZE) / float(SCATTERING_TEXTURE_NU_SIZE + 1.0);
  vec4 combined_scattering =
      scatteringLookup(uvw0) * (1.0 - lerp) +
      scatteringLookup(uvw1) * lerp;
  vec3 scattering = vec3(combined_scattering);
  single_mie_scattering =
      GetExtrapolatedSingleMieScattering(combined_scattering);
  return scattering;
}

vec3 GetSkyRadiance(
    vec3 camera, in vec3 view_ray, float shadow_length,
    in vec3 sun_direction, out vec3 transmittance) {
  // Compute the distance to the top atmosphere boundary along the view ray,
  // assuming the viewer is in space (or NaN if the view ray does not intersect
  // the atmosphere).
  float r = length(camera);
  float rmu = dot(camera, view_ray);
  float distance_to_top_atmosphere_boundary = -rmu -
      sqrt(rmu * rmu - r * r + ATMOSPHERE.top_radius * ATMOSPHERE.top_radius);
  // If the viewer is in space and the view ray intersects the ATMOSPHERE, move
  // the viewer to the top ATMOSPHERE boundary (along the view ray):
  if (distance_to_top_atmosphere_boundary > 0.0 * m) {
    camera = camera + view_ray * distance_to_top_atmosphere_boundary;
    r = ATMOSPHERE.top_radius;
    rmu += distance_to_top_atmosphere_boundary;
  } else if (r > ATMOSPHERE.top_radius) {
    // If the view ray does not intersect the ATMOSPHERE, simply return 0.
    transmittance = vec3(1.0);
    return vec3(0.0 * watt_per_square_meter_per_sr_per_nm);
  }
  // Compute the r, mu, mu_s and nu parameters needed for the texture lookups.
  float mu = rmu / r;
  float mu_s = dot(camera, sun_direction) / r;
  float nu = dot(view_ray, sun_direction);
  bool ray_r_mu_intersects_ground = RayIntersectsGround(ATMOSPHERE, r, mu);

  transmittance = ray_r_mu_intersects_ground ? vec3(0.0) :
      GetTransmittanceToTopAtmosphereBoundary(r, mu);
  vec3 single_mie_scattering;
  vec3 scattering;
  if (shadow_length == 0.0 * m) {
    scattering = GetCombinedScattering(r, mu, mu_s, nu, ray_r_mu_intersects_ground,
        single_mie_scattering);
  } else {
    // Case of light shafts (shadow_length is the total float noted l in our
    // paper): we omit the scattering between the camera and the point at
    // distance l, by implementing Eq. (18) of the paper (shadow_transmittance
    // is the T(x,x_s) term, scattering is the S|x_s=x+lv term).
    float d = shadow_length;
    float r_p =
        ClampRadius(ATMOSPHERE, sqrt(d * d + 2.0 * r * mu * d + r * r));
    float mu_p = (r * mu + d) / r_p;
    float mu_s_p = (r * mu_s + d * nu) / r_p;

    scattering = GetCombinedScattering(r_p, mu_p, mu_s_p, nu, ray_r_mu_intersects_ground,
        single_mie_scattering);
    vec3 shadow_transmittance =
        GetTransmittance(r, mu, shadow_length, ray_r_mu_intersects_ground);
    scattering = scattering * shadow_transmittance;
    single_mie_scattering = single_mie_scattering * shadow_transmittance;
  }
  vec3 in_scatter = scattering * RayleighPhaseFunction(nu) + single_mie_scattering *
      MiePhaseFunction(ATMOSPHERE.mie_phase_function_g, nu);

  in_scatter = setSaturationLevel(in_scatter, SKY_SATURATION);

  return in_scatter;
}

vec3 GetSkyRadianceToPoint(vec3 camera, in vec3 point, float shadow_length,
    in vec3 sun_direction, out vec3 transmittance) {
  // Compute the distance to the top ATMOSPHERE boundary along the view ray,
  // assuming the viewer is in space (or NaN if the view ray does not intersect
  // the ATMOSPHERE).
  vec3 view_ray = normalize(point - camera);
  float r = length(camera);
  float rmu = dot(camera, view_ray);
  float distance_to_top_atmosphere_boundary = -rmu -
      sqrt(rmu * rmu - r * r + ATMOSPHERE.top_radius * ATMOSPHERE.top_radius);
  // If the viewer is in space and the view ray intersects the ATMOSPHERE, move
  // the viewer to the top ATMOSPHERE boundary (along the view ray):
  if (distance_to_top_atmosphere_boundary > 0.0 * m) {
    camera = camera + view_ray * distance_to_top_atmosphere_boundary;
    r = ATMOSPHERE.top_radius;
    rmu += distance_to_top_atmosphere_boundary;
  }

  // Compute the r, mu, mu_s and nu parameters for the first texture lookup.
  float mu = rmu / r;
  float mu_s = dot(camera, sun_direction) / r;
  float nu = dot(view_ray, sun_direction);
  float d = length(point - camera);
  bool ray_r_mu_intersects_ground = RayIntersectsGround(ATMOSPHERE, r, mu);

  // Hack to avoid rendering artifacts near the horizon, due to finite
  // atmosphere texture resolution and finite floating point precision.
  if (!ray_r_mu_intersects_ground) {
    float mu_horiz = -SafeSqrt(
        1.0 - (ATMOSPHERE.bottom_radius / r) * (ATMOSPHERE.bottom_radius / r));
    mu = max(mu, mu_horiz + 0.004);
  }

  transmittance = GetTransmittance(r, mu, d, ray_r_mu_intersects_ground);

  vec3 single_mie_scattering;
  vec3 scattering = GetCombinedScattering(r, mu, mu_s, nu, ray_r_mu_intersects_ground,
      single_mie_scattering);

  // Compute the r, mu, mu_s and nu parameters for the second texture lookup.
  // If shadow_length is not 0 (case of light shafts), we want to ignore the
  // scattering along the last shadow_length meters of the view ray, which we
  // do by subtracting shadow_length from d (this way scattering_p is equal to
  // the S|x_s=x_0-lv term in Eq. (17) of our paper).
  d = max(d - shadow_length, 0.0 * m);
  float r_p = ClampRadius(ATMOSPHERE, sqrt(d * d + 2.0 * r * mu * d + r * r));
  float mu_p = (r * mu + d) / r_p;
  float mu_s_p = (r * mu_s + d * nu) / r_p;

  vec3 single_mie_scattering_p;
  vec3 scattering_p = GetCombinedScattering(r_p, mu_p, mu_s_p, nu, ray_r_mu_intersects_ground,
      single_mie_scattering_p);

  // Combine the lookup results to get the scattering between camera and point.
  vec3 shadow_transmittance = transmittance;
  if (shadow_length > 0.0 * m) {
    // This is the T(x,x_s) term in Eq. (17) of our paper, for light shafts.
    shadow_transmittance = GetTransmittance(r, mu, d, ray_r_mu_intersects_ground);
  }
  scattering = scattering - shadow_transmittance * scattering_p;
  single_mie_scattering =
      single_mie_scattering - shadow_transmittance * single_mie_scattering_p;

  single_mie_scattering = GetExtrapolatedSingleMieScattering(vec4(scattering, single_mie_scattering.r));

  // Hack to avoid rendering artifacts when the sun is below the horizon.
  single_mie_scattering = single_mie_scattering * 0.01;
      // smoothstep(0.0, 0.01, mu_s);

  vec3 in_scatter = scattering * RayleighPhaseFunction(nu) + single_mie_scattering *
      MiePhaseFunction(ATMOSPHERE.mie_phase_function_g, nu);

  in_scatter = setSaturationLevel(in_scatter, SKY_SATURATION);

  return in_scatter;
}

vec3 GetSunAndSkyIrradiance(in vec3 point, in vec3 sun_direction,
    out vec3 sky_irradiance) {
  float r = length(point);
  float mu_s = dot(point, sun_direction) / r;

  // Indirect float (approximated if the surface is not horizontal).
  sky_irradiance = GetIrradiance(r, mu_s);

  // Direct float.
  vec3 irradiance = ATMOSPHERE.solar_irradiance *
      GetTransmittanceToSun(r, mu_s);
  irradiance = setSaturationLevel(irradiance, SKY_SATURATION);

  return irradiance;
}

vec3 GetSunAndSkyIrradiance(in vec3 point, in vec3 normal, in vec3 sun_direction,
    out vec3 sky_irradiance) {
  float r = length(point);
  float mu_s = dot(point, sun_direction) / r;

  // Indirect float (approximated if the surface is not horizontal).
  sky_irradiance = GetIrradiance(r, mu_s) *
      (1.0 + dot(normal, point) / r) * 0.5;

  // Direct float.
  return ATMOSPHERE.solar_irradiance *
      GetTransmittanceToSun(r, mu_s) *
      max(dot(normal, sun_direction), 0.0);
}
// ===========================================================================================

#endif