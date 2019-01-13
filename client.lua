ESX = nil
local PlayerData = {}
local whitelistedWeapons = {}
local playerPed = GetPlayerPed(-1)
local playerPosition = nil
local streetHash1 = 0
local streetHash2 = 0
local streetName1 = ''
local streetName2 = ''
local vehicle = 0
local isInPoliceVehicle = false
local playerSex = ''
local zoneName = ''

Citizen.CreateThread(function()
    initEsx()
    initWhitelistedWeapons()

    Citizen.CreateThread(getPlayerSexLoop)
    Citizen.CreateThread(gatherDataLoop)
    Citizen.CreateThread(initDecorLoop)
    Citizen.CreateThread(decorLoop)

    Citizen.CreateThread(carJackingLoop)
    Citizen.CreateThread(meleeCombatLoop)
    Citizen.CreateThread(shootingLoop)
end)

function initEsx()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while true do
        local playerData = ESX.GetPlayerData()
        if playerData.job ~= nil then
            PlayerData = playerData
            break
        end
        Citizen.Wait(10)
    end
end

function initWhitelistedWeapons()
    for _, weaponModel in pairs(Config.WeaponWhitelist) do
        whitelistedWeapons[GetHashKey(weaponModel)] = true
    end
end

function getPlayerSexLoop()
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
end

function gatherDataLoop()
    while true do
        playerPed = GetPlayerPed(-1)
        playerPosition = GetEntityCoords(playerPed,  true)

        streetHash1, streetHash2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, playerPosition.x, playerPosition.y, playerPosition.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
        streetName1 = GetStreetNameFromHashKey(streetHash1)
        streetName2 = GetStreetNameFromHashKey(streetHash2)

        vehicle = GetVehiclePedIsIn(playerPed, false)
        isInPoliceVehicle = IsPedInAnyPoliceVehicle(playerPed)

        local zoneNameId = GetNameOfZone(playerPosition.x, playerPosition.y, playerPosition.y)
        zoneName = ZoneNames[string.upper(zoneNameId)]
        
        Wait(100)
    end
end

function initDecorLoop()
    while true do
        if NetworkIsSessionStarted() then
            DecorRegister('IsOutlaw',  3)
            DecorSetInt(playerPed, 'IsOutlaw', 1)
            return
        end

        Wait(0)
    end
end

function decorLoop()
    while true do
        if DecorGetInt(playerPed, 'IsOutlaw') == 2 then
            Wait(Config.Timer * 60000)
            DecorSetInt(playerPed, 'IsOutlaw', 1)
        end

        Wait(0)
    end
end

function carJackingLoop()
    while true do
        Wait(0)

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

                        if streetHash2 == 0 and isInPoliceVehicle then
                            TriggerServerEvent('thiefInProgressS1police', streetName1, vehicleName, playerSex, zoneName)
                        elseif streetHash2 == 0 then
                            TriggerServerEvent('thiefInProgressS1', streetName1, vehicleName, playerSex, zoneName)
                        elseif isInPoliceVehicle then
                            TriggerServerEvent('thiefInProgressPolice', streetName1, streetName2, vehicleName, playerSex, zoneName)
                        else
                            TriggerServerEvent('thiefInProgress', streetName1, streetName2, vehicleName, playerSex, zoneName)
                        end
                    end
                end, vehicleProps)
            end
        end
    end
end

function meleeCombatLoop()
    while true do
        Wait(0)
        
        if IsPedInMeleeCombat(playerPed) then
            DecorSetInt(playerPed, 'IsOutlaw', 2)

            if not isPlayerPoliceOfficer() or Config.ShowCopsMisbehave then
                TriggerServerEvent('meleeInProgressPos', playerPosition.x, playerPosition.y, playerPosition.z)

                if streetHash2 == 0 then
                    TriggerServerEvent('meleeInProgressS1', streetName1, playerSex, zoneName)
                else
                    TriggerServerEvent('meleeInProgress', streetName1, streetName2, playerSex, zoneName)
                end

                Wait(3000)
            end
        end
    end
end

function shootingLoop()
    while true do
        Wait(0)

        if IsPedShooting(playerPed) and not whitelistedWeapons[GetSelectedPedWeapon(playerPed)] then
            DecorSetInt(playerPed, 'IsOutlaw', 2)

            if not isPlayerPoliceOfficer() or Config.ShowCopsMisbehave then
                TriggerServerEvent('gunshotInProgressPos', playerPosition.x, playerPosition.y, playerPosition.z)

                if streetHash2 == 0 then
                    TriggerServerEvent('gunshotInProgressS1', streetName1, playerSex, zoneName)
                else
                    TriggerServerEvent('gunshotInProgress', streetName1, streetName2, playerSex, zoneName)
                end

                Wait(3000)
            end
        end
    end
end

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
    if isPlayerPoliceOfficerOrInVehicle() then
        ESX.ShowNotification(alert)
    end
end)

RegisterNetEvent('thiefPlace')
AddEventHandler('thiefPlace', function(tx, ty, tz)
    if Config.CarJackingAlert and isPlayerPoliceOfficerOrInVehicle() then
        showExpiringBlip(tx, ty, tz, 10, 1, Config.BlipJackingTime)
    end
end)

RegisterNetEvent('gunshotPlace')
AddEventHandler('gunshotPlace', function(gx, gy, gz)
    if Config.GunshotAlert and isPlayerPoliceOfficerOrInVehicle() then
        showExpiringBlip(gx, gy, gz, 10, 1, Config.BlipGunTime)
    end
end)

RegisterNetEvent('meleePlace')
AddEventHandler('meleePlace', function(mx, my, mz)
    if Config.MeleeAlert and isPlayerPoliceOfficerOrInVehicle() then
        showExpiringBlip(mx, my, mz, 270, 17, Config.BlipMeleeTime)
    end
end)

function isPlayerPoliceOfficerOrInVehicle()
    return isPlayerPoliceOfficer() or (Config.ShowNotificationsToAnyPlayerInPoliceVehicle and isInPoliceVehicle)
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

    RemoveBlip(blip)
end
