groundRadiusMM = 6.36
atmosphereRadiusMM = 6.46

ozoneAbsorptionBase_clear = vec(0.650, 1.881, 0.085)
rayleighScatteringBase_clear = vec(5.802, 13.558, 33.1)
rayleighAbsorptionBase_clear = 0.0
mieScatteringBase_clear = 3.996
mieAbsorptionBase_clear = 4.4

ozoneAbsorptionBase_rain = vec(0.650, 1.381, 0.576)
rayleighScatteringBase_rain = vec(80.802, 130.558, 200.1)
rayleighAbsorptionBase_rain = 32.0
mieScatteringBase_rain = 3.996 * 22.0
mieAbsorptionBase_rain = 4.4 * 12.0

ozoneAbsorptionBase_end = vec(0.650, 8.381, 8.576)
rayleighScatteringBase_end = vec(64.802, 6.558, 28.1)
rayleighAbsorptionBase_end = 6.0
mieScatteringBase_end = 3.996 * 4.0
mieAbsorptionBase_end = 4.4 * 10.0

transmittanceSteps = 40


TYPE_CLEAR = 0
TYPE_RAIN = 1
TYPE_END = 4


function getAtmosType(z)
    if z < (1.0/5.0) then return TYPE_CLEAR
    elseif z < (3.0/5.0) then return TYPE_RAIN
    else return TYPE_END
    end
end

function getOzoneAbsorptionBase(atmosType)
    if atmosType == TYPE_CLEAR then return ozoneAbsorptionBase_clear
    elseif atmosType == TYPE_RAIN then return ozoneAbsorptionBase_rain
    elseif atmosType == TYPE_END then return ozoneAbsorptionBase_end
    else error("Unknown atmosphere type!")
    end
end

function getRayleighScatteringBase(atmosType)
    if atmosType == TYPE_CLEAR then return rayleighScatteringBase_clear
    elseif atmosType == TYPE_RAIN then return rayleighScatteringBase_rain
    elseif atmosType == TYPE_END then return rayleighScatteringBase_end
    else error("Unknown atmosphere type!")
    end
end

function getRayleighAbsorptionBase(atmosType)
    if atmosType == TYPE_CLEAR then return rayleighAbsorptionBase_clear
    elseif atmosType == TYPE_RAIN then return rayleighAbsorptionBase_rain
    elseif atmosType == TYPE_END then return rayleighAbsorptionBase_end
    else error("Unknown atmosphere type!")
    end
end

function getMieScatteringBase(atmosType)
    if atmosType == TYPE_CLEAR then return mieScatteringBase_clear
    elseif atmosType == TYPE_RAIN then return mieScatteringBase_rain
    elseif atmosType == TYPE_END then return mieScatteringBase_end
    else error("Unknown atmosphere type!")
    end
end

function getMieAbsorptionBase(atmosType)
    if atmosType == TYPE_CLEAR then return mieAbsorptionBase_clear
    elseif atmosType == TYPE_RAIN then return mieAbsorptionBase_rain
    elseif atmosType == TYPE_END then return mieAbsorptionBase_end
    else error("Unknown atmosphere type!")
    end
end

function getAtmosTypeZ(atmosType)
    if atmosType == TYPE_CLEAR then return 0.5 / 5.0
    elseif atmosType == TYPE_RAIN then return 1.5 / 5.0
    elseif atmosType == TYPE_END then return 4.5 / 5.0
    else error("Unknown atmosphere type!")
    end
end


function safeacos(x)
    return acos(clamp(x, -1.0, 1.0))
end

function rayIntersectSphere(pos, dir, radius)
    local NoV = dot(pos, dir)
    local c = dot(pos, pos) - radius^2

    if c > 0.0 and NoV > 0.0 then
        return -1.0
    end

    local discr = NoV^2 - c
    if discr < 0.0 then
        return -1.0
    end

    -- Special case: inside sphere, use far discriminant
    if discr > NoV^2 then
        return -NoV + sqrt(discr)
    end

    return -NoV - sqrt(discr)
end

function getScatteringValues(pos, atmosType)
    local altitudeKM = (length(pos) - groundRadiusMM) * 1000.0
    -- Note: Paper gets these switched up.
    local rayleighDensity = exp(-altitudeKM / 8.0)
    local mieDensity = exp(-altitudeKM / 1.2)
    
    local rayleighScattering = getRayleighScatteringBase(atmosType) * rayleighDensity
    local rayleighAbsorption = getRayleighAbsorptionBase(atmosType) * rayleighDensity
    
    local mieScattering = getMieScatteringBase(atmosType) * mieDensity
    local mieAbsorption = getMieAbsorptionBase(atmosType) * mieDensity
    
    local ozoneAbsorption = getOzoneAbsorptionBase(atmosType) * max(0.0, 1.0 - abs(altitudeKM - 25.0) / 15.0)
    
    local extinction = rayleighScattering + rayleighAbsorption + mieScattering + mieAbsorption + ozoneAbsorption

    return rayleighScattering, mieScattering, extinction
end

function getSunTransmittance(pos, sunDir, atmosType)
    if rayIntersectSphere(pos, sunDir, groundRadiusMM) > 0.0 then
        return vec3(0.0)
    end
    
    local atmoDist = rayIntersectSphere(pos, sunDir, atmosphereRadiusMM)
    local transmittance = vec3(1.0)
    local t = 0.0

    for i = 0,transmittanceSteps-1,1 do
        local newT = ((i + 0.3) / transmittanceSteps) * atmoDist
        local dt = newT - t
        t = newT
        
        local newPos = pos + t*sunDir
        local rayleighScattering, mieScattering, extinction = getScatteringValues(newPos, atmosType)
        
        transmittance = transmittance * exp(-dt*extinction)
    end

    return transmittance
end