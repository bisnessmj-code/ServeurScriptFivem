-- ═══════════════════════════════════════════════════════════════════════════
-- HUD Health Armor Bank - Bridge (Isolation Framework)
-- Version: 2.2.0
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- CE FICHIER ISOLE TOUTE LA LOGIQUE FRAMEWORK
-- ⚠️ AUCUNE RÉFÉRENCE À qs-inventory, ox_inventory, etc.
-- L'argent est récupéré via ESX / QBCore UNIQUEMENT
--
-- ═══════════════════════════════════════════════════════════════════════════

Bridge = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIABLES PRIVÉES
-- ═══════════════════════════════════════════════════════════════════════════

local ESX = nil
local QBCore = nil
local frameworkReady = false
local playerLoaded = false

-- ═══════════════════════════════════════════════════════════════════════════
-- FONCTIONS DE DEBUG
-- ═══════════════════════════════════════════════════════════════════════════

local function Log(level, msg, ...)
    if not Config.Debug and level == 'debug' then return end
    
    local colors = {
        debug = '^2',   -- Vert
        info = '^5',    -- Cyan
        warn = '^3',    -- Jaune
        error = '^1'    -- Rouge
    }
    
    local color = colors[level] or '^7'
    local prefix = string.format('%s[HUD Bridge]^7', color)
    print(string.format('%s %s', prefix, string.format(msg, ...)))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALISATION DU FRAMEWORK
-- ═══════════════════════════════════════════════════════════════════════════

local function InitESX()
    -- Méthode 1: Export (nouvelle méthode ESX)
    local success = pcall(function()
        ESX = exports['es_extended']:getSharedObject()
    end)
    
    if success and ESX then
        Log('info', 'ESX initialisé via exports')
        return true
    end
    
    -- Méthode 2: Event (ancienne méthode ESX)
    local eventSuccess = false
    TriggerEvent('esx:getSharedObject', function(obj)
        if obj then
            ESX = obj
            eventSuccess = true
        end
    end)
    
    Wait(100)
    
    if eventSuccess and ESX then
        Log('info', 'ESX initialisé via event')
        return true
    end
    
    Log('warn', 'ESX non trouvé')
    return false
end

local function InitQBCore()
    local success = pcall(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end)
    
    if success and QBCore then
        Log('info', 'QBCore initialisé')
        return true
    end
    
    Log('warn', 'QBCore non trouvé')
    return false
end

function Bridge.Init()
    Log('debug', 'Initialisation du bridge (Framework: %s)', Config.Framework)
    
    local maxRetries = 10
    local retryDelay = 500
    
    for attempt = 1, maxRetries do
        local success = false
        
        if Config.Framework == 'ESX' then
            success = InitESX()
        elseif Config.Framework == 'QBCore' then
            success = InitQBCore()
        else
            Log('error', 'Framework inconnu: %s', Config.Framework)
            break
        end
        
        if success then
            frameworkReady = true
            Log('info', 'Framework prêt après %d tentative(s)', attempt)
            return true
        end
        
        if attempt < maxRetries then
            Log('debug', 'Retry %d/%d dans %dms...', attempt, maxRetries, retryDelay)
            Wait(retryDelay)
        end
    end
    
    Log('error', 'Échec initialisation framework après %d tentatives', maxRetries)
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VÉRIFICATION DE L'ÉTAT
-- ═══════════════════════════════════════════════════════════════════════════

function Bridge.IsReady()
    return frameworkReady
end

function Bridge.IsPlayerLoaded()
    return playerLoaded
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RÉCUPÉRATION DES DONNÉES JOUEUR
-- ═══════════════════════════════════════════════════════════════════════════

--- Récupère l'argent en banque du joueur
--- @return number Montant en banque (0 si erreur)
function Bridge.GetBankMoney()
    if not frameworkReady then
        Log('debug', 'GetBankMoney: Framework non prêt')
        return 0
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- ESX
    -- ═══════════════════════════════════════════════════════════════════════
    if Config.Framework == 'ESX' and ESX then
        local success, result = pcall(function()
            local playerData = ESX.GetPlayerData()
            
            if not playerData then
                Log('debug', 'ESX: PlayerData nil')
                return 0
            end
            
            if not playerData.accounts then
                Log('debug', 'ESX: Accounts nil')
                return 0
            end
            
            for _, account in ipairs(playerData.accounts) do
                if account.name == 'bank' then
                    return account.money or 0
                end
            end
            
            return 0
        end)
        
        if success then
            return result or 0
        else
            Log('debug', 'ESX GetBankMoney error: %s', tostring(result))
            return 0
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- QBCore
    -- ═══════════════════════════════════════════════════════════════════════
    if Config.Framework == 'QBCore' and QBCore then
        local success, result = pcall(function()
            local playerData = QBCore.Functions.GetPlayerData()
            
            if not playerData then
                Log('debug', 'QBCore: PlayerData nil')
                return 0
            end
            
            if not playerData.money then
                Log('debug', 'QBCore: Money nil')
                return 0
            end
            
            return playerData.money.bank or 0
        end)
        
        if success then
            return result or 0
        else
            Log('debug', 'QBCore GetBankMoney error: %s', tostring(result))
            return 0
        end
    end
    
    return 0
end

--- Récupère l'argent liquide du joueur
--- @return number Montant cash (0 si erreur)
function Bridge.GetCashMoney()
    if not frameworkReady then return 0 end
    
    if Config.Framework == 'ESX' and ESX then
        local success, result = pcall(function()
            local playerData = ESX.GetPlayerData()
            if playerData and playerData.accounts then
                for _, account in ipairs(playerData.accounts) do
                    if account.name == 'money' then
                        return account.money or 0
                    end
                end
            end
            return 0
        end)
        return success and result or 0
    end
    
    if Config.Framework == 'QBCore' and QBCore then
        local success, result = pcall(function()
            local playerData = QBCore.Functions.GetPlayerData()
            if playerData and playerData.money then
                return playerData.money.cash or 0
            end
            return 0
        end)
        return success and result or 0
    end
    
    return 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS FRAMEWORK
-- ═══════════════════════════════════════════════════════════════════════════

-- ESX Events
if Config.Framework == 'ESX' then
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        Log('debug', 'ESX: playerLoaded event')
        playerLoaded = true
        
        -- Re-init si nécessaire
        if not frameworkReady then
            CreateThread(function()
                Wait(500)
                Bridge.Init()
            end)
        end
    end)
    
    RegisterNetEvent('esx:onPlayerLogout', function()
        Log('debug', 'ESX: onPlayerLogout event')
        playerLoaded = false
    end)
    
    -- Event de mise à jour des comptes
    RegisterNetEvent('esx:setAccountMoney', function(account)
        if account and account.name == 'bank' then
            Log('debug', 'ESX: Bank updated to %d', account.money or 0)
            TriggerEvent('hud:bankUpdated', account.money or 0)
        end
    end)
end

-- QBCore Events
if Config.Framework == 'QBCore' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Log('debug', 'QBCore: OnPlayerLoaded event')
        playerLoaded = true
        
        if not frameworkReady then
            CreateThread(function()
                Wait(500)
                Bridge.Init()
            end)
        end
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        Log('debug', 'QBCore: OnPlayerUnload event')
        playerLoaded = false
    end)
    
    -- Event de mise à jour des données joueur
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        if val and val.money then
            Log('debug', 'QBCore: PlayerData updated, bank=%d', val.money.bank or 0)
            TriggerEvent('hud:bankUpdated', val.money.bank or 0)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALISATION AUTOMATIQUE
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000) -- Attendre que les autres ressources démarrent
    Bridge.Init()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DU BRIDGE
-- ═══════════════════════════════════════════════════════════════════════════

Log('debug', 'Bridge chargé (Framework configuré: %s)', Config.Framework)
