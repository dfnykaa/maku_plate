local original_GetVehicleNumberPlateText = GetVehicleNumberPlateText

GetVehicleNumberPlateText = function(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local plate = original_GetVehicleNumberPlateText(vehicle)
    if plate and plate:gsub('%s+', '') == '' then
        local statebag = Entity(vehicle).state.plate
        if statebag ~= nil then
            plate = statebag
        end
    end
    return plate
end
