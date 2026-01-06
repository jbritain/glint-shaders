/*
    Copyright (c) 2025 Josh Britain (jbritain)
    Licensed under the MIT license

    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗

    By jbritain
    https://jbritain.net

*/

#include "/lib/util/dither.glsl"
#include "/lib/atmosphere/atmosphere.glsl"

uniform sampler3D cloudshapetex;
uniform sampler3D clouddetailtex;
uniform sampler2D cloudcoveragetex;
uniform sampler2D vanillacloudtex;


#define CLOUDS_BASE_ALTITUDE 200
#define CLOUDS_TOP_ALTITUDE 350
#define CLOUD_PRIMARY_SAMPLES 16
#define CLOUD_SECONDARY_SAMPLES 4
#define CLOUDS_DENSITY 0.085
#define CLOUDS_MULTIPLE_SCATTERING 500.0

const float cloudScattering = 2.0;
const float cloudAbsorption = 0.44;
const float cloudExtinction = cloudScattering + cloudAbsorption;

float remap(float val, float oMin, float oMax, float nMin, float nMax) {
    return mix(nMin, nMax, linearstep(oMin, oMax, val));
}

const float isotropicPhase = 1.0 / (4.0 * PI);

float henyeyGreensteinPhase(float cos_theta, float g) {
    return (1.0 - g * g) /
    (4.0 * PI * pow(1.0 + g * g - 2.0 * g * cos_theta, 3.0 / 2.0));
}

float drainePhase(float cos_theta, float g, float a) {
    return (1 - g * g) *
    (1 + a * cos_theta * cos_theta) /
    (4.0 *
      (1 + a * (1 + 2 * g * g) / 3.0) *
      PI *
      pow(1 + g * g - 2 * g * cos_theta, 1.5));
}

float hgDrainePhase(float cos_theta, const float d) {
    const float g_hg = exp(-0.0990567 / (d - 1.67154));
    const float g_d = exp(-2.20679 / (d + 3.91029) - 0.428934);
    const float a = exp(3.62489 - 8.29288 / (d + 5.52825));
    const float w = exp(-0.599085 / (d - 0.641583) - 0.665888);

    return mix(
        henyeyGreensteinPhase(cos_theta, g_hg),
        drainePhase(cos_theta, g_d, a),
        w
    );
}

bool rayPlaneIntersection(
    vec3 cameraPosition,
    vec3 direction,
    float height,
    inout vec3 point
) {
    vec3 normal = vec3(0.0, sign(cameraPosition.y - height), 0.0); // plane normal vector
    vec3 planePoint = vec3(0.0, height, 0.0); // point on the plane

    float NdotD = dot(normal, direction);
    if (NdotD == 0.0) {
        return false;
    }

    float t = dot(normal, planePoint - cameraPosition) / NdotD;

    point = cameraPosition + t * direction;

    return t >= 0;
}

float getCloudDensity(vec3 rayPos, bool highQuality){
    #ifdef VANILLA_CLOUDS
        vec2 samplePos = (rayPos.xz + vec2(frameTimeCounter, 0.0)) * 2.0;
        ivec2 p = ivec2(floor(mod((samplePos) / 24, 256)));

        return texelFetch(vanillacloudtex, p, 0).r * CLOUDS_DENSITY;
    #else
        vec2 windDir = vec2(0.0, 1.0);
        vec2 wind = windDir * frameTimeCounter;

        rayPos.xz += wind;

        // rayPos = floor(rayPos / 4) * 4;

        float heightInPlane = linearstep(CLOUDS_BASE_ALTITUDE, CLOUDS_TOP_ALTITUDE, rayPos.y);
        rayPos.xz += windDir * heightInPlane * 20.0;

        // Based loosely upon "Real Time Volumetric Cloudscapes" by Andrew Schneider in GPU Pro 7
        // Coverage texture generated with 'Strepitus' by luna5ama (https://github.com/luna5ama/strepitus)
        // Shape and detail textures generated with jaekmichie97's noise generator (https://github.com/jcm2606/volume-noise-generator)
        float coverage = smoothstep(0.7, 1.0, texture(cloudcoveragetex, fract(rayPos.xz / 10000.0)).r);
        coverage *= heightInPlane * 0.3 + 0.7;

        // coverage = sqrt(coverage);

        vec4 lowFrequencyNoise = texture(cloudshapetex, fract(rayPos.xyz / 300.0));
        float lowFrequencyFBM = lowFrequencyNoise.g * 0.625 + lowFrequencyNoise.b * 0.25 + lowFrequencyNoise.a * 0.125;
        float density = remap(lowFrequencyNoise.r, lowFrequencyFBM * 0.7, 1.0, 0.0, 1.0);
        density = sqrt(density);
        
        float heightFactor = min(smoothstep(0.0, 0.2, heightInPlane / 2), 1.0 - linearstep(0.2, 1.0, heightInPlane / 2));
        density *= heightFactor;

        density = remap(density, 1.0 - coverage, 1.0, 0.0, 1.0);
        // density *= coverage;

        density = pow(density, 1.5);

        if(highQuality){
            vec3 highFrequencyNoise = texture(clouddetailtex, fract(rayPos.xyz / 50.0 + vec3(wind.x * 0.01, 0.0, wind.y * 0.01))).rgb;
            float highFrequencyFBM = highFrequencyNoise.r * 0.625 + highFrequencyNoise.g * 0.25 + highFrequencyNoise.b * 0.125;
            highFrequencyFBM = mix(highFrequencyFBM, 1.0 - highFrequencyFBM, saturate(heightInPlane * 10.0));

            density = remap(density, highFrequencyFBM * 0.7, 1.0, 0.0, 1.0);
        } else {
            density = remap(density, 0.25, 1.0, 0.0, 1.0); // the remap operation from the high quality noise affects the overall density - this emulates that
        }

        density *= smoothstep(0.0, 0.5, density);



        return density * CLOUDS_DENSITY * (1.0 + wetness);
    #endif
}

// TODO: move this somewhere more sensible
vec3 unmapSphere(vec2 uv) {
    float phi = (uv.x - 0.5) * 2.0 * 3.14;
    float theta = (uv.y - 0.5) * 3.14;
    
    float y = sin(theta);
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    float cosTheta = cos(theta);
    
    return vec3(
        cosTheta * cosPhi,
        y,
        cosTheta * sinPhi
    );
}

float getTransmittanceToSun(vec3 start, vec3 dir, vec2 jitter){

    vec3 jitterDir = unmapSphere(jitter);
    dir = normalize(dir + jitterDir * 0.1);

    vec3 a = start;
    vec3 b;
    if (!rayPlaneIntersection(a, dir, CLOUDS_TOP_ALTITUDE, b)) {
        if (!rayPlaneIntersection(a, dir, CLOUDS_BASE_ALTITUDE, b)) {
        return 1.0;
        }
    }

    float density = 0.0;

    vec3 previousSamplePos = a;
    for (int i = 0; i < CLOUD_SECONDARY_SAMPLES; i++) {
        float progress = (float(i) + jitter.x) / float(CLOUD_SECONDARY_SAMPLES);
        vec3 samplePos = mix(a, b, exp(5.0 * (progress - 1.0)));

        density +=
        getCloudDensity(samplePos, false) *
        distance(previousSamplePos, samplePos);

        previousSamplePos = samplePos;
    }

    return exp(-density * cloudExtinction);
}

vec4 getClouds(inout vec3 position, bool sky){
    vec3 dir = normalize(position);

    vec3 start;
    vec3 end;

    if (!rayPlaneIntersection(cameraPosition, dir, CLOUDS_BASE_ALTITUDE, start)) {
        start = cameraPosition;
    }

    if (!rayPlaneIntersection(cameraPosition, dir, CLOUDS_TOP_ALTITUDE, end)) {
        end = cameraPosition;
    }

    if(start == end){
      return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // ensure we are always marching away from the camera
    if (distance(cameraPosition, start) > distance(cameraPosition, end)) {
        vec3 swap = start;
        start = end;
        end = swap;
    }

    // limit ray length if inside cloud plane
    if(start == cameraPosition && distance(cameraPosition, end) > 1000){
        end = start + dir * 1000;
    }

    if(!sky){
        // if terrain is closer than entry point, don't both
        if(distance(cameraPosition, start) > length(position)){
            return vec4(0.0, 0.0, 0.0, 1.0);
        }

        // if terrain is closer than exit point, march to terrain instead
        if(distance(cameraPosition, end) > length(position)){
            end = position + cameraPosition;
        }
    }


    vec3 rayStep = (end - start) / CLOUD_PRIMARY_SAMPLES;
    float stepLength = length(rayStep);

    vec3 rayPos = start;

    vec3 jitter = blueNoise(gl_FragCoord.xy, frameCounter);
    rayPos += rayStep * jitter.x;

    float transmittance = 1.0;
    vec3 scattering = vec3(0.0);

    float phase = hgDrainePhase(dot(dir, worldLightDir), 11);

    bool hasHitStart = false;
    position = mix(start, end, 0.5) - cameraPosition;

    for(int i = 0; i < CLOUD_PRIMARY_SAMPLES; i++, rayPos += rayStep){
        float density = getCloudDensity(rayPos, true);
        if(density < 0.01){
            continue;
        }

        float sampleTransmittance = exp(-density * stepLength * cloudExtinction);

        if(!hasHitStart){
            hasHitStart = true;
            position = rayPos - cameraPosition;
        }

        // single scattering
        float transmittanceToSun = getTransmittanceToSun(rayPos, worldLightDir, jitter.yz);
        vec3 radiance = sunlightColor * transmittanceToSun * phase;

        // multiple scattering approximation by ohmygggod (窝的舔)
        // https://zhuanlan.zhihu.com/p/457997155
        // "discovered" by Luna5ama
        float fMS = (1.0 - exp(-CLOUDS_MULTIPLE_SCATTERING * density * cloudExtinction * stepLength)) * cloudScattering / cloudExtinction;
        fMS = mix(fMS, fMS * 0.99, smoothstep(0.99, 1.0, fMS)); // this part by luna
        radiance += sunlightColor * transmittanceToSun * isotropicPhase * fMS / (1.0 - fMS);
       
        // ambient scattering
        radiance += skylightColor;
       
        scattering +=
            transmittance *
            (radiance * (1.0 - saturate(sampleTransmittance)) * cloudScattering / cloudExtinction);
        transmittance *= sampleTransmittance;
    }

    // apply aerial perspective to clouds
    if(hasHitStart){
        // fuck it - random density value
        // the assumption here is that any clouds far enough away to have aerial perspective
        // applied to them are unlikely to have any terrain behind them
        // so we can just fade them out into the sky
        float atmoTransmittance = exp(-length(position) * 1e-4);
        scattering *= atmoTransmittance;
        transmittance = mix(1.0, transmittance, atmoTransmittance);
    }

    return vec4(scattering, transmittance);
}