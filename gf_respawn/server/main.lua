local playerStats = {}

function ServerLog(msg)
    if Config.Debug then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    end
end

-- Events
RegisterServerEvent('gf:playerDied')
AddEventHandler('gf:playerDied', function()
    local source = source
    
    if not playerStats[source] then
        playerStats[source] = { deaths = 0, respawns = 0, heals = 0 }
    end
    
    playerStats[source].deaths = playerStats[source].deaths + 1
end)

RegisterServerEvent('gf:respawnAlive')
AddEventHandler('gf:respawnAlive', function()
    local source = source
    
    if playerStats[source] then
        playerStats[source].respawns = playerStats[source].respawns + 1
    end
end)

RegisterServerEvent('gf:respawnLobby')
AddEventHandler('gf:respawnLobby', function()
    local source = source
    
    if playerStats[source] then
        playerStats[source].respawns = playerStats[source].respawns + 1
    end
    
end)

RegisterServerEvent('gf:playerHealed')
AddEventHandler('gf:playerHealed', function()
    local source = source
    
    if not playerStats[source] then
        playerStats[source] = { deaths = 0, respawns = 0, heals = 0 }
    end
    
    playerStats[source].heals = playerStats[source].heals + 1
end)

-- ██████╗ ██╗   ██╗ ██████╗██╗  ██╗███████╗████████╗
-- ██╔══██╗██║   ██║██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝
-- ██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   
-- ██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   
-- ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   
-- ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   

-- Gestion des routing buckets
RegisterServerEvent('gf_respawn:requestBucket')
AddEventHandler('gf_respawn:requestBucket', function()
    local source = source
    local bucket = GetPlayerRoutingBucket(source)
    
    TriggerClientEvent('gf_respawn:updateBucket', source, bucket)
end)

-- Export pour que d'autres scripts puissent changer le bucket
-- et notifier automatiquement le joueur
function SetPlayerBucketWithNotification(playerId, bucket)
    SetPlayerRoutingBucket(playerId, bucket)
    TriggerClientEvent('gf_respawn:updateBucket', playerId, bucket)
end

-- Exports
exports('SetPlayerBucketWithNotification', SetPlayerBucketWithNotification)

-- ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗
-- ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
-- █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
-- ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║
-- ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║
-- ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

-- Events pour permettre aux autres scripts de contrôler le système
RegisterServerEvent('gf_respawn:disableForPlayer')
AddEventHandler('gf_respawn:disableForPlayer', function(target)
    local source = source
    local targetId = target or source
    
    TriggerClientEvent('gf_respawn:disable', targetId)
end)

RegisterServerEvent('gf_respawn:enableForPlayer')
AddEventHandler('gf_respawn:enableForPlayer', function(target)
    local source = source
    local targetId = target or source
    
    TriggerClientEvent('gf_respawn:enable', targetId)
end)

-- Exports pour le contrôle serveur
exports('DisableRespawnForPlayer', function(playerId)
    TriggerClientEvent('gf_respawn:disable', playerId)
end)

exports('EnableRespawnForPlayer', function(playerId)
    TriggerClientEvent('gf_respawn:enable', playerId)
end)

-- Déconnexion
AddEventHandler('playerDropped', function()
    local source = source
    
    if playerStats[source] then
        
        playerStats[source] = nil
    end
end)

RegisterServerEvent('gf:lobbyTeleport')
AddEventHandler('gf:lobbyTeleport', function()
    local source = source
    
    if not playerStats[source] then
        playerStats[source] = { deaths = 0, respawns = 0, heals = 0, lobbyTeleports = 0 }
    end
    
    if not playerStats[source].lobbyTeleports then
        playerStats[source].lobbyTeleports = 0
    end
    
    playerStats[source].lobbyTeleports = playerStats[source].lobbyTeleports + 1
end)
