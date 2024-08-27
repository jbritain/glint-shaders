#ifndef SKY_INCLUDE
#define SKY_INCLUDE

// FROM https://www.shadertoy.com/view/wsfGWH
// TODO: NOT USE THIS BECAUSE THERE IS NO LICENSE ATTACHED

// Planet Constants
const float EARTHRADIUS = 6360e3; // 6360e3
const float ATMOSPHERERADIUS = 6420e3; //6420e3
const float SUNINTENSITY = 20.0; //20.0

// Rayleigh Scattering
const float RAYLEIGHSCALEHEIGHT = 7994.0; // 7994.0
const vec3 BETAR = vec3(3.8e-6, 13.5e-6, 33.1e-6);

// Mie Scattering
const float MIESCALEHEIGHT = 1200.0; // 1200.0
const vec3 BETAM = vec3(210e-5, 210e-5, 210e-5);
const float G = 0.76;

// --------------------------------------
// ---------- Helper Functions-----------
// --------------------------------------

// Returns the matrix that rotates a given point by 'a' radians

mat2 mm2(in float a) {
    
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
    
}


// Returns the first intersection of the ray with the sphere (or -1.0 if no intersection)
// From https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d

float raySphereIntersect(vec3 rayOrigin, vec3 rayDirection, vec3 sphereCenter, float sphereRadius) {
    
    float a = dot(rayDirection, rayDirection);
    vec3 d = rayOrigin - sphereCenter;
    float b = 2.0 * dot(rayDirection, d);
    float c = dot(d, d) - (sphereRadius * sphereRadius);
    if (b*b - 4.0*a*c < 0.0) {
        return -1.0;
    }
    return (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);
    
}

// -------------------------------
// ------- Main Functions --------
// -------------------------------

// The rayleigh phase function
float rayleighPhase(float mu) {
    float phase = (3.0 / (16.0 * PI)) * (1.0 + mu * mu);
    return phase;
}

// The mie phase function
float miePhase(float mu) {
    float numerator = (1.0 - G * G) * (1.0 + mu * mu);
    float denominator = (2.0 + G * G) * pow(1.0 + G * G - 2.0 * G * mu, 3.0/2.0);
    return (3.0 / (8.0 * PI)) * numerator / denominator;
}

// Returns the expected amount of atmospheric scattering at a given height above sea level
// Different parameters are passed in for rayleigh and mie scattering
vec3 scatteringAtHeight(vec3 scatteringAtSea, float height, float heightScale) {
	return scatteringAtSea * exp(-height/heightScale);
}

// Returns the height of a vector above the 'earth'
float height(vec3 p) {
    return (length(p) - EARTHRADIUS);
}

// Calculates the transmittance from pb to pa, given the scale height and the scattering
// coefficients. The samples parameter controls how accurate the result is.
// See the scratchapixel link for details on what is happening
vec3 transmittance(vec3 pa, vec3 pb, int samples, float scaleHeight, vec3 scatCoeffs) {
    float opticalDepth = 0.0;
    float segmentLength = length(pb - pa)/float(samples);
    for (int i = 0; i < samples; i++) {
        vec3 samplePoint = mix(pa, pb, (float(i)+0.5)/float(samples));
        float sampleHeight = height(samplePoint);
        opticalDepth += exp(-sampleHeight / scaleHeight) * segmentLength;
    }
    vec3 transmittance = exp(-1.0 * scatCoeffs * opticalDepth);
    return transmittance;
}

// This is the main function that uses the ideas of rayleigh and mie scattering
// This function is written with understandability in mind rather than performance, and
// redundant calls to transmittance can be removed as per the code in the scratchapixel link

vec3 getSkyColor(vec3 pa, vec3 pb, vec3 sunDir) {
	
    // Get the angle between the ray direction and the sun
    float mu = dot(normalize(pb - pa), sunDir);
    
    // Calculate the result from the phase functions
    float phaseR = rayleighPhase(mu);
    float phaseM = miePhase(mu);
    
    // Will be used to store the cumulative colors for rayleigh and mie
    vec3 rayleighColor = vec3(0.0, 0.0, 0.0);
    vec3 mieColor = vec3(0.0, 0.0, 0.0);

    // Performs an integral approximation by checking a number of sample points and:
    //		- Calculating the incident light on that point from the sun
    //		- Calculating the amount of that light that gets reflected towards the origin
    
    int samples = 10;
    float segmentLength = length(pb - pa) / float(samples);
    
    for (int i = 0; i < samples; i++) {
        
    	vec3 samplePoint = mix(pa, pb, (float(i)+0.5)/float(samples));
        float sampleHeight = height(samplePoint);
        float distanceToAtmosphere = raySphereIntersect(samplePoint, sunDir, vec3(0.0, 0.0, 0.0), ATMOSPHERERADIUS);
    	vec3 atmosphereIntersect = samplePoint + sunDir * distanceToAtmosphere;
        
        // Rayleigh Calculations
        vec3 trans1R = transmittance(pa, samplePoint, 10, RAYLEIGHSCALEHEIGHT, BETAR);
        vec3 trans2R = transmittance(samplePoint, atmosphereIntersect, 10, RAYLEIGHSCALEHEIGHT, BETAR);
        rayleighColor += trans1R * trans2R * scatteringAtHeight(BETAR, sampleHeight, RAYLEIGHSCALEHEIGHT) * segmentLength;
        
        // Mie Calculations
        vec3 trans1M = transmittance(pa, samplePoint, 10, MIESCALEHEIGHT, BETAM);
        vec3 trans2M = transmittance(samplePoint, atmosphereIntersect, 10, MIESCALEHEIGHT, BETAM);
        mieColor += trans1M * trans2M * scatteringAtHeight(BETAM, sampleHeight, MIESCALEHEIGHT) * segmentLength;
        
    }
    
    rayleighColor = SUNINTENSITY * phaseR * rayleighColor;
    mieColor = SUNINTENSITY * phaseM * mieColor;
    
    return rayleighColor + mieColor;
    
}

// Get the sky color for the ray in direction 'p'
vec3 skyColor(vec3 p, vec3 sunDir, bool includeSun) {
    
    // Get the origin and direction of the ray
	vec3 origin = vec3(0.0, EARTHRADIUS + 1.0, 0.0);
	vec3 dir = p * vec3(1.0, sign(p.y), 1.0);

	// Get the position where the ray 'leaves' the atmopshere (see the scratchapixel link for details)
    // Note that this implementation only works when the origin is inside the atmosphere to begin with
    float distanceToAtmosphere = raySphereIntersect(origin, dir, vec3(0.0, 0.0, 0.0), ATMOSPHERERADIUS);
    vec3 atmosphereIntersect = origin + dir * distanceToAtmosphere;
    
    // Get the color of the light from the origin to the atmosphere intersect
    vec3 col = getSkyColor(origin, atmosphereIntersect, sunDir) * 2;

    vec3 sun = vec3(step(cos(radians(1.0)), dot(p, sunDir)) * float(includeSun)) * step(0.0, p.y);
    return col + sun;

}

#define SUN_VECTOR normalize(mat3(gbufferModelViewInverse) * sunPosition)

vec3 getSky(vec3 dir, bool includeSun){
    return skyColor(dir, SUN_VECTOR, includeSun);
}
#endif