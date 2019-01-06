ESX = nil
local PlayerData = {}
local timing = Config.Timer * 60000

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
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
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        Notify(alert)
    end
end)

function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            DecorRegister("IsOutlaw",  3)
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 1)
            return
        end
    end
end)

RegisterNetEvent('thiefPlace')
AddEventHandler('thiefPlace', function(tx, ty, tz)
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        if Config.CarJackingAlert then
            local transT = 250
            local thiefBlip = AddBlipForCoord(tx, ty, tz)
            SetBlipSprite(thiefBlip,  10)
            SetBlipColour(thiefBlip,  1)
            SetBlipAlpha(thiefBlip,  transT)
            SetBlipAsShortRange(thiefBlip,  1)
            while transT ~= 0 do
                Wait(Config.BlipJackingTime * 4)
                transT = transT - 1
                SetBlipAlpha(thiefBlip,  transT)
                if transT == 0 then
                    SetBlipSprite(thiefBlip,  2)
                    return
                end
            end
            
        end
    end
end)

RegisterNetEvent('gunshotPlace')
AddEventHandler('gunshotPlace', function(gx, gy, gz)
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        if Config.GunshotAlert then
            local transG = 250
            local gunshotBlip = AddBlipForCoord(gx, gy, gz)
            SetBlipSprite(gunshotBlip,  1)
            SetBlipColour(gunshotBlip,  1)
            SetBlipAlpha(gunshotBlip,  transG)
            SetBlipAsShortRange(gunshotBlip,  1)
            while transG ~= 0 do
                Wait(Config.BlipGunTime * 4)
                transG = transG - 1
                SetBlipAlpha(gunshotBlip,  transG)
                if transG == 0 then
                    SetBlipSprite(gunshotBlip,  2)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('meleePlace')
AddEventHandler('meleePlace', function(mx, my, mz)
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        if Config.MeleeAlert then
            local transM = 250
            local meleeBlip = AddBlipForCoord(mx, my, mz)
            SetBlipSprite(meleeBlip,  270)
            SetBlipColour(meleeBlip,  17)
            SetBlipAlpha(meleeBlip,  transG)
            SetBlipAsShortRange(meleeBlip,  1)
            while transM ~= 0 do
                Wait(Config.BlipMeleeTime * 4)
                transM = transM - 1
                SetBlipAlpha(meleeBlip,  transM)
                if transM == 0 then
                    SetBlipSprite(meleeBlip,  2)
                    return
                end
            end
        end
    end
end)

Citizen.CreateThread( function()
    while true do
        Wait(0)
        if DecorGetInt(GetPlayerPed(-1), "IsOutlaw") == 2 then
            Wait( math.ceil(timing) )
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 1)
        end
    end
end)

Citizen.CreateThread( function()
    while true do
        Wait(0)
        local plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        if IsPedTryingToEnterALockedVehicle(GetPlayerPed(-1)) or IsPedJacking(GetPlayerPed(-1)) then
            TriggerServerEvent('eden_garage:debug', "carjacking!")
            Wait(3000)
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 2)
            local playerPed = GetPlayerPed(-1)
            local coords    = GetEntityCoords(playerPed)
            local vehicle =GetVehiclePedIsIn(playerPed,false)
            local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
            if PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.ShowCopsMisbehave == false then
            elseif PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.Config.ShowCopsMisbehave then
                ESX.TriggerServerCallback('esx_outlawalert:ownvehicle',function(valid)
                    if (valid) then
                    else
                        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                            local sex = nil
                            if skin.sex == 0 then
                                sex = "un homme"
                            else
                                sex = "une femme"
                            end
                            TriggerServerEvent('thiefInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                            local veh = GetVehiclePedIsTryingToEnter(GetPlayerPed(-1))
                            local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                            local vehName2 = GetLabelText(vehName)
                            if s2 == 0 then
                                if IsPedInAnyPoliceVehicle(GetPlayerPed(-1)) then
                                    TriggerServerEvent('thiefInProgressS1police', street1, vehName2, sex)
                                else
                                    TriggerServerEvent('thiefInProgressS1', street1, vehName2, sex)
                                end
                            elseif s2 ~= 0 then
                                if IsPedInAnyPoliceVehicle(GetPlayerPed(-1)) then
                                    TriggerServerEvent('thiefInProgressPolice', street1, street2, vehName2, sex)
                                else
                                    TriggerServerEvent('thiefInProgress', street1, street2, vehName2, sex)
                                end
                            end
                        end)
                    end
                end, vehicleProps)
            else
                ESX.TriggerServerCallback('esx_outlawalert:ownvehicle',function(valid)
                    if (valid) then
                    else
                        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                            local sex = nil
                            if skin.sex == 0 then
                                sex = "un homme"
                            else
                                sex = "une femme"
                            end
                            TriggerServerEvent('thiefInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                            local veh = GetVehiclePedIsTryingToEnter(GetPlayerPed(-1))
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

Citizen.CreateThread( function()
    while true do
        Wait(0)
        local plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        if IsPedInMeleeCombat(GetPlayerPed(-1)) then
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 2)
            if PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.ShowCopsMisbehave == false then
            elseif PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.ShowCopsMisbehave then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "un homme"
                    else
                        sex = "une femme"
                    end
                    TriggerServerEvent('meleeInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('meleeInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("meleeInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            else
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "un homme"
                    else
                        sex = "une femme"
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

Citizen.CreateThread( function()
    while true do
        Wait(0)
        local plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        if IsPedShooting(GetPlayerPed(-1)) then
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 2)
            if PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.ShowCopsMisbehave == false then
            elseif PlayerData.job ~= nil and PlayerData.job.name == 'police' and Config.ShowCopsMisbehave then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "un homme"
                    else
                        sex = "une femme"
                    end
                    TriggerServerEvent('gunshotInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('gunshotInProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent("gunshotInProgress", street1, street2, sex)
                    end
                end)
                Wait(3000)
            else
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "un homme"
                    else
                        sex = "une femme"
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
