ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('thiefInProgress')
AddEventHandler('thiefInProgress', function(street1, street2, vehicleName, sex, zoneName)
    if vehicleName == 'NULL' then
        TriggerClientEvent('outlawNotify', -1, _('unknown_vehicle_stolen_both_streets', sex, street1, street2, zoneName))
    else
        TriggerClientEvent('outlawNotify', -1, _('known_vehicle_stolen_both_streets', vehicleName, sex, street1, street2, zoneName))
    end
end)

RegisterServerEvent('thiefInProgressS1')
AddEventHandler('thiefInProgressS1', function(street1, vehicleName, sex, zoneName)
    if vehicleName == 'NULL' then
        TriggerClientEvent('outlawNotify', -1, _('unknown_vehicle_stolen_one_street', sex, street1, zoneName))
    else
        TriggerClientEvent('outlawNotify', -1, _('known_vehicle_stolen_one_street', vehicleName, sex, street1, zoneName))
    end
end)

RegisterServerEvent('thiefInProgressPolice')
AddEventHandler('thiefInProgressPolice', function(street1, street2, vehicleName, sex, zoneName)
    if vehicleName == 'NULL' then
        TriggerClientEvent('outlawNotify', -1, _('unknown_police_vehicle_stolen_both_streets', sex, street1, street2, zoneName))
    else
        TriggerClientEvent('outlawNotify', -1, _('known_police_vehicle_stolen_both_streets', vehicleName, sex, street1, street2, zoneName))
    end
end)

RegisterServerEvent('thiefInProgressS1Police')
AddEventHandler('thiefInProgressS1Police', function(street1, vehicleName, sex, zoneName)
    if vehicleName == 'NULL' then
        TriggerClientEvent('outlawNotify', -1, _('unknown_police_vehicle_stolen_one_street', sex, street1, zoneName))
    else
        TriggerClientEvent('outlawNotify', -1, _('known_police_vehicle_stolen_one_street', vehicleName, sex, street1, zoneName))
    end
end)

RegisterServerEvent('meleeInProgress')
AddEventHandler('meleeInProgress', function(street1, street2, sex, zoneName)
    TriggerClientEvent('outlawNotify', -1, _('melee_in_progress_both_streets', sex, street1, street2, zoneName))
end)

RegisterServerEvent('meleeInProgressS1')
AddEventHandler('meleeInProgressS1', function(street1, sex, zoneName)
    TriggerClientEvent('outlawNotify', -1, _('melee_in_progress_one_street', sex, street1, zoneName))
end)

RegisterServerEvent('gunshotInProgress')
AddEventHandler('gunshotInProgress', function(street1, street2, sex, zoneName)
    TriggerClientEvent('outlawNotify', -1, _('gunshots_in_progress_both_streets', sex, street1, street2, zoneName))
end)

RegisterServerEvent('gunshotInProgressS1')
AddEventHandler('gunshotInProgressS1', function(street1, sex, zoneName)
    TriggerClientEvent('outlawNotify', -1, _('gunshots_in_progress_one_street', sex, street1, zoneName))
end)

RegisterServerEvent('thiefInProgressPos')
AddEventHandler('thiefInProgressPos', function(tx, ty, tz)
    TriggerClientEvent('thiefPlace', -1, tx, ty, tz)
end)

RegisterServerEvent('gunshotInProgressPos')
AddEventHandler('gunshotInProgressPos', function(gx, gy, gz)
    TriggerClientEvent('gunshotPlace', -1, gx, gy, gz)
end)

RegisterServerEvent('meleeInProgressPos')
AddEventHandler('meleeInProgressPos', function(mx, my, mz)
    TriggerClientEvent('meleePlace', -1, mx, my, mz)
end)

ESX.RegisterServerCallback('esx_outlawalert:ownvehicle', function(source, cb, vehicleProps)
    local isFound = false
    local _source = source

    local xPlayer = ESX.GetPlayerFromId(_source)
    local vehicles = getPlayerVehicles(xPlayer.getIdentifier())

    for _, vehicle in pairs(vehicles) do
        if vehicleProps.plate == vehicle.plate then
            isFound = true
            break
        end        
    end

    cb(isFound)
end)

function getPlayerVehicles(identifier)
    local vehicles = {}
    local data = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @identifier', {['@identifier'] = identifier})

    for _, vehicle in pairs(data) do
        table.insert(vehicles, {id = vehicle.id, plate = json.decode(vehicle.vehicle).plate})
    end

    return vehicles
end
