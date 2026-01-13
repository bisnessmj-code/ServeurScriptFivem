-- Variables
local isDead = false
local canRespawn = false
local isHealing = false
local healCooldown = 0

-- Système de compatibilité
local isSystemEnabled = true
local isInGame = false
local currentBucket = 0
local isInBucketZero = true
local bucketInitialized = false

-- ███████╗ ██████╗ ███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
-- ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
-- █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
-- ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
-- ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
-- ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

function DebugPrint(msg)
    if Config.Debug then
        print("^5[GF-RESPAWN]^7 " .. msg)
    end
end

function ShowNotification(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

-- ██████╗ ██████╗ ███╗   ███╗██████╗  █████╗ ████████╗██╗██████╗ ██╗██╗     ██╗████████╗██╗   ██╗
-- ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
-- ██║     ██║   ██║██╔████╔██║██████╔╝███████║   ██║   ██║██████╔╝██║██║     ██║   ██║    ╚████╔╝ 
-- ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║   ██║   ██║██╔══██╗██║██║     ██║   ██║     ╚██╔╝  
-- ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║   ██║   ██║██████╔╝██║███████╗██║   ██║      ██║   
--  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝╚═════╝ ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   

function IsSystemActive()
    if not Config.EnableCompatibility then
        return true
    end
    
    if isInGame then
        return false
    end
    
    if Config.DisableInBuckets and currentBucket ~= nil then
        local isAllowed = false
        for _, allowedBucket in ipairs(Config.AllowedBuckets) do
            if currentBucket == allowedBucket then
                isAllowed = true
                break
            end
        end
        
        if not isAllowed then
            return false
        end
    end
    
    return isSystemEnabled
end

function DisableRespawnSystem()
    isInGame = true
    
    if isDead then
        SendNUIMessage({ action = "hideDeath" })
        StopScreenEffect("DeathFailOut")
        TriggerScreenblurFadeOut(0)
        isDead = false
        canRespawn = false
    end
    
    if isHealing then
        CancelHeal()
    end
end

function EnableRespawnSystem()
    isInGame = false
end

function IsRespawnSystemEnabled()
    return IsSystemActive()
end

-- ███████╗██╗  ██╗██████╗  ██████╗ ██████╗ ████████╗███████╗
-- ██╔════╝╚██╗██╔╝██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝
-- █████╗   ╚███╔╝ ██████╔╝██║   ██║██████╔╝   ██║   ███████╗
-- ██╔══╝   ██╔██╗ ██╔═══╝ ██║   ██║██╔══██╗   ██║   ╚════██║
-- ███████╗██╔╝ ██╗██║     ╚██████╔╝██║  ██║   ██║   ███████║
-- ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝

exports('DisableRespawnSystem', DisableRespawnSystem)
exports('EnableRespawnSystem', EnableRespawnSystem)
exports('IsRespawnSystemEnabled', IsRespawnSystemEnabled)

RegisterNetEvent('gf_respawn:disable')
AddEventHandler('gf_respawn:disable', function()
    DisableRespawnSystem()
end)

RegisterNetEvent('gf_respawn:enable')
AddEventHandler('gf_respawn:enable', function()
    EnableRespawnSystem()
end)

RegisterNetEvent('gf_respawn:updateBucket')
AddEventHandler('gf_respawn:updateBucket', function(bucket)
    currentBucket = bucket
    bucketInitialized = true
    
    if bucket == 0 then
        isInBucketZero = true
        SendNUIMessage({ action = "showLobbyPrompt" })
    else
        isInBucketZero = false
        SendNUIMessage({ action = "hideLobbyPrompt" })
    end
    
end)

-- ███╗   ███╗ ██████╗ ██████╗ ████████╗
-- ████╗ ████║██╔═══██╗██╔══██╗╚══██╔══╝
-- ██╔████╔██║██║   ██║██████╔╝   ██║   
-- ██║╚██╔╝██║██║   ██║██╔══██╗   ██║   
-- ██║ ╚═╝ ██║╚██████╔╝██║  ██║   ██║   
-- ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

function OnPlayerDeath()
    if not IsSystemActive() then
        return
    end
    
    if isDead then 
        return 
    end
    
    isDead = true
    canRespawn = false
    
    local playerPed = PlayerPedId()

    StartScreenEffect("DeathFailOut", 0, true)
    TriggerScreenblurFadeIn(1000)
    
    SetPedToRagdoll(playerPed, 5000, 5000, 0, 0, 0, 0)

    SendNUIMessage({
        action = "showDeath",
        timer = Config.RespawnTimer,
        colors = Config.Colors
    })
    
    SetTimeout(Config.RespawnTimer * 1000, function()
        
        if not IsSystemActive() then
            if isDead then
                SendNUIMessage({ action = "hideDeath" })
                StopScreenEffect("DeathFailOut")
                TriggerScreenblurFadeOut(0)
                isDead = false
                canRespawn = false
            end
            return
        end
        
        if isDead then
            canRespawn = true
            SendNUIMessage({ action = "enableRespawn" })
        end
    end)
    
    TriggerServerEvent('gf:playerDied')
end

-- ██████╗ ███████╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗
-- ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║
-- ██████╔╝█████╗  ███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║
-- ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║
-- ██║  ██║███████╗███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║
-- ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝

function RespawnAlive()
    if not canRespawn then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    DoRespawn(coords.x, coords.y, coords.z, heading)
    TriggerServerEvent('gf:respawnAlive')
end

function RespawnLobby()
    if not canRespawn then return end
    
    local spawn = Config.SpawnPosition
    DoRespawn(spawn.x, spawn.y, spawn.z, spawn.heading)
    TriggerServerEvent('gf:respawnLobby')
end

function DoRespawn(x, y, z, heading)
    local playerPed = PlayerPedId()
    
    DoScreenFadeOut(500)
    Wait(500)
    
    isDead = false
    canRespawn = false
    
    StopScreenEffect("DeathFailOut")
    TriggerScreenblurFadeOut(500)
    
    SetEntityCoordsNoOffset(playerPed, x, y, z, false, false, false)
    SetEntityHeading(playerPed, heading)
    
    NetworkResurrectLocalPlayer(x, y, z, heading, true, false)
    SetPlayerInvincible(playerPed, false)
    ClearPedTasksImmediately(playerPed)
    
    SetEntityHealth(playerPed, Config.RespawnHealth)
    
    SendNUIMessage({ action = "hideDeath" })
    
    Wait(100)
    DoScreenFadeIn(500)
end

-- ██╗  ██╗███████╗ █████╗ ██╗     
-- ██║  ██║██╔════╝██╔══██╗██║     
-- ███████║█████╗  ███████║██║     
-- ██╔══██║██╔══╝  ██╔══██║██║     
-- ██║  ██║███████╗██║  ██║███████╗
-- ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝

function StartHeal()
    if isDead or isHealing then return end
    
    local playerPed = PlayerPedId()
    
    if healCooldown > 0 then
        ShowNotification("~r~Cooldown : " .. healCooldown .. "s")
        return
    end
    
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, true)
    
    isHealing = true
    local startCoords = GetEntityCoords(playerPed)
    
    RequestAnimDict("amb@medic@standing@kneel@base")
    while not HasAnimDictLoaded("amb@medic@standing@kneel@base") do
        Wait(10)
    end
    
    RequestAnimDict("amb@medic@standing@kneel@idle_a")
    while not HasAnimDictLoaded("amb@medic@standing@kneel@idle_a") do
        Wait(10)
    end
    
    FreezeEntityPosition(playerPed, false)
    
    TaskPlayAnim(playerPed, "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(500)
    TaskPlayAnim(playerPed, "amb@medic@standing@kneel@idle_a", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    SendNUIMessage({
        action = "showHeal",
        duration = Config.HealDuration * 1000,
        colors = Config.Colors
    })
    
    PlaySoundFrontend(-1, "TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    local startTime = GetGameTimer()
    local success = true
    
    while isHealing do
        Wait(100)
        
        if not IsSystemActive() then
            success = false
            CancelHeal()
            break
        end
        
        local currentCoords = GetEntityCoords(playerPed)
        local distance = #(startCoords - currentCoords)
        
        if distance > 1.0 then
            success = false
            CancelHeal("~r~Vous avez bougé !")
            break
        end
        
        if IsEntityDead(playerPed) then
            success = false
            CancelHeal()
            break
        end
        
        local elapsed = GetGameTimer() - startTime
        if elapsed >= Config.HealDuration * 1000 then
            if success then
                CompleteHeal()
            end
            break
        end
    end
end

function CompleteHeal()
    if not isHealing then return end
    
    isHealing = false
    local playerPed = PlayerPedId()
    
    local currentHealth = GetEntityHealth(playerPed)
    local newHealth = math.min(currentHealth + Config.HealAmount, GetEntityMaxHealth(playerPed))
    SetEntityHealth(playerPed, newHealth)
    
    ClearPedTasks(playerPed)
    SendNUIMessage({ action = "hideHeal" })
    
    local healed = newHealth - currentHealth
    if healed > 0 then
        ShowNotification("~g~+" .. healed .. " HP récupérés !")
    else
        ShowNotification("~y~Vous êtes déjà en pleine forme !")
    end
    
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
    
    healCooldown = Config.HealCooldown
    TriggerServerEvent('gf:playerHealed')
end

function CancelHeal(reason)
    if not isHealing then return end
    
    isHealing = false
    local playerPed = PlayerPedId()
    
    ClearPedTasks(playerPed)
    SendNUIMessage({ action = "hideHeal" })
    
    if reason then
        ShowNotification(reason)
    end
end

-- ████████╗██╗  ██╗██████╗ ███████╗ █████╗ ██████╗ ███████╗
-- ╚══██╔══╝██║  ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝
--    ██║   ███████║██████╔╝█████╗  ███████║██║  ██║███████╗
--    ██║   ██╔══██║██╔══██╗██╔══╝  ██╔══██║██║  ██║╚════██║
--    ██║   ██║  ██║██║  ██║███████╗██║  ██║██████╔╝███████║
--    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝

-- Thread de détection de mort
CreateThread(function()
    while true do
        Wait(500)  -- Check toutes les 500ms pour la mort
        
        if not IsSystemActive() then
            goto continue
        end
        
        local playerPed = PlayerPedId()
        
        if IsEntityDead(playerPed) and not isDead then
            OnPlayerDeath()
        end
        
        ::continue::
    end
end)

-- Thread de gestion des contrôles pendant la mort
CreateThread(function()
    while true do
        Wait(0)
        
        if isDead and IsSystemActive() then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            
            if canRespawn then
                if IsDisabledControlJustPressed(0, 38) then
                    RespawnAlive()
                end
                
                if IsDisabledControlJustPressed(0, 23) then
                    RespawnLobby()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Thread de la touche heal
CreateThread(function()
    while true do
        Wait(0)
        
        if not isDead and not isHealing and IsSystemActive() then
            for _, keyCode in ipairs(Config.HealKeys) do
                if IsControlJustPressed(0, keyCode) then
                    StartHeal()
                    break
                end
            end
        end
        
        if isDead or isHealing then
            Wait(500)
        elseif not IsSystemActive() then
            Wait(1000)
        end
    end
end)

-- ⚡ THREAD TOUCHE B - ULTRA RÉACTIF (Wait 0ms en bucket 0) ⚡
CreateThread(function()
    
    while true do
        -- CLEF DE LA RÉACTIVITÉ : Wait adaptatif
        if currentBucket == 0 and bucketInitialized and IsSystemActive() and not isDead and not isHealing then
            -- En bucket 0 et prêt : Wait 0ms pour réactivité MAXIMALE
            Wait(0)
            
            -- B = Control 29
            if IsControlJustPressed(0, 29) then
                TeleportToLobby()
            end
        else
            -- Hors bucket 0 ou pas prêt : Wait 1000ms pour économiser CPU
            Wait(1000)
        end
    end
end)

-- Thread de cooldown
CreateThread(function()
    while true do
        Wait(1000)
        
        if healCooldown > 0 then
            healCooldown = healCooldown - 1
        end
    end
end)

-- Thread de désactivation de la régénération native
CreateThread(function()
    while true do
        Wait(0)
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    end
end)

-- Thread de surveillance du bucket
if Config.EnableCompatibility and Config.DisableInBuckets then
    CreateThread(function()
        Wait(3000)
        
        while true do
            TriggerServerEvent('gf_respawn:requestBucket')
            Wait(5000)
        end
    end)
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isDead then
            local playerPed = PlayerPedId()
            NetworkResurrectLocalPlayer(GetEntityCoords(playerPed), GetEntityHeading(playerPed), true, false)
            SetEntityHealth(playerPed, 200)
        end
        
        SendNUIMessage({ action = "hideDeath" })
        SendNUIMessage({ action = "hideHeal" })
        SendNUIMessage({ action = "hideLobbyPrompt" })
        
        StopScreenEffect("DeathFailOut")
        TriggerScreenblurFadeOut(0)
    end
end)

-- ██╗      ██████╗ ██████╗ ██████╗ ██╗   ██╗
-- ██║     ██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
-- ██║     ██║   ██║██████╔╝██████╔╝ ╚████╔╝ 
-- ██║     ██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  
-- ███████╗╚██████╔╝██████╔╝██████╔╝   ██║   
-- ╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   

function TeleportToLobby()
    
    if currentBucket ~= 0 then
        ShowNotification("~r~Cette fonction n'est disponible qu'en mode libre")
        return
    end
    
    if not IsSystemActive() then
        ShowNotification("~r~Fonction indisponible")
        return
    end
    
    if isDead then
        ShowNotification("~r~Impossible de se téléporter pendant la mort")
        return
    end
    
    if isHealing then
        ShowNotification("~r~Impossible de se téléporter pendant un heal")
        CancelHeal("~r~Téléportation annulée")
        return
    end
    

    local playerPed = PlayerPedId()
    local spawn = Config.SpawnPosition
    
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoordsNoOffset(playerPed, spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(playerPed, spawn.heading)
    
    ClearPedTasksImmediately(playerPed)
    
    Wait(200)
    DoScreenFadeIn(500)
    
    ShowNotification("~g~Téléportation au lobby")
    
    TriggerServerEvent('gf:lobbyTeleport')
end

RegisterCommand('lobby', function()
    TeleportToLobby()
end, false)

RegisterCommand('checkbucket', function()
    ShowNotification("~b~Bucket: " .. tostring(currentBucket) .. " | Init: " .. tostring(bucketInitialized))
end, false)

-- Affichage initial du prompt
CreateThread(function()
    Wait(2000)
    
    TriggerServerEvent('gf_respawn:requestBucket')
    
    Wait(500)
    if currentBucket == 0 then
        SendNUIMessage({ action = "showLobbyPrompt" })
    end
end)