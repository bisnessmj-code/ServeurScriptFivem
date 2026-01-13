-- ═══════════════════════════════════════════════════════════════════════
--  CLIENT SIDE - SAFEZONE v3.1.0 - ANTI FANCA_ANTITANK INTEGRATION
--  Protection complète contre les kills hors zone
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- 📦 VARIABLES GLOBALES & CACHE
-- ═══════════════════════════════════════════════════════════════════════

local STATE = {
    -- Cache joueur
    playerPed = 0,
    playerCoords = vector3(0, 0, 0),
    
    -- État des zones
    inZone = false,
    currentZone = nil,
    
    -- État des contrôles
    weaponsDisabled = false,
    meleeDisabled = false,
    
    -- Protection spawn
    isPlayerReady = false,
    
    -- Blips
    blips = {},
}

-- Cache des contrôles (calculé une seule fois)
local WEAPON_CONTROLS = {24, 25, 37, 47, 58, 69, 70, 92, 114, 140, 141, 142, 143, 257, 263, 264, 331, 157, 158, 160, 164, 165, 45, 80}
local MELEE_CONTROLS = {140, 141, 142, 143, 24, 257}

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 UTILITAIRES SIMPLES
-- ═══════════════════════════════════════════════════════════════════════

local function DebugLog(message, level)
    if not Config.Debug then return end
    local prefix = '^3[SafeZone]^7'
    if level == 'error' then prefix = '^1[SafeZone ERROR]^7'
    elseif level == 'success' then prefix = '^2[SafeZone]^7'
    end
    print(prefix .. ' ' .. message)
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎯 DÉTECTION DES ZONES (SIMPLE ET EFFICACE)
-- ═══════════════════════════════════════════════════════════════════════

local function IsInCylinderZone(zone, coords)
    local px, py, pz = coords.x, coords.y, coords.z
    local zx, zy, zz = zone.geometry.position.x, zone.geometry.position.y, zone.geometry.position.z
    
    local dx = px - zx
    local dy = py - zy
    local horizontalDistSq = dx * dx + dy * dy
    local radiusSq = zone.geometry.radius * zone.geometry.radius
    
    if horizontalDistSq > radiusSq then
        return false
    end
    
    local height = zone.geometry.height or 20.0
    local verticalDist = math.abs(pz - zz)
    
    return verticalDist <= height
end

local function IsInSphereZone(zone, coords)
    local distance = #(coords - zone.geometry.position)
    return distance <= zone.geometry.radius
end

local function GetCurrentZone(coords)
    for _, zone in ipairs(Config.SafeZones) do
        if zone.enabled then
            local distance = #(coords - zone.geometry.position)
            -- Vérifie seulement si proche (optimisation)
            if distance < (zone.geometry.radius + 50.0) then
                local isInside = false
                if zone.geometry.type == 'cylinder' then
                    isInside = IsInCylinderZone(zone, coords)
                else
                    isInside = IsInSphereZone(zone, coords)
                end
                if isInside then
                    return zone
                end
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🔫 GESTION DES ARMES (SIMPLE)
-- ═══════════════════════════════════════════════════════════════════════

local function RemoveWeapons(ped)
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

local function ApplyZoneRestrictions(ped, zone)
    if not zone or not zone.effects then return end
    
    -- Armes
    if zone.effects.disableWeapons then
        if not STATE.weaponsDisabled then
            STATE.weaponsDisabled = true
            RemoveWeapons(ped)
            SetPedCanSwitchWeapon(ped, false)
            SetPlayerCanDoDriveBy(PlayerId(), false)
            DebugLog('Armes désactivées', 'success')
        end
    end
    
    -- Mêlée
    if zone.effects.disableMelee then
        if not STATE.meleeDisabled then
            STATE.meleeDisabled = true
            SetPedConfigFlag(ped, 122, true)
            DebugLog('Mêlée désactivée', 'success')
        end
    end
    
    -- Vitesse
    if zone.effects.speedMultiplier and zone.effects.speedMultiplier > 1.0 then
        SetRunSprintMultiplierForPlayer(PlayerId(), zone.effects.speedMultiplier)
        SetPedMoveRateOverride(ped, zone.effects.speedMultiplier)
    end
    
    -- God Mode
    if zone.effects.godMode then
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
    end
end

local function RemoveZoneRestrictions(ped)
    -- Armes
    if STATE.weaponsDisabled then
        STATE.weaponsDisabled = false
        SetPedCanSwitchWeapon(ped, true)
        SetPlayerCanDoDriveBy(PlayerId(), true)
        DebugLog('Armes réactivées', 'success')
    end
    
    -- Mêlée
    if STATE.meleeDisabled then
        STATE.meleeDisabled = false
        SetPedConfigFlag(ped, 122, false)
        DebugLog('Mêlée réactivée', 'success')
    end
    
    -- Reset vitesse et invincibilité
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPedMoveRateOverride(ped, 1.0)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 BLIPS (CRÉÉS UNE SEULE FOIS)
-- ═══════════════════════════════════════════════════════════════════════

local function CreateZoneBlips()
    if not Config.Visual or not Config.Visual.showBlips then return end
    
    for _, zone in ipairs(Config.SafeZones) do
        if zone.enabled and zone.visual and zone.visual.blip and zone.visual.blip.enabled then
            local blipData = zone.visual.blip
            local pos = zone.geometry.position
            
            -- Blip rayon
            local radiusBlip = AddBlipForRadius(pos.x, pos.y, pos.z, zone.geometry.radius)
            SetBlipHighDetail(radiusBlip, true)
            SetBlipColour(radiusBlip, blipData.color or 2)
            SetBlipAlpha(radiusBlip, 128)
            
            -- Blip centre
            local centerBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
            SetBlipSprite(centerBlip, blipData.sprite or 310)
            SetBlipDisplay(centerBlip, 4)
            SetBlipScale(centerBlip, blipData.scale or 0.8)
            SetBlipColour(centerBlip, blipData.color or 2)
            SetBlipAsShortRange(centerBlip, true)
            
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(blipData.label or zone.name)
            EndTextCommandSetBlipName(centerBlip)
            
            table.insert(STATE.blips, {radius = radiusBlip, center = centerBlip})
        end
    end
    
    DebugLog('Blips créés: ' .. #STATE.blips, 'success')
end

local function RemoveAllBlips()
    for _, blip in ipairs(STATE.blips) do
        if DoesBlipExist(blip.radius) then RemoveBlip(blip.radius) end
        if DoesBlipExist(blip.center) then RemoveBlip(blip.center) end
    end
    STATE.blips = {}
end

-- ═══════════════════════════════════════════════════════════════════════
-- 💬 NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════

local function ShowNotification(message)
    if not Config.Notifications or not Config.Notifications.enabled then return end
    
    if Config.Notifications.type == 'esx' then
        ESX.ShowNotification(message)
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 255},
            multiline = true,
            args = {'SafeZone', message}
        })
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🛡️ NOTIFICATION PROTECTION FANCA_ANTITANK
-- ═══════════════════════════════════════════════════════════════════════

RegisterNetEvent('safezone:notifyProtectedTarget', function(targetName)
    if Config.NotifyAttackerOnBlock then
        ShowNotification('~r~Impossible de tirer sur ' .. targetName .. ' (en zone sécurisée)')
        
        -- Son d'échec (optionnel)
        PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🔄 THREAD PRINCIPAL UNIQUE - ANTI-CRASH GARANTI
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    -- Attente spawn joueur
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(1000)
    end
    
    -- Protection spawn supplémentaire
    Wait(3000)
    STATE.isPlayerReady = true
    
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('SAFEZONE v3.1.0 - THREAD PRINCIPAL DÉMARRÉ', 'success')
    DebugLog('Protection fanca_antitank: ACTIVE', 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    
    -- Boucle principale - WAIT MINIMUM 500ms GARANTI
    while true do
        -- ════════════════════════════════════════════════════════════════
        -- WAIT AU DÉBUT - ABSOLUMENT CRITIQUE
        -- ════════════════════════════════════════════════════════════════
        Wait(500)
        
        -- Skip si joueur pas prêt
        if not STATE.isPlayerReady then
            goto continue
        end
        
        -- Cache joueur
        STATE.playerPed = PlayerPedId()
        STATE.playerCoords = GetEntityCoords(STATE.playerPed)
        
        -- Détection zone
        local zone = GetCurrentZone(STATE.playerCoords)
        
        if zone then
            -- ENTRÉE DANS ZONE
            if not STATE.inZone then
                STATE.inZone = true
                STATE.currentZone = zone
                
                DebugLog('ENTRÉE: ' .. zone.name, 'success')
                
                ShowNotification(Config.Notifications.messages.entering)
                
                TriggerEvent('safezone:playerEntered', zone)
                TriggerServerEvent('safezone:playerEntered', zone.id or zone.name)
            end
            
            -- Application des effets
            ApplyZoneRestrictions(STATE.playerPed, zone)
            
        else
            -- SORTIE DE ZONE
            if STATE.inZone then
                DebugLog('SORTIE: ' .. (STATE.currentZone and STATE.currentZone.name or 'Unknown'), 'success')
                
                RemoveZoneRestrictions(STATE.playerPed)
                
                ShowNotification(Config.Notifications.messages.leaving)
                
                TriggerEvent('safezone:playerLeft', STATE.currentZone)
                TriggerServerEvent('safezone:playerLeft', STATE.currentZone and (STATE.currentZone.id or STATE.currentZone.name) or 'Unknown')
                
                STATE.inZone = false
                STATE.currentZone = nil
            end
        end
        
        ::continue::
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🔒 THREAD BLOCAGE CONTRÔLES - SÉPARÉ ET SÉCURISÉ
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        -- ════════════════════════════════════════════════════════════════
        -- WAIT MINIMUM 100ms - JAMAIS MOINS
        -- ════════════════════════════════════════════════════════════════
        
        if STATE.inZone and (STATE.weaponsDisabled or STATE.meleeDisabled) then
            -- Blocage des contrôles
            if STATE.weaponsDisabled then
                for _, control in ipairs(WEAPON_CONTROLS) do
                    DisableControlAction(0, control, true)
                end
                DisablePlayerFiring(STATE.playerPed, true)
                
                -- Vérification arme équipée
                if GetSelectedPedWeapon(STATE.playerPed) ~= `WEAPON_UNARMED` then
                    RemoveWeapons(STATE.playerPed)
                end
            end
            
            if STATE.meleeDisabled then
                for _, control in ipairs(MELEE_CONTROLS) do
                    DisableControlAction(0, control, true)
                end
                DisableControlAction(0, 45, true)
                
                if IsPedInMeleeCombat(STATE.playerPed) then
                    ClearPedTasksImmediately(STATE.playerPed)
                end
            end
            
            -- Wait court pour réactivité des contrôles, mais pas trop court
            Wait(100)
        else
            -- Hors zone ou pas de restrictions = wait long
            Wait(1000)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🎛️ COMMANDES
-- ═══════════════════════════════════════════════════════════════════════

RegisterCommand('safezone', function(source, args)
    if args[1] == 'info' then
        print('═══════════════════════════════════════')
        print('SAFEZONE v3.1.0 - ANTI-CRASH GARANTI')
        print('═══════════════════════════════════════')
        print('Dans zone: ' .. tostring(STATE.inZone))
        print('Zone actuelle: ' .. (STATE.currentZone and STATE.currentZone.name or 'Aucune'))
        print('Armes désactivées: ' .. tostring(STATE.weaponsDisabled))
        print('Mêlée désactivée: ' .. tostring(STATE.meleeDisabled))
        print('Joueur prêt: ' .. tostring(STATE.isPlayerReady))
        print('Position: ' .. tostring(STATE.playerCoords))
        print('Protection fanca_antitank: ACTIVE')
        print('═══════════════════════════════════════')
        
    elseif args[1] == 'reload' then
        RemoveAllBlips()
        Wait(100)
        CreateZoneBlips()
        print('^2[SafeZone]^7 Blips rechargés')
        
    elseif args[1] == 'pos' then
        local coords = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        print(string.format('Position: vector3(%.6f, %.6f, %.6f)', coords.x, coords.y, coords.z))
        print(string.format('Heading: %.6f', heading))
        print(string.format('vector4(%.6f, %.6f, %.6f, %.6f)', coords.x, coords.y, coords.z, heading))
        
    else
        print('═══════════════════════════════════════')
        print('COMMANDES SAFEZONE v3.1.0')
        print('═══════════════════════════════════════')
        print('/safezone info    - Informations debug')
        print('/safezone reload  - Recharger blips')
        print('/safezone pos     - Position actuelle')
        print('═══════════════════════════════════════')
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS
-- ═══════════════════════════════════════════════════════════════════════

exports('IsInSafeZone', function()
    return STATE.inZone
end)

exports('GetCurrentZone', function()
    return STATE.currentZone
end)

exports('AreWeaponsDisabled', function()
    return STATE.weaponsDisabled
end)

exports('IsMeleeDisabled', function()
    return STATE.meleeDisabled
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ═══════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('SAFEZONE v3.1.0 INITIALISÉ', 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    DebugLog('Architecture: 2 threads seulement', 'success')
    DebugLog('Wait minimum: 500ms principal / 100ms contrôles', 'success')
    DebugLog('Zones configurées: ' .. #Config.SafeZones, 'success')
    DebugLog('Debug: ' .. (Config.Debug and 'ACTIVÉ' or 'DÉSACTIVÉ'), 'success')
    DebugLog('Protection fanca_antitank: ACTIVE', 'success')
    DebugLog('═══════════════════════════════════════', 'success')
    
    CreateZoneBlips()
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ═══════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    RemoveAllBlips()
    
    if STATE.inZone then
        RemoveZoneRestrictions(STATE.playerPed)
    end
    
    DebugLog('SafeZone arrêté proprement', 'success')
end)