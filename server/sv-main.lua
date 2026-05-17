local inventory = exports.ox_inventory

local ESX = nil
local QBCore = nil

if Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function notify(source, text, type)
    TriggerClientEvent('maku_plate:client:notify', source, text, type)
end

local function isVehicleOwned(source, plate)
    local formattedPlate = string.upper(plate:gsub('%s+', ''))
    
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local result = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE owner = ? AND REPLACE(plate, " ", "") = ?', {
            xPlayer.identifier,
            formattedPlate
        })
        return result ~= nil
    elseif Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE citizenid = ? AND REPLACE(plate, " ", "") = ?', {
            Player.PlayerData.citizenid,
            formattedPlate
        })
        return result ~= nil
    end
    
    return true
end

RegisterNetEvent('maku_plate:server:takeoff', function(netId)
    local source = source

    if not inventory:CanCarryItem(source, Config.PlateItem, 1) then
        notify(source, Config.Locales['inventory_full'], 'error')
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        notify(source, Config.Locales['no_vehicle'], 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate:gsub('%s+', '') == '' then
        notify(source, Config.Locales['no_plate'], 'error')
        return
    end

    local playerPed = GetPlayerPed(source)
    if DoesEntityExist(GetVehiclePedIsIn(playerPed)) then
        notify(source, Config.Locales['inside_vehicle'], 'error')
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    if distance > (Config.ClosestVehicleRange + 2.0) then
        notify(source, Config.Locales['too_far'], 'error')
        return
    end

    if Config.OnlyOwner then
        if not isVehicleOwned(source, plate) then
            notify(source, Config.Locales['not_owner'], 'error')
            return
        end
    end

    local vehicleType = GetVehicleType(vehicle)
    if not Config.AllowedTypes[vehicleType] then
        notify(source, Config.Locales['vehicle_not_allowed'], 'error')
        return
    end

    local duration = 5000
    local timeout = duration + 2000
    local startTime = GetGameTimer()

    startProgressbar(Config.Locales['taking_off'], duration, source)
    while getProgressbarStatus(source) == true do
        Citizen.Wait(100)
        if not GetPlayerPed(source) or GetPlayerPed(source) == 0 or (GetGameTimer() - startTime > timeout) then
            clearProgressbar(source)
            return
        end
    end

    local status = getProgressbarStatus(source)
    clearProgressbar(source)

    if status == ABORTED_PROGRESSBAR then
        notify(source, Config.Locales['action_cancelled'], 'error')
        return
    end

    local currentPlate = GetVehicleNumberPlateText(vehicle)
    if not currentPlate or currentPlate:gsub('%s+', '') == '' then
        notify(source, Config.Locales['already_removed'], 'error')
        return
    end

    Entity(vehicle).state.plate = currentPlate
    SetVehicleNumberPlateText(vehicle, Config.EmptyPlate)

    local success = inventory:AddItem(source, Config.PlateItem, 1, {
        plate = currentPlate,
        description = currentPlate
    })

    if success then
        notify(source, Config.Locales['plate_removed'], 'success')
    else
        SetVehicleNumberPlateText(vehicle, currentPlate)
        Entity(vehicle).state.plate = nil
        notify(source, Config.Locales['remove_failed'], 'error')
    end
end)

RegisterNetEvent('maku_plate:server:puton', function(netId, plate)
    local source = source

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        notify(source, Config.Locales['no_vehicle'], 'error')
        return
    end

    local statebagPlate = Entity(vehicle).state.plate
    if statebagPlate ~= plate then
        notify(source, Config.Locales['wrong_plate'], 'error')
        return
    end

    local playerPed = GetPlayerPed(source)
    if DoesEntityExist(GetVehiclePedIsIn(playerPed)) then
        notify(source, Config.Locales['inside_vehicle'], 'error')
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    if distance > (Config.ClosestVehicleRange + 2.0) then
        notify(source, Config.Locales['too_far'], 'error')
        return
    end

    local items = inventory:GetInventoryItems(source)
    local found = false
    for _, item in pairs(items) do
        if item.name == Config.PlateItem and item.metadata ~= nil and item.metadata.plate == plate then
            found = true
            break
        end
    end

    if not found then
        notify(source, Config.Locales['no_matching_plate'], 'error')
        return
    end

    local duration = 5000
    local timeout = duration + 2000
    local startTime = GetGameTimer()

    startProgressbar(Config.Locales['putting_on'], duration, source)
    while getProgressbarStatus(source) == true do
        Citizen.Wait(100)
        if not GetPlayerPed(source) or GetPlayerPed(source) == 0 or (GetGameTimer() - startTime > timeout) then
            clearProgressbar(source)
            return
        end
    end

    local status = getProgressbarStatus(source)
    clearProgressbar(source)

    if status == ABORTED_PROGRESSBAR then
        notify(source, Config.Locales['action_cancelled'], 'error')
        return
    end

    local success = inventory:RemoveItem(source, Config.PlateItem, 1, {
        plate = plate,
        description = plate
    })

    if success then
        SetVehicleNumberPlateText(vehicle, plate)
        Entity(vehicle).state.plate = nil
        notify(source, Config.Locales['plate_attached'], 'success')
    else
        notify(source, Config.Locales['attach_failed'], 'error')
    end
end)
