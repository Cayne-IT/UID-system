-- server.lua - Complete QBCore UID System
local QBCore = exports['qb-core']:GetCoreObject()

-- Function to get next sequential UID
local function GetNextUID(callback)
    -- Get the highest UID currently in use
    exports.oxmysql:execute('SELECT MAX(CAST(uid AS UNSIGNED)) as max_uid FROM players WHERE uid IS NOT NULL', {}, function(result)
        local nextUID = 1
        
        if #result > 0 and result[1].max_uid then
            nextUID = result[1].max_uid + 1
        end
        
        callback(tostring(nextUID))
    end)
end

-- Function to get or create permanent UID
local function GetOrCreateUID(license, callback)
    -- First check if player already has a UID
    exports.oxmysql:execute('SELECT uid FROM players WHERE license = ?', {license}, function(result)
        if #result > 0 and result[1].uid then
            callback(result[1].uid)
        else
            -- Get next sequential UID
            GetNextUID(function(newUID)
                -- Update player with new UID
                exports.oxmysql:execute('UPDATE players SET uid = ? WHERE license = ?', {newUID, license}, function(affectedRows)
                    if affectedRows > 0 then
                        callback(newUID)
                    else
                        print('[UID System] Failed to update player UID for license: ' .. license)
                        callback(nil)
                    end
                end)
            end)
        end
    end)
end

-- Event when player loads (hook into QBCore player loading)
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local license = Player.PlayerData.license
        
        -- Wait a moment to ensure player is fully loaded
        Citizen.Wait(500)
        
        GetOrCreateUID(license, function(uid)
            if uid then
                Player.PlayerData.uid = uid
                Player.Functions.SetPlayerData('uid', uid)
                
                -- Send UID to client
                TriggerClientEvent('qb-uid:client:SetUID', src, uid)
                
                print('[UID System] Assigned UID ' .. uid .. ' to player: ' .. Player.PlayerData.name)
            else
                print('[UID System] Failed to assign UID to player: ' .. Player.PlayerData.name)
            end
        end)
    end
end)

-- Alternative hook for when player first joins (before character selection)
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and not Player.PlayerData.uid then
        local license = Player.PlayerData.license
        
        GetOrCreateUID(license, function(uid)
            if uid then
                Player.PlayerData.uid = uid
                Player.Functions.SetPlayerData('uid', uid)
                TriggerClientEvent('qb-uid:client:SetUID', src, uid)
            end
        end)
    end
end)

-- Command to check own UID
QBCore.Commands.Add('myuid', 'Check your UID', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData.uid then
        TriggerClientEvent('QBCore:Notify', source, 'Your UID: ' .. Player.PlayerData.uid, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'UID not found', 'error')
    end
end)

-- Command to check player UID (admin only)
QBCore.Commands.Add('checkuid', 'Check player UID (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local uid = targetPlayer.PlayerData.uid or 'No UID assigned'
    TriggerClientEvent('QBCore:Notify', source, 'Player UID: ' .. uid, 'success')
end, 'admin')

-- Command to search player by UID (admin only)
QBCore.Commands.Add('finduid', 'Find player by UID (Admin Only)', {{name = 'uid', help = 'Player UID'}}, true, function(source, args)
    local searchUID = args[1]
    if not searchUID then
        TriggerClientEvent('QBCore:Notify', source, 'Please provide a UID', 'error')
        return
    end
    
    exports.oxmysql:execute('SELECT citizenid, charinfo FROM players WHERE uid = ?', {searchUID}, function(result)
        if #result > 0 then
            local charinfo = json.decode(result[1].charinfo)
            local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
            TriggerClientEvent('QBCore:Notify', source, 'UID ' .. searchUID .. ' belongs to: ' .. playerName .. ' (ID: ' .. result[1].citizenid .. ')', 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'No player found with UID: ' .. searchUID, 'error')
        end
    end)
end, 'admin')

-- Command to list all UIDs (admin only)
QBCore.Commands.Add('listuid', 'List all player UIDs (Admin Only)', {{name = 'page', help = 'Page number (optional)'}}, true, function(source, args)
    local page = tonumber(args[1]) or 1
    local limit = 10
    local offset = (page - 1) * limit
    
    exports.oxmysql:execute('SELECT uid, citizenid, charinfo FROM players WHERE uid IS NOT NULL ORDER BY CAST(uid AS UNSIGNED) LIMIT ? OFFSET ?', {limit, offset}, function(result)
        if #result > 0 then
            TriggerClientEvent('QBCore:Notify', source, 'UID List (Page ' .. page .. '):', 'primary')
            for i, player in ipairs(result) do
                local charinfo = json.decode(player.charinfo)
                local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
                TriggerClientEvent('QBCore:Notify', source, 'UID ' .. player.uid .. ': ' .. playerName, 'primary')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'No players found on page ' .. page, 'error')
        end
    end)
end, 'admin')

-- Export function to get player UID by server ID
exports('GetPlayerUID', function(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if Player then
        return Player.PlayerData.uid
    end
    return nil
end)

-- Export function to get player UID by citizenid
exports('GetPlayerUIDByCitizenID', function(citizenid)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        return Player.PlayerData.uid
    end
    return nil
end)

-- Export function to get player by UID
exports('GetPlayerByUID', function(uid, callback)
    exports.oxmysql:execute('SELECT citizenid FROM players WHERE uid = ?', {uid}, function(result)
        if #result > 0 then
            local Player = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
            callback(Player)
        else
            callback(nil)
        end
    end)
end)

-- Export function to check if UID exists
exports('UIDExists', function(uid, callback)
    exports.oxmysql:execute('SELECT uid FROM players WHERE uid = ?', {uid}, function(result)
        callback(#result > 0)
    end)
end)

-- Server callback for getting UID
QBCore.Functions.CreateCallback('qb-uid:server:GetUID', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        cb(Player.PlayerData.uid)
    else
        cb(nil)
    end
end)

-- Server callback for getting player by UID
QBCore.Functions.CreateCallback('qb-uid:server:GetPlayerByUID', function(source, cb, uid)
    exports.oxmysql:execute('SELECT citizenid, charinfo FROM players WHERE uid = ?', {uid}, function(result)
        if #result > 0 then
            local charinfo = json.decode(result[1].charinfo)
            cb({
                citizenid = result[1].citizenid,
                name = charinfo.firstname .. ' ' .. charinfo.lastname,
                uid = uid
            })
        else
            cb(nil)
        end
    end)
end)

-- Initialize UID system
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    print('[UID System] QBCore UID System initialized')
    
    -- Check if UID column exists in database
    exports.oxmysql:execute('SHOW COLUMNS FROM players LIKE "uid"', {}, function(result)
        if #result == 0 then
            print('[UID System] WARNING: UID column not found in players table!')
            print('[UID System] Please run: ALTER TABLE players ADD COLUMN uid VARCHAR(10) UNIQUE;')
        else
            print('[UID System] UID column found in database')
        end
    end)
end)

-- Debug command to manually assign UID (admin only)
QBCore.Commands.Add('assignuid', 'Manually assign UID to player (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local license = targetPlayer.PlayerData.license
    
    GetOrCreateUID(license, function(uid)
        if uid then
            targetPlayer.PlayerData.uid = uid
            targetPlayer.Functions.SetPlayerData('uid', uid)
            TriggerClientEvent('qb-uid:client:SetUID', targetId, uid)
            TriggerClientEvent('QBCore:Notify', source, 'Assigned UID ' .. uid .. ' to player', 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, 'Failed to assign UID', 'error')
        end
    end)
end, 'admin')