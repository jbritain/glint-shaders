// https://www.shadertoy.com/view/lcXSR2
// thanks quadro!!! (and by extension Jessie, the goat of minecraft applied physics)

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float normdist (float x, float mean, float dev) {
    float nd = (1.0 / (dev * sqrt(2.0 * PI))) * exp(-0.5 * pow((x - mean) / dev, 2.0));
    if(isnan(nd)) nd = 0.0;
    return nd;
}

//From Jessie
float PreethamBetaO_Fit(float wavelength) {
    wavelength -= 390.0;
    float p1 = normdist(wavelength, 202.0, 15.0) * 14.4;
    float p2 = normdist(wavelength, 170.0, 10.0) * 6.5;
    float p3 = normdist(wavelength, 50.0, 20.0) * 3.0;
    float p4 = normdist(wavelength, 100.0, 25.0) * 7.0;
    float p5 = normdist(wavelength, 140.0, 30.0) * 20.0;
    float p6 = normdist(wavelength, 150.0, 10.0) * 3.0;
    float p7 = normdist(wavelength, 290.0, 30.0) * 12.0;
    float p8 = normdist(wavelength, 330.0, 80.0) * 10.0;
    float p9 = normdist(wavelength, 240.0, 20.0) * 13.0;
    float p10 = normdist(wavelength, 220.0, 10.0) * 2.0;
    float p11 = normdist(wavelength, 186.0, 8.0) * 1.3;
    return 0.0001 * ((p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9 + p10 + p11) / 1e20);
}

float Air(in float wavelength) {
    return 1.0+8.06051E-5+2.480990E-2/(132.274-pow(wavelength,-2.0))+1.74557E-4/(39.32957-pow(wavelength,-2.0));
}

float BetaR(in float wavelength) {
    float nanometers = wavelength * 1e-9;

    float F_N2 = 1.034 + 3.17e-4 * (1.0 / pow(wavelength, 2.0));
    float F_O2 = 1.096 + 1.385e-3 * (1.0 / pow(wavelength, 2.0)) + 1.448e-4 * (1.0 / pow(wavelength, 4.0));
    float CCO2 = 0.045;
    float kingFactor = (78.084 * F_N2 + 20.946 * F_O2 + 0.934 + CCO2 * 1.15) / (78.084 + 20.946 + 0.934 + CCO2);
    float n = pow(Air(wavelength * 1e-3), 2.0) - 1.0;

    return ((8.0 * pow(PI, 3.0) * pow(n, 2.0)) / (3.0 * 2.5035422e25 * pow(nanometers, 4.0))) * kingFactor;
}

vec2 RSI (vec3 ro, vec3 rd, vec4 sph) {
    ro = ro - sph.xyz;
    float a = sph.a * sph.a;
    float b = dot(ro, rd);
    float c = b * b + a - dot(ro, ro);

    if (c < 0.0) return vec2(-1.0);

    c = sqrt(c);
    return -b + vec2(-c, c);
}

#define CUSTOMRAYLEIGH

const float sundeg = 1.0;
const float sunintens = 100.0;

const int points = 8;
const int odpoints = 4;

const vec3 scatterm = vec3(2e-6);
const vec3 scatterr = vec3(1.8e-6, 14.5e-6, 44.1e-6);

const float ozone = 1.0;

const float planetrad = 6371e3;
const float atmoheight = 100e3;

const vec2 scaleheights = vec2(8.0, 1.4) * 1000.0;

const vec2 inversescaleheights = 1.0 / scaleheights;
const vec2 scaledplanetrads = planetrad * inversescaleheights;
const float atmorad = planetrad + atmoheight;
const float atmolowerlim = planetrad - 1000;

float rphase(float c) {
    return  3.0 * (1.0 + c * c) / 16.0 / PI;
}

float mphase2 (float c) {
    float g = 0.76;

    float e = 1.0;
    for (int i = 0; i < 8; i++) {
        float gFromE = 1.0 / e - 2.0 / log(2.0 * e + 1.0) + 1.0;
        float deriv = 4.0 / ((2.0 * e + 1.0) * log(2.0 * e + 1.0) * log(2.0 * e + 1.0)) - 1.0 / (e * e);
        if (abs(deriv) < 0.00000001) break;
        e = e - (gFromE - g) / deriv;
    }

    return e / (2.0 * PI * (e * (1.0 - c) + 1.0) * log(2.0 * e + 1.0));
}

float raydens (in float h) {
    return exp(-h * inversescaleheights.x + scaledplanetrads.x);
}

float miedens (in float h) {
    return exp(-h * inversescaleheights.y + scaledplanetrads.y);
}

//From Jessie
float ozonedens (in float h) {
    float o1 = 25.0 *     exp(( 0.0 - h) /   8.0) * 0.5;
    float o2 = 30.0 * pow(exp((18.0 - h) /  80.0), h - 18.0);
    float o3 = 75.0 * pow(exp((25.3 - h) /  35.0), h - 25.3);
    float o4 = 50.0 * pow(exp((30.0 - h) / 150.0), h - 30.0);
    return (o1 + o2 + o3 + o4) / 134.628;
}

vec3 dens2 (float height) {
    height = max(height, planetrad);
    float ray = raydens(height);
    float mie = miedens(height);
    float ozone = ozonedens((height - planetrad) / 1000.0);

    return vec3(ray, mie, ozone);
}

vec3 lighttrans (vec3 ro, vec3 rd) {
    float dist = dot(ro, rd);
    dist = sqrt(dist * dist + atmorad * atmorad - dot(ro, ro)) - dist;
    float t = dist / float(odpoints);
    vec3 step = rd * t;
    ro += step * 0.5;

    vec3 sum = vec3(0.0);
    for (int i = 0; i < odpoints; i++, ro += step) {
        float height = length(ro);
        sum += dens2(height);
    }
    
    vec3 scattero = vec3(PreethamBetaO_Fit(680.0), PreethamBetaO_Fit(550.0), PreethamBetaO_Fit(440.0)) * 2.5035422e25 * exp(-25e3 / 8e3) * 134.628 / 48.0 * 3e-6 * ozone;
    #ifndef CUSTOMRAYLEIGH
    vec3 scatterr = vec3(BetaR(680.0), BetaR(550.0), BetaR(440.0));
    #endif

    vec3 od = (scatterr * t * sum.x) + (scatterm * t * sum.y) + (scattero * t * sum.z);
    vec3 trans = exp(-od);
    if (any(isnan(trans))) trans = vec3(0.0);
    if (any(isinf(trans))) trans = vec3(1.0);

    return trans;
}

vec3 march (vec3 ro, vec3 rd, vec3 lrd, float intens, vec3 col, vec3 pos) {
    vec2 atmo = RSI(ro, rd, vec4(vec3(0.0), atmorad));
    vec2 plan = RSI(ro, rd, vec4(vec3(0.0), atmolowerlim));

    bool atmoi = atmo.y >= 0.0;
    bool plani = plan.x >= 0.0;

    col *= float(!plani);

    vec2 idk = vec2((plani && plan.x < 0.0) ? plan.y : max(atmo.x, 0.0), (plani && plan.x > 0.0) ? plan.x : atmo.y);

    float t;

    if (pos != vec3(0)){
        t = length(pos) / float(points);
    } else {
        t = length(idk.y - idk.x) / float(points);
    }
    
    vec3 step = rd * t;
    vec3 p = rd * idk.x + step * 0.5 + ro;

    float mu = dot(rd, lrd);

    float rayphase = rphase(mu);
    float miephase = mphase2(mu);
    
    vec3 scattero = vec3(PreethamBetaO_Fit(680.0), PreethamBetaO_Fit(550.0), PreethamBetaO_Fit(440.0)) * 2.5035422e25 * exp(-25e3 / 8e3) * 134.628 / 48.0 * 3e-6 * ozone;
    
    #ifndef CUSTOMRAYLEIGH
    vec3 scatterr = vec3(BetaR(680.0), BetaR(550.0), BetaR(440.0));
    #endif

    vec3 scattering = vec3(0.0);
    vec3 trans = vec3(1.0);
    for (int i = 0; i < points; i++, p += step) {
        vec3 dens = dens2(length(p));
        if (dens.x > 1e35) break;
        if (dens.y > 1e35) break;
        if (dens.z > 1e35) break;

        vec3 mass = t * dens;
        if (any(isnan(mass))) mass = vec3(0.0);

        vec3 stepod = (scatterr * mass.x) + (scatterm * mass.y) + (scattero * mass.z);

        vec3 steptrans = exp(-stepod);
        vec3 scatter = trans * (steptrans - 1.0) / -stepod;

        scattering += (scatterr * mass.x * rayphase + scatterm * mass.y * miephase) * scatter * lighttrans(p, lrd);
        
    }
    if (any(isnan(scattering))) return vec3(0.0);

    return scattering * intens + col * trans;
}

vec3 sky (vec3 ro, vec3 rd, vec3 sunrd, vec3 col, bool includeSun, vec3 pos) {
    vec3 sun = dot(rd, sunrd) > cos(radians(sundeg)) && includeSun ? vec3(sunintens) : col;
    ro.y += planetrad;
    return march(ro, rd, sunrd, sunintens, sun, pos);
}

#define SUN_VECTOR normalize(mat3(gbufferModelViewInverse) * sunPosition)

vec3 getSky(vec3 dir, bool includeSun){
    return sky(vec3(0.), dir, SUN_VECTOR, vec3(0.), includeSun, vec3(0.));
}

vec3 getAtmosphere(vec3 col, vec3 playerPos){
    vec3 dir = normalize(playerPos);
    return sky(vec3(0.), dir, SUN_VECTOR, col, false, playerPos);
}
