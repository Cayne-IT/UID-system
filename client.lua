-- client.lua for QBCore UID System

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local playerUID = nil

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    playerUID = PlayerData.uid
end)

-- Update player data when it changes
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    playerUID = nil
end)

-- Update player data
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    if val.uid then
        playerUID = val.uid
    end
end)

-- Receive UID from server (if using separate resource method)
RegisterNetEvent('qb-uid:client:SetUID', function(uid)
    playerUID = uid
end)

-- Command to show own UID
RegisterCommand('myuid', function()
    if playerUID then
        QBCore.Functions.Notify('Your UID: ' .. playerUID, 'success', 3000)
    else
        QBCore.Functions.Notify('UID not loaded yet', 'error', 3000)
    end
end)

-- Export function to get current player's UID
exports('GetMyUID', function()
    return playerUID
end)

-- Export function to get player data (includes UID)
exports('GetPlayerData', function()
    return PlayerData
end)

-- Alternative way to get UID from QBCore player data
exports('GetUIDFromPlayerData', function()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData.uid
end)