-- ═══════════════════════════════════════════════════════════════════════
--  SERVER SIDE - SAFEZONE v3.1.0 - ANTI FANCA_ANTITANK INTEGRATION
--  Protection complète contre les kills hors zone
-- ═══════════════════════════════════════════════════════════════════════

local PlayersInZones = {}

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════

local function ServerLog(message, level)
    if not Config.ServerLogs then return end
    
    local prefix = '^2[SafeZone Server]^7'
    if level == 'error' then prefix = '^1[SafeZone ERROR]^7'
    elseif level == 'warning' then prefix = '^3[SafeZone WARNING]^7'
    end
    
    print(prefix .. ' ' .. message)
end

local function GetPlayerNameSafe(source)
    local name = GetPlayerName(source)
    return name or ('Player ' .. source)
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🛡️ PROTECTION FANCA_ANTITANK
-- ═══════════════════════════════════════════════════════════════════════

local antitankHookId = nil
local antitankAvailable = false

-- Détecte si fanca_antitank est disponible
CreateThread(function()
    Wait(2000) -- Attente chargement ressources
    
    if GetResourceState('fanca_antitank') == 'started' then
        antitankAvailable = true
        ServerLog('fanca_antitank détecté - Activation de la protection avancée', 'success')
        
        -- Enregistrement du hook weaponDamageAdjust
        local antitank = exports['fanca_antitank']
        
        if antitank and antitank.registerHook then
            antitankHookId = antitank:registerHook("weaponDamageAdjust", function(payload)
                local targetId = payload.targetId
                local attackerId = payload.source
                
                -- Vérifier si la victime est en zone sécurisée
                if PlayersInZones[targetId] then
                    local zone = PlayersInZones[targetId].zoneName
                    
                    -- Récupérer la configuration de la zone
                    local zoneConfig = nil
                    for _, z in ipairs(Config.SafeZones) do
                        if z.id == zone or z.name == zone then
                            zoneConfig = z
                            break
                        end
                    end
                    
                    if zoneConfig and zoneConfig.effects then
                        -- Si la zone désactive les armes ou active godMode
                        if zoneConfig.effects.disableWeapons or zoneConfig.effects.godMode then
                            ServerLog(
                                string.format(
                                    'DÉGÂTS BLOQUÉS: %s -> %s (Zone: %s)',
                                    GetPlayerNameSafe(attackerId),
                                    GetPlayerNameSafe(targetId),
                                    zone
                                ),
                                'warning'
                            )
                            
                            -- ANNULER LES DÉGÂTS
                            return false
                        end
                    end
                end
                
                -- Vérifier si l'attaquant est en zone (optionnel)
                if Config.BlockAttacksFromSafeZone and PlayersInZones[attackerId] then
                    local attackerZone = PlayersInZones[attackerId].zoneName
                    
                    local zoneConfig = nil
                    for _, z in ipairs(Config.SafeZones) do
                        if z.id == attackerZone or z.name == attackerZone then
                            zoneConfig = z
                            break
                        end
                    end
                    
                    if zoneConfig and zoneConfig.effects and zoneConfig.effects.disableWeapons then
                        ServerLog(
                            string.format(
                                'ATTAQUE DEPUIS ZONE BLOQUÉE: %s -> %s',
                                GetPlayerNameSafe(attackerId),
                                GetPlayerNameSafe(targetId)
                            ),
                            'warning'
                        )
                        return false
                    end
                end
                
                -- Flux normal
                return true
            end)
            
            ServerLog('Hook weaponDamageAdjust enregistré (ID: ' .. tostring(antitankHookId) .. ')', 'success')
        else
            ServerLog('Impossible d\'enregistrer le hook fanca_antitank', 'error')
        end
    else
        ServerLog('fanca_antitank non détecté - Protection basique uniquement', 'warning')
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚫 BLOCAGE DES ÉVÉNEMENTS KILL
-- ═══════════════════════════════════════════════════════════════════════

-- Bloquer l'événement fanca_antitank:kill si la victime est en safezone
AddEventHandler('fanca_antitank:kill', function(targetId, playerId)
    if PlayersInZones[targetId] then
        local zone = PlayersInZones[targetId].zoneName
        
        ServerLog(
            string.format(
                'KILL BLOQUÉ: %s tentait de tuer %s (Zone: %s)',
                GetPlayerNameSafe(playerId),
                GetPlayerNameSafe(targetId),
                zone
            ),
            'warning'
        )
        
        -- ANNULER L'ÉVÉNEMENT
        CancelEvent()
        
        -- Notifier l'attaquant
        if Config.NotifyAttackerOnBlock then
            TriggerClientEvent('safezone:notifyProtectedTarget', playerId, GetPlayerNameSafe(targetId))
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 📥 EVENTS DU CLIENT
-- ═══════════════════════════════════════════════════════════════════════

RegisterNetEvent('safezone:playerEntered', function(zoneName)
    local _source = source
    local playerName = GetPlayerNameSafe(_source)
    
    PlayersInZones[_source] = {
        zoneName = zoneName,
        timestamp = os.time(),
    }
    
    ServerLog(playerName .. ' entré dans: ' .. zoneName)
    TriggerEvent('safezone:onPlayerEntered', _source, zoneName)
    
    -- Si fanca_antitank est disponible, désactiver les headshots dans la zone
    if antitankAvailable then
        local zoneConfig = nil
        for _, zone in ipairs(Config.SafeZones) do
            if zone.id == zoneName or zone.name == zoneName then
                zoneConfig = zone
                break
            end
        end
        
        if zoneConfig and zoneConfig.effects then
            if zoneConfig.effects.disableWeapons or zoneConfig.effects.disableHeadshots then
                local antitank = exports['fanca_antitank']
                if antitank and antitank.SetDisableHeadshots then
                    antitank:SetDisableHeadshots(_source, true)
                    ServerLog('Headshots désactivés pour ' .. playerName .. ' dans ' .. zoneName)
                end
            end
        end
    end
end)

RegisterNetEvent('safezone:playerLeft', function(zoneName)
    local _source = source
    local playerName = GetPlayerNameSafe(_source)
    
    local timeInZone = 0
    if PlayersInZones[_source] then
        timeInZone = os.time() - PlayersInZones[_source].timestamp
        PlayersInZones[_source] = nil
    end
    
    ServerLog(playerName .. ' sorti de: ' .. zoneName .. ' (Temps: ' .. timeInZone .. 's)')
    TriggerEvent('safezone:onPlayerLeft', _source, zoneName, timeInZone)
    
    -- Réactiver les headshots après sortie de zone
    if antitankAvailable then
        local antitank = exports['fanca_antitank']
        if antitank and antitank.RestoreDefaultHeadshots then
            antitank:RestoreDefaultHeadshots(_source)
            ServerLog('Headshots réactivés pour ' .. playerName)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 💬 NOTIFICATION CLIENT
-- ═══════════════════════════════════════════════════════════════════════

RegisterNetEvent('safezone:notifyProtectedTarget', function(targetName)
    -- Cet event est envoyé au client pour l'informer
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚪 GESTION DES DÉCONNEXIONS
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local _source = source
    if PlayersInZones[_source] then
        -- Nettoyage headshots si nécessaire
        if antitankAvailable then
            local antitank = exports['fanca_antitank']
            if antitank and antitank.RestoreDefaultHeadshots then
                antitank:RestoreDefaultHeadshots(_source)
            end
        end
        
        PlayersInZones[_source] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🎛️ COMMANDES ADMIN
-- ═══════════════════════════════════════════════════════════════════════

RegisterCommand('safezone_list', function(source, args)
    local output = function(msg)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 255},
                args = {'SafeZone', msg}
            })
        end
    end
    
    output('═══════════════════════════════════════')
    output('JOUEURS DANS LES ZONES')
    output('═══════════════════════════════════════')
    
    local count = 0
    for playerId, data in pairs(PlayersInZones) do
        count = count + 1
        local timeInZone = os.time() - data.timestamp
        output('[' .. playerId .. '] ' .. GetPlayerNameSafe(playerId) .. ' -> ' .. data.zoneName .. ' (' .. timeInZone .. 's)')
    end
    
    output('Total: ' .. count .. ' joueur(s)')
    output('═══════════════════════════════════════')
    
    if antitankAvailable then
        output('Protection fanca_antitank: ✅ ACTIVE')
        output('Hook ID: ' .. tostring(antitankHookId))
    else
        output('Protection fanca_antitank: ❌ INACTIVE')
    end
    output('═══════════════════════════════════════')
end, false)

RegisterCommand('safezone_debug', function(source, args)
    local output = function(msg)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 255},
                args = {'SafeZone', msg}
            })
        end
    end
    
    output('═══════════════════════════════════════')
    output('SAFEZONE DEBUG INFO')
    output('═══════════════════════════════════════')
    output('fanca_antitank: ' .. (antitankAvailable and '✅ Détecté' or '❌ Non détecté'))
    output('Hook ID: ' .. tostring(antitankHookId))
    output('Joueurs en zone: ' .. GetPlayersInZoneCount())
    output('Zones actives: ' .. Config.GetActiveZonesCount())
    output('═══════════════════════════════════════')
end, false)

-- ═══════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS SERVEUR
-- ═══════════════════════════════════════════════════════════════════════

exports('GetPlayersInZone', function(zoneName)
    local players = {}
    for playerId, data in pairs(PlayersInZones) do
        if data.zoneName == zoneName then
            table.insert(players, playerId)
        end
    end
    return players
end)

exports('IsPlayerInZone', function(playerId)
    return PlayersInZones[playerId] ~= nil
end)

exports('GetPlayerZone', function(playerId)
    if PlayersInZones[playerId] then
        return PlayersInZones[playerId].zoneName
    end
    return nil
end)

exports('GetPlayersInZoneCount', function()
    local count = 0
    for _ in pairs(PlayersInZones) do
        count = count + 1
    end
    return count
end)

function GetPlayersInZoneCount()
    return exports['esx_safezone']:GetPlayersInZoneCount()
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[SafeZone Server]^7 ═══════════════════════════════════════')
    print('^2[SafeZone Server]^7 SAFEZONE v3.1.0 SERVER DÉMARRÉ')
    print('^2[SafeZone Server]^7 ═══════════════════════════════════════')
    print('^2[SafeZone Server]^7 Zones actives: ' .. Config.GetActiveZonesCount())
    print('^2[SafeZone Server]^7 Protection fanca_antitank: En attente...')
    print('^2[SafeZone Server]^7 ═══════════════════════════════════════')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Nettoyer le hook fanca_antitank
    if antitankAvailable and antitankHookId then
        local antitank = exports['fanca_antitank']
        if antitank and antitank.removeHooks then
            antitank:removeHooks(antitankHookId)
            ServerLog('Hook fanca_antitank supprimé', 'success')
        end
    end
    
    -- Restaurer les headshots pour tous les joueurs en zone
    for playerId, _ in pairs(PlayersInZones) do
        if antitankAvailable then
            local antitank = exports['fanca_antitank']
            if antitank and antitank.RestoreDefaultHeadshots then
                antitank:RestoreDefaultHeadshots(playerId)
            end
        end
    end
    
    PlayersInZones = {}
    ServerLog('SafeZone arrêté proprement', 'success')
end)