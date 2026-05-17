local inventory = exports.ox_inventory

function notify(text, type)
    if isResourcePresent('ox_lib') then
        lib.notify({
            title = 'License Plate',
            description = text,
            type = type or 'info'
        })
    elseif Config.Framework == "esx" then
        TriggerEvent('esx:showNotification', text)
    elseif Config.Framework == "qb" then
        TriggerEvent('QBCore:Notify', text, type or 'primary')
    else
        BeginTextCommandString("STRING")
        AddTextComponentString(text)
        EndTextCommandDisplayHelp(0, 0, 1, -1)
    end
end

RegisterNetEvent('maku_plate:client:notify', function(text, type)
    notify(text, type)
end)

function getClosestVehicleToPlayer(plyPos, radius)
    local retval, statusCode = nil, 'unk'
    local range = radius and radius or Config.ClosestVehicleRange

    if GetClosestVehicle(plyPos.x, plyPos.y, plyPos.z, range, 0, 23) then
        retval = GetClosestVehicle(plyPos.x, plyPos.y, plyPos.z, range, 0, 23)
        statusCode = 'found_vehicle'
    end

    return retval, statusCode
end

function isResourcePresent(resourceName)
    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

local function takeOff(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('maku_plate:server:takeoff', netId)
end

AddEventHandler('maku_plate:client:takeoff', takeOff)
exports('takeOff', takeOff)

local function putOn(vehicle, plate)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('maku_plate:server:puton', netId, plate)
end

AddEventHandler('maku_plate:client:puton', putOn)
exports('putOn', putOn)

exports('itemUsage', function(data, slot)
    local itemData = slot or data
    if not itemData or not itemData.metadata or not itemData.metadata.plate then
        notify(Config.Locales['no_matching_plate'], 'error')
        return
    end

    local vehicle, statusCode = getClosestVehicleToPlayer(GetEntityCoords(PlayerPedId()))
    if DoesEntityExist(vehicle) then
        if statusCode == 'found_vehicle' then
            putOn(vehicle, itemData.metadata.plate)
        end
    else
        notify(Config.Locales['no_vehicle'], 'error')
    end
end)

if isResourcePresent('ox_target') then
    local target = exports.ox_target

    Citizen.CreateThread(function()
        target:addGlobalVehicle({
            {
                label = Config.TargetTakeOff,
                name = 'takeoffplate',
                icon = 'fa-solid fa-tarp',
                distance = 3.0,
                canInteract = function(vehicle, distance, coords, name, bone)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    return plate and plate:gsub('%s+', '') ~= ''
                end,
                onSelect = function(data)
                    takeOff(data.entity)
                end
            }
        })
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        target:removeGlobalVehicle('takeoffplate')
    end)
else
    RegisterCommand('plate', function(source, args, raw)
        local plyPed = PlayerPedId()
        local plyPos = GetEntityCoords(plyPed)
        local vehicle, statusCode = getClosestVehicleToPlayer(plyPos)

        if DoesEntityExist(vehicle) and statusCode == 'found_vehicle' then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate and plate:gsub('%s+', '') ~= '' then
                takeOff(vehicle)
            else
                notify(Config.Locales['no_plate'], 'error')
            end
        else
            notify(Config.Locales['no_vehicle'], 'error')
        end
    end, false)
end
