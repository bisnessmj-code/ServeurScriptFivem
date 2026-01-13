-- ═══════════════════════════════════════════════════════════════════════════════
-- EXEMPLES D'INTÉGRATION - GF_RESPAWN v5.0
-- ═══════════════════════════════════════════════════════════════════════════════
-- Ce fichier contient des exemples concrets pour intégrer gf_respawn avec vos
-- scripts de jeu (gunfight, deathmatch, TDM, etc.)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 1 : SCRIPT GUNFIGHT AVEC ROUTING BUCKETS (RECOMMANDÉ)              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_gunfight/server/match.lua

local activeMatches = {}
local matchBuckets = {}  -- Bucket par match

-- Démarrer un match
function StartGunfightMatch(players, matchId)
    local bucketId = matchId + 100  -- Buckets 100, 101, 102, etc.
    
    matchBuckets[matchId] = bucketId
    activeMatches[matchId] = {
        players = players,
        bucket = bucketId,
        startTime = os.time()
    }
    
    -- Placer tous les joueurs dans le même bucket
    for _, playerId in ipairs(players) do
        SetPlayerRoutingBucket(playerId, bucketId)
        print(string.format("^2[GUNFIGHT]^7 Joueur %d placé en bucket %d", playerId, bucketId))
        
        -- Le système gf_respawn se désactive automatiquement !
    end
    
    -- Votre logique de jeu ici...
end

-- Terminer un match
function EndGunfightMatch(matchId)
    local match = activeMatches[matchId]
    if not match then return end
    
    -- Remettre tous les joueurs dans le monde normal
    for _, playerId in ipairs(match.players) do
        SetPlayerRoutingBucket(playerId, 0)
        print(string.format("^2[GUNFIGHT]^7 Joueur %d remis en bucket 0", playerId))
        
        -- Le système gf_respawn se réactive automatiquement !
    end
    
    activeMatches[matchId] = nil
    matchBuckets[matchId] = nil
end

-- Cleanup à la déconnexion
AddEventHandler('playerDropped', function()
    local playerId = source
    
    -- Chercher le match du joueur
    for matchId, match in pairs(activeMatches) do
        for i, pId in ipairs(match.players) do
            if pId == playerId then
                table.remove(match.players, i)
                print(string.format("^2[GUNFIGHT]^7 Joueur %d retiré du match %d", playerId, matchId))
                break
            end
        end
    end
end)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 2 : DEATHMATCH AVEC EXPORTS (SI PAS DE BUCKETS)                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_dm/server/game.lua

local playersInGame = {}

-- Joueur rejoint le deathmatch
RegisterNetEvent('dm:joinGame')
AddEventHandler('dm:joinGame', function()
    local playerId = source
    
    -- Désactiver le système gf_respawn
    exports['gf_respawn']:DisableRespawnForPlayer(playerId)
    
    playersInGame[playerId] = {
        kills = 0,
        deaths = 0,
        joinTime = os.time()
    }
    
    TriggerClientEvent('dm:gameStarted', playerId)
    
    print(string.format("^3[DM]^7 Joueur %d en jeu (respawn désactivé)", playerId))
end)

-- Joueur quitte le deathmatch
RegisterNetEvent('dm:leaveGame')
AddEventHandler('dm:leaveGame', function()
    local playerId = source
    
    if not playersInGame[playerId] then return end
    
    -- Réactiver le système gf_respawn
    exports['gf_respawn']:EnableRespawnForPlayer(playerId)
    
    local stats = playersInGame[playerId]
    playersInGame[playerId] = nil
    
    TriggerClientEvent('dm:gameStopped', playerId)
    
    print(string.format("^3[DM]^7 Joueur %d hors jeu (respawn réactivé)", playerId))
    print(string.format("^3[DM]^7 Stats: %d kills, %d deaths", stats.kills, stats.deaths))
end)

-- Cleanup
AddEventHandler('playerDropped', function()
    local playerId = source
    
    if playersInGame[playerId] then
        playersInGame[playerId] = nil
    end
end)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 3 : TDM AVEC ÉQUIPES (BUCKETS PAR ÉQUIPE)                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_tdm/server/teams.lua

local BUCKET_RED_TEAM = 200
local BUCKET_BLUE_TEAM = 201

local teams = {
    red = {},
    blue = {}
}

-- Joueur rejoint équipe rouge
RegisterNetEvent('tdm:joinRedTeam')
AddEventHandler('tdm:joinRedTeam', function()
    local playerId = source
    
    SetPlayerRoutingBucket(playerId, BUCKET_RED_TEAM)
    
    table.insert(teams.red, playerId)
    
    TriggerClientEvent('tdm:teamAssigned', playerId, 'red')
    
    print(string.format("^1[TDM]^7 Joueur %d rejoint l'équipe rouge", playerId))
end)

-- Joueur rejoint équipe bleue
RegisterNetEvent('tdm:joinBlueTeam')
AddEventHandler('tdm:joinBlueTeam', function()
    local playerId = source
    
    SetPlayerRoutingBucket(playerId, BUCKET_BLUE_TEAM)
    
    table.insert(teams.blue, playerId)
    
    TriggerClientEvent('tdm:teamAssigned', playerId, 'blue')
    
    print(string.format("^4[TDM]^7 Joueur %d rejoint l'équipe bleue", playerId))
end)

-- Joueur quitte les équipes
RegisterNetEvent('tdm:leaveTeam')
AddEventHandler('tdm:leaveTeam', function()
    local playerId = source
    
    -- Remettre dans le monde normal
    SetPlayerRoutingBucket(playerId, 0)
    
    -- Retirer des équipes
    for i, pId in ipairs(teams.red) do
        if pId == playerId then
            table.remove(teams.red, i)
            break
        end
    end
    
    for i, pId in ipairs(teams.blue) do
        if pId == playerId then
            table.remove(teams.blue, i)
            break
        end
    end
    
    print(string.format("^5[TDM]^7 Joueur %d a quitté le TDM", playerId))
end)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 4 : ZONE D'ENTRAÎNEMENT (CLIENT-SIDE)                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_training/client/zones.lua

local trainingZone = {
    coords = vector3(100.0, 200.0, 30.0),
    radius = 50.0
}

local isInTraining = false

CreateThread(function()
    while true do
        Wait(1000)  -- Check toutes les secondes
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - trainingZone.coords)
        
        if distance <= trainingZone.radius then
            -- Joueur dans la zone
            if not isInTraining then
                isInTraining = true
                
                -- Désactiver le respawn
                exports['gf_respawn']:DisableRespawnSystem()
                
                TriggerEvent('chatMessage', '^2[TRAINING]', {0, 255, 0}, 'Zone d\'entraînement - Respawn désactivé')
            end
        else
            -- Joueur hors de la zone
            if isInTraining then
                isInTraining = false
                
                -- Réactiver le respawn
                exports['gf_respawn']:EnableRespawnSystem()
                
                TriggerEvent('chatMessage', '^2[TRAINING]', {0, 255, 0}, 'Vous avez quitté la zone - Respawn réactivé')
            end
        end
    end
end)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 5 : ÉVÉNEMENT SERVEUR (BATTLE ROYALE)                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_br/server/event.lua

local BUCKET_BR = 300
local brActive = false
local brPlayers = {}

-- Démarrer le Battle Royale
RegisterCommand('startbr', function(source, args)
    if brActive then
        TriggerClientEvent('chatMessage', source, '^1[BR]', {255, 0, 0}, 'Un BR est déjà en cours')
        return
    end
    
    brActive = true
    brPlayers = {}
    
    print("^5[BR]^7 Battle Royale lancé !")
    
    TriggerClientEvent('chatMessage', -1, '^5[BR]', {255, 0, 255}, 'Tapez /joinbr pour participer !')
end, false)

-- Rejoindre le Battle Royale
RegisterCommand('joinbr', function(source, args)
    if not brActive then
        TriggerClientEvent('chatMessage', source, '^1[BR]', {255, 0, 0}, 'Aucun BR en cours')
        return
    end
    
    local playerId = source
    
    -- Téléporter et placer dans le bucket BR
    SetPlayerRoutingBucket(playerId, BUCKET_BR)
    
    brPlayers[playerId] = {
        alive = true,
        kills = 0
    }
    
    TriggerClientEvent('br:joined', playerId)
    
    print(string.format("^5[BR]^7 Joueur %d a rejoint le BR", playerId))
end, false)

-- Terminer le Battle Royale
RegisterCommand('stopbr', function(source, args)
    if not brActive then return end
    
    brActive = false
    
    -- Remettre tous les joueurs dans le monde normal
    for playerId, data in pairs(brPlayers) do
        SetPlayerRoutingBucket(playerId, 0)
        TriggerClientEvent('br:ended', playerId)
    end
    
    brPlayers = {}
    
    print("^5[BR]^7 Battle Royale terminé !")
end, false)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 6 : VÉRIFICATION DU STATUT (UTILITY)                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : n'importe où (client)

-- Commande pour vérifier si le respawn est actif
RegisterCommand('checkrespawn', function()
    local isActive = exports['gf_respawn']:IsRespawnSystemEnabled()
    
    if isActive then
        TriggerEvent('chatMessage', '^2[INFO]', {0, 255, 0}, 'Le système de respawn est ACTIF')
    else
        TriggerEvent('chatMessage', '^1[INFO]', {255, 0, 0}, 'Le système de respawn est INACTIF')
    end
end, false)


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  EXEMPLE 7 : SYSTÈME HYBRIDE (BUCKETS + EXPORTS)                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- Fichier : votre_script_pvp/server/arena.lua

local BUCKET_ARENA = 400
local arenaPlayers = {}

-- Entrer dans l'arène
RegisterNetEvent('arena:enter')
AddEventHandler('arena:enter', function()
    local playerId = source
    
    -- Méthode 1 : Bucket (isolation)
    SetPlayerRoutingBucket(playerId, BUCKET_ARENA)
    
    -- Méthode 2 : Export (double sécurité)
    exports['gf_respawn']:DisableRespawnForPlayer(playerId)
    
    arenaPlayers[playerId] = true
    
    TriggerClientEvent('arena:entered', playerId)
    
    print(string.format("^6[ARENA]^7 Joueur %d dans l'arène (double protection)", playerId))
end)

-- Sortir de l'arène
RegisterNetEvent('arena:leave')
AddEventHandler('arena:leave', function()
    local playerId = source
    
    if not arenaPlayers[playerId] then return end
    
    -- Remettre dans le monde normal
    SetPlayerRoutingBucket(playerId, 0)
    
    -- Réactiver le respawn
    exports['gf_respawn']:EnableRespawnForPlayer(playerId)
    
    arenaPlayers[playerId] = nil
    
    TriggerClientEvent('arena:left', playerId)
    
    print(string.format("^6[ARENA]^7 Joueur %d a quitté l'arène", playerId))
end)


-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DES EXEMPLES
-- ═══════════════════════════════════════════════════════════════════════════════
-- 
-- NOTES IMPORTANTES :
-- 
-- 1. ROUTING BUCKETS est la méthode RECOMMANDÉE (simple et automatique)
-- 2. Les EXPORTS sont utiles si vous ne pouvez pas utiliser de buckets
-- 3. Vous pouvez COMBINER les deux méthodes pour plus de sécurité
-- 4. Pensez toujours au CLEANUP quand un joueur se déconnecte
-- 5. TESTEZ avec Config.Debug = true pour voir les logs
-- 
-- Questions ? Activez le debug et partagez les logs !
-- ═══════════════════════════════════════════════════════════════════════════════
