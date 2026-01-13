-- ═══════════════════════════════════════════════════════════════════════════
-- HUD Health Armor Bank - Client
-- Version: 2.2.0
-- ═══════════════════════════════════════════════════════════════════════════
--
-- ⚠️ CE FICHIER N'APPELLE JAMAIS DIRECTEMENT UN INVENTAIRE
-- Toutes les données framework passent par bridge.lua
--
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- CACHE LOCALES (OPTIMISATION)
-- ═══════════════════════════════════════════════════════════════════════════

local PlayerPedId = PlayerPedId
local GetEntityHealth = GetEntityHealth
local GetPedMaxHealth = GetPedMaxHealth
local GetPedArmour = GetPedArmour
local DoesEntityExist = DoesEntityExist
local IsPauseMenuActive = IsPauseMenuActive
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local Wait = Wait

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIABLES D'ÉTAT
-- ═══════════════════════════════════════════════════════════════════════════

local hudVisible = true
local minimapInitialized = false

-- Cache des dernières valeurs (évite updates NUI inutiles)
local lastHealth = -1
local lastArmor = -1
local lastPlayerId = -1
local lastBank = -1
local lastDead = false
local lastVehicle = false
local lastPause = false

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTIONS DE DEBUG
-- ═══════════════════════════════════════════════════════════════════════════

local function Log(level, msg, ...)
    if not Config.Debug and level == 'debug' then return end
    
    local colors = {
        debug = '^2',
        info = '^5',
        warn = '^3',
        error = '^1'
    }
    
    local color = colors[level] or '^7'
    print(string.format('%s[HUD Client]^7 %s', color, string.format(msg, ...)))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MINIMAP
-- ═══════════════════════════════════════════════════════════════════════════

local function InitMinimap()
    if minimapInitialized then return end
    
    CreateThread(function()
        local minimap = RequestScaleformMovie("minimap")
        
        local timeout = 0
        while not HasScaleformMovieLoaded(minimap) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end
        
        if not HasScaleformMovieLoaded(minimap) then
            Log('warn', 'Minimap scaleform failed to load')
            return
        end
        
        DisplayRadar(true)
        
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        
        minimapInitialized = true
        Log('debug', 'Minimap initialized')
        
        -- Maintenance loop
        while minimapInitialized do
            Wait(5000)
            BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MASQUAGE HUD NATIF
-- ═══════════════════════════════════════════════════════════════════════════

local componentsToHide = {}

local function SetupHiddenComponents()
    componentsToHide = {}
    
    -- Composants de la config
    if Config.HideComponents then
        for _, id in ipairs(Config.HideComponents) do
            componentsToHide[#componentsToHide + 1] = id
        end
    end
    
    -- Si on masque les barres natives, ajouter tous les composants
    if Config.HideNativeBars then
        for i = 1, 22 do
            local found = false
            for _, id in ipairs(componentsToHide) do
                if id == i then found = true break end
            end
            if not found then
                componentsToHide[#componentsToHide + 1] = i
            end
        end
    end
    
    Log('debug', 'Components to hide: %d', #componentsToHide)
end

CreateThread(function()
    if not Config.Enabled then return end
    
    SetupHiddenComponents()
    
    if #componentsToHide == 0 then return end
    
    while Config.Enabled do
        Wait(0)
        DisplayRadar(true)
        
        for i = 1, #componentsToHide do
            HideHudComponentThisFrame(componentsToHide[i])
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- RÉCUPÉRATION DES DONNÉES
-- ═══════════════════════════════════════════════════════════════════════════

local function GetHealthArmor()
    local ped = PlayerPedId()
    
    if not DoesEntityExist(ped) then
        return 0, 0
    end
    
    local health = GetEntityHealth(ped)
    local maxHealth = GetPedMaxHealth(ped)
    
    if maxHealth <= 100 then maxHealth = 200 end
    
    -- Calcul correct : santé GTA va de 100 (mort) à maxHealth
    local healthPct = math.floor(math.max(0, math.min(100, ((health - 100) / (maxHealth - 100)) * 100)))
    local armorPct = math.floor(math.max(0, math.min(100, GetPedArmour(ped) or 0)))
    
    return healthPct, armorPct
end

local function IsDead()
    return GetEntityHealth(PlayerPedId()) <= 100
end

local function IsInVehicle()
    if not Config.Advanced.HideInVehicle then return false end
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FORMATAGE ARGENT
-- ═══════════════════════════════════════════════════════════════════════════

local function FormatMoney(amount)
    amount = tonumber(amount) or 0
    
    if Config.Bank.Format == 'compact' then
        if amount >= 1000000 then
            return string.format('%.1fM%s', amount / 1000000, Config.Bank.Symbol)
        elseif amount >= 1000 then
            return string.format('%.1fK%s', amount / 1000, Config.Bank.Symbol)
        else
            return string.format('%d%s', amount, Config.Bank.Symbol)
        end
    else
        local formatted = tostring(math.floor(amount)):reverse():gsub('(%d%d%d)', '%1' .. Config.Bank.Separator):reverse()
        if formatted:sub(1, 1) == Config.Bank.Separator then
            formatted = formatted:sub(2)
        end
        return formatted .. Config.Bank.Symbol
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMUNICATION NUI
-- ═══════════════════════════════════════════════════════════════════════════

local nuiScheduled = false
local pendingData = nil

local function ScheduleNuiUpdate(health, armor, playerId, bank)
    pendingData = {
        health = health,
        armor = armor,
        id = playerId,
        bank = Config.Bank.Enabled and FormatMoney(bank) or nil
    }
    
    if not nuiScheduled then
        nuiScheduled = true
        
        CreateThread(function()
            Wait(50) -- Grouper les updates
            
            if pendingData then
                SendNUIMessage({
                    action = "update",
                    health = pendingData.health,
                    armor = pendingData.armor,
                    id = pendingData.id,
                    bank = pendingData.bank
                })
                pendingData = nil
            end
            
            nuiScheduled = false
        end)
    end
end

local function ToggleHud(show)
    hudVisible = show
    SendNUIMessage({
        action = "toggle",
        show = show
    })
    Log('debug', 'HUD toggled: %s', tostring(show))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BOUCLE PRINCIPALE
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    if not Config.Enabled then return end
    
    Wait(1000)
    InitMinimap()
    
    -- Attendre que le bridge soit prêt
    local waitCount = 0
    while not Bridge.IsReady() and waitCount < 30 do
        Wait(500)
        waitCount = waitCount + 1
    end
    
    if not Bridge.IsReady() then
        Log('warn', 'Bridge not ready, HUD running without bank')
    end
    
    Log('info', 'Main loop started (interval: %dms)', Config.UpdateInterval)
    
    while Config.Enabled do
        local dead = IsDead()
        local inVehicle = IsInVehicle()
        local pauseMenu = IsPauseMenuActive()
        
        -- Conditions de masquage
        local shouldHide = false
        
        if Config.Advanced.HideInPauseMenu and pauseMenu then
            shouldHide = true
        end
        
        if Config.Advanced.HideWhenDead and dead then
            shouldHide = true
        end
        
        if Config.Advanced.HideInVehicle and inVehicle then
            shouldHide = true
        end
        
        -- Toggle HUD si état changé
        if shouldHide and hudVisible then
            ToggleHud(false)
        elseif not shouldHide and not hudVisible then
            ToggleHud(true)
        end
        
        -- Récupérer données
        local health, armor = GetHealthArmor()
        local playerId = GetPlayerServerId(PlayerId()) or 0
        
        -- ⚠️ RÉCUPÉRATION BANQUE VIA BRIDGE (PAS D'INVENTAIRE DIRECT)
        local bank = Bridge.GetBankMoney()
        
        -- Vérifier si changement
        local hasChanged = (
            health ~= lastHealth or
            armor ~= lastArmor or
            playerId ~= lastPlayerId or
            bank ~= lastBank or
            dead ~= lastDead or
            inVehicle ~= lastVehicle or
            pauseMenu ~= lastPause
        )
        
        if hasChanged and hudVisible then
            ScheduleNuiUpdate(health, armor, playerId, bank)
            
            lastHealth = health
            lastArmor = armor
            lastPlayerId = playerId
            lastBank = bank
            lastDead = dead
            lastVehicle = inVehicle
            lastPause = pauseMenu
        end
        
        Wait(Config.UpdateInterval)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler('onClientResourceStart', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    if not Config.Enabled then return end
    
    Wait(500)
    InitMinimap()
    
    Wait(500)
    
    local health, armor = GetHealthArmor()
    local playerId = GetPlayerServerId(PlayerId()) or 0
    local bank = Bridge.GetBankMoney()
    
    ScheduleNuiUpdate(health, armor, playerId, bank)
    Log('info', 'Resource started')
end)

-- Event de mise à jour banque (déclenché par bridge.lua)
RegisterNetEvent('hud:bankUpdated', function(amount)
    if Config.Bank.Enabled and type(amount) == 'number' then
        lastBank = -1 -- Force refresh
        Log('debug', 'Bank updated: %d', amount)
    end
end)

RegisterNetEvent('hud:toggle', function(show)
    if type(show) == 'boolean' then
        ToggleHud(show)
    end
end)

RegisterNetEvent('hud:updateBank', function(amount)
    if Config.Bank.Enabled and type(amount) == 'number' then
        lastBank = amount
        
        local health, armor = GetHealthArmor()
        local playerId = GetPlayerServerId(PlayerId()) or 0
        
        ScheduleNuiUpdate(health, armor, playerId, amount)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports('toggleHud', function(show)
    if type(show) == 'boolean' then
        ToggleHud(show)
        return true
    end
    return false
end)

exports('updateBank', function(amount)
    if type(amount) == 'number' then
        TriggerEvent('hud:updateBank', amount)
        return true
    end
    return false
end)

exports('forceRefresh', function()
    lastHealth = -1
    lastArmor = -1
    lastBank = -1
    lastPlayerId = -1
    lastDead = false
    lastVehicle = false
    lastPause = false
    Log('debug', 'Force refresh')
    return true
end)

exports('isHudVisible', function()
    return hudVisible
end)

exports('resetMinimap', function()
    minimapInitialized = false
    InitMinimap()
    return true
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN
-- ═══════════════════════════════════════════════════════════════════════════

Log('info', 'Client loaded (v2.2.0)')
