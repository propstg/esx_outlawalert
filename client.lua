ESX = nil
local PlayerData = {}
local playerPed = GetPlayerPed(-1)
local playerPosition = nil
local streetHash1 = 0
local streetHash2 = 0
local streetName1 = ''
local streetName2 = ''
local vehicle = 0
local playerSex = ''

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    Citizen.CreateThread(function()
        while true do
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                if skin.sex == 0 then
                    playerSex = _('male')
                else
                    playerSex = _('female')
                end
            end)
            
            Wait(30000)
        end
    end)

    while true do
        playerPosition = GetEntityCoords(playerPed,  true)
        streetHash1, streetHash2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, playerPosition.x, playerPosition.y, playerPosition.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
        streetName1 = GetStreetNameFromHashKey(streetHash1)
        streetName2 = GetStreetNameFromHashKey(streetHash2)
        vehicle = GetVehiclePedIsIn(playerPed, false)
        
        Wait(100)
    end
end)

Citizen.CreateThread(function()
    while true do
        if NetworkIsSessionStarted() then
            DecorRegister('IsOutlaw',  3)
            DecorSetInt(playerPed, 'IsOutlaw', 1)
            return
        end

        Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        if DecorGetInt(playerPed, 'IsOutlaw') == 2 then
            Wait(Config.Timer * 60000)
            DecorSetInt(playerPed, 'IsOutlaw', 1)
        end

        Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(15)

        if IsPedTryingToEnterALockedVehicle(playerPed) or IsPedJacking(playerPed) then
            TriggerServerEvent('eden_garage:debug', 'carjacking!')

            Wait(3000)

            DecorSetInt(playerPed, 'IsOutlaw', 2)
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)

            if not isPlayerPoliceOfficer() or Config.ShowCopsMisbehave then
                ESX.TriggerServerCallback('esx_outlawalert:ownvehicle', function(valid)
                    if not valid then
                        TriggerServerEvent('thiefInProgressPos', playerPosition.x, playerPosition.y, playerPosition.z)

                        local jackingVehicle = GetVehiclePedIsTryingToEnter(playerPed)
                        local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(jackingVehicle)))
                        local isPoliceVehicle = IsPedInAnyPoliceVehicle(playerPed)

                        if streetHash2 == 0 and isPoliceVehicle then
                            TriggerServerEvent('thiefInProgressS1police', streetName1, vehicleName, playerSex)
                        elseif streetHash2 == 0 then
                            TriggerServerEvent('thiefInProgressS1', streetName1, vehicleName, playerSex)
                        elseif isPoliceVehicle then
                            TriggerServerEvent('thiefInProgressPolice', streetName1, streetName2, vehicleName, playerSex)
                        else
                            TriggerServerEvent('thiefInProgress', streetName1, streetName2, vehicleName, playerSex)
                        end
                    end
                end, vehicleProps)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(15)
        
        if IsPedInMeleeCombat(playerPed) then
            DecorSetInt(playerPed, 'IsOutlaw', 2)

            if not isPlayerPoliceOfficer() or Config.ShowCopsMisbehave then
                TriggerServerEvent('meleeInProgressPos', playerPosition.x, playerPosition.y, playerPosition.z)

                if streetHash2 == 0 then
                    TriggerServerEvent('meleeInProgressS1', streetName1, playerSex)
                else
                    TriggerServerEvent('meleeInProgress', streetName1, streetName2, playerSex)
                end

                Wait(3000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(15)

        if IsPedShooting(playerPed) then
            DecorSetInt(playerPed, 'IsOutlaw', 2)

            if not isPlayerPoliceOfficer() or Config.ShowCopsMisbehave then
                TriggerServerEvent('gunshotInProgressPos', playerPosition.x, playerPosition.y, playerPosition.z)

                if streetHash2 == 0 then
                    TriggerServerEvent('gunshotInProgressS1', streetName1, playerSex)
                else
                    TriggerServerEvent('gunshotInProgress', streetName1, streetName2, playerSex)
                end

                Wait(3000)
            end
        end
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('outlawNotify')
AddEventHandler('outlawNotify', function(alert)
    if isPlayerPoliceOfficer() then
        Notify(alert)
    end
end)

RegisterNetEvent('thiefPlace')
AddEventHandler('thiefPlace', function(tx, ty, tz)
    if Config.CarJackingAlert and isPlayerPoliceOfficer() then
        showExpiringBlip(tx, ty, tz, 10, 1, Config.BlipJackingTime)
    end
end)

RegisterNetEvent('gunshotPlace')
AddEventHandler('gunshotPlace', function(gx, gy, gz)
    if Config.GunshotAlert and isPlayerPoliceOfficer() then
        showExpiringBlip(gx, gy, gz, 1, 1, Config.BlipGunTime)
    end
end)

RegisterNetEvent('meleePlace')
AddEventHandler('meleePlace', function(mx, my, mz)
    if Config.MeleeAlert and isPlayerPoliceOfficer() then
        showExpiringBlip(mx, my, mz, 270, 17, Config.BlipMeleeTime)
    end
end)

function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function isPlayerPoliceOfficer()
    return PlayerData.job ~= nil and PlayerData.job.name == 'police'
end

function showExpiringBlip(x, y, z, sprite, color, decayTime)
    local transparency = 250
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, transparency)
    SetBlipAsShortRange(blip, 1)

    while transparency > 0 do
        Wait(decayTime * 4)
        transparency = transparency - 1
        SetBlipAlpha(blip, transparency)
    end

    SetBlipSprite(blip, 2)
end