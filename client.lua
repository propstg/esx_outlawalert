ESX = nil
local PlayerData = {}
local timing = Config.Timer * 60000

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    local playerPed = GetPlayerPed(-1)

    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            DecorRegister("IsOutlaw",  3)
            DecorSetInt(playerPed, "IsOutlaw", 1)
            return
        end
    end
end)

Citizen.CreateThread(function()
    local playerPed = GetPlayerPed(-1)

    while true do
        Wait(0)
        if DecorGetInt(playerPed, "IsOutlaw") == 2 then
            Wait(math.ceil(timing))
            DecorSetInt(playerPed, "IsOutlaw", 1)
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

Citizen.CreateThread(function()
    local playerPed = GetPlayerPed(-1)

    while true do
        Wait(0)
        local plyPos = GetEntityCoords(playerPed,  true)
        local s1, s2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)

        if IsPedTryingToEnterALockedVehicle(playerPed) or IsPedJacking(playerPed) then
            TriggerServerEvent('eden_garage:debug', 'carjacking!')

            Wait(3000)

            DecorSetInt(playerPed, 'IsOutlaw', 2)
            
            local coords = GetEntityCoords(playerPed)
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)

            if Config.ShowCopsMisbehave and isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_outlawalert:ownvehicle',function(valid)
                    if not valid then
                        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                            local sex = nil
                            if skin.sex == 0 then
                                sex = _('male')
                            else
                                sex = _('female')
                            end
                            TriggerServerEvent('thiefInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                            local veh = GetVehiclePedIsTryingToEnter(playerPed)
                            local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                            local vehName2 = GetLabelText(vehName)
                            if s2 == 0 then
                                if IsPedInAnyPoliceVehicle(playerPed) then
                                    TriggerServerEvent('thiefInProgressS1police', street1, vehName2, sex)
                                else
                                    TriggerServerEvent('thiefInProgressS1', street1, vehName2, sex)
                                end
                            elseif s2 ~= 0 then
                                if IsPedInAnyPoliceVehicle(playerPed) then
                                    TriggerServerEvent('thiefInProgressPolice', street1, street2, vehName2, sex)
                                else
                                    TriggerServerEvent('thiefInProgress', street1, street2, vehName2, sex)
                                end
                            end
                        end)
                    end
                end, vehicleProps)
            elseif not isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_outlawalert:ownvehicle',function(valid)
                    if (valid) then
                    else
                        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                            local sex = nil
                            if skin.sex == 0 then
                                sex = _('male')
                            else
                                sex = _('female')
                            end
                            TriggerServerEvent('thiefInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                            local veh = GetVehiclePedIsTryingToEnter(playerPed)
                            local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                            local vehName2 = GetLabelText(vehName)
                            if s2 == 0 then
                                TriggerServerEvent('thiefInProgressS1', street1, vehName2, sex)
                            elseif s2 ~= 0 then
                                TriggerServerEvent('thiefInProgress', street1, street2, vehName2, sex)
                            end
                        end)
                    end
                end, vehicleProps)
            end
        end
    end
end)

Citizen.CreateThread(function()
    local playerPed = GetPlayerPed(-1)

    while true do
        Wait(0)
        local plyPos = GetEntityCoords(playerPed,  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        
        if IsPedInMeleeCombat(playerPed) then
            DecorSetInt(playerPed, "IsOutlaw", 2)
            if Config.ShowCopsMisbehave and isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = _('male')
                    else
                        sex = _('female')
                    end
                    TriggerServerEvent('meleeInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('meleeInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("meleeInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            elseif not isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = _('male')
                    else
                        sex = _('female')
                    end
                    TriggerServerEvent('meleeInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('meleeInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("meleeInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            end
        end
    end
end)

Citizen.CreateThread(function()
    local playerPed = GetPlayerPed(-1)

    while true do
        Wait(0)
        local plyPos = GetEntityCoords(playerPed,  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)

        if IsPedShooting(playerPed) then
            DecorSetInt(playerPed, "IsOutlaw", 2)

            if Config.ShowCopsMisbehave and isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = _('male')
                    else
                        sex = _('female')
                    end
                    TriggerServerEvent('gunshotInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('gunshotInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("gunshotInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            elseif not isPlayerPoliceOfficer() then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = _('male')
                    else
                        sex = _('female')
                    end
                    TriggerServerEvent('gunshotInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('gunshotInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("gunshotInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            end
        end
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