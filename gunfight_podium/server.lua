-- ================================================================================================
-- PVP PODIUM - SERVER v6.1.0 FIXED - SKIN PARSING ROBUSTE
-- ================================================================================================
-- CORRECTIONS :
-- 1. ParseSkin() amélioré : gère tous les formats JSON (ancien/nouveau ESX)
-- 2. Fallback intelligent : model par défaut si skin invalide
-- 3. Logs détaillés : debug complet du parsing
-- 4. Support multi-framework : détecte automatiquement la structure
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================================================================
-- 💾 CACHE SERVEUR
-- ================================================================================================
local ServerCache = {
    gunfight = {},
    catmouse = {}
}
local lastUpdate = 0

-- ================================================================================================
-- 🛠️ LOG DEBUG
-- ================================================================================================
local function Log(message, logType)
    if not Config.Debug then return end
    
    local types = {
        error = "^1[ERROR]^0",
        success = "^2[OK]^0",
        db = "^5[DB]^0",
        cache = "^3[CACHE]^0",
        perf = "^6[PERF]^0",
        skin = "^4[SKIN]^0"
    }
    
    print((types[logType] or "^6[Podium]^0") .. " " .. message)
end

-- ================================================================================================
-- 🔧 PARSER SKIN ROBUSTE (Support multi-format)
-- ================================================================================================
local function ParseSkin(skinJson, identifier)
    if not skinJson or skinJson == "" or skinJson == "null" or skinJson == "{}" then 
        Log(string.format("Skin vide ou null pour %s", identifier or "?"), "skin")
        return nil 
    end
    
    -- Tenter de décoder le JSON
    local success, data = pcall(json.decode, skinJson)
    
    if not success then
        Log(string.format("Erreur parsing JSON pour %s: %s", identifier or "?", tostring(data)), "error")
        return nil
    end
    
    if not data then
        Log(string.format("Data nil après parsing pour %s", identifier or "?"), "error")
        return nil
    end
    
    -- VALIDATION : Vérifier que la structure est exploitable
    local isValid = false
    
    -- Format 1 : Structure avec model direct
    if data.model then
        isValid = true
        Log(string.format("✓ Skin trouvé (model: %s) pour %s", tostring(data.model), identifier or "?"), "skin")
    end
    
    -- Format 2 : Structure imbriquée (nouveau ESX)
    if data.skin and type(data.skin) == "table" and data.skin.model then
        data = data.skin -- Extraire la sous-structure
        isValid = true
        Log(string.format("✓ Skin trouvé (structure imbriquée, model: %s) pour %s", tostring(data.model), identifier or "?"), "skin")
    end
    
    -- Format 3 : Double parsing nécessaire (cas rare)
    if type(data) == "string" then
        local success2, data2 = pcall(json.decode, data)
        if success2 and data2 and data2.model then
            data = data2
            isValid = true
            Log(string.format("✓ Skin trouvé (double parsing, model: %s) pour %s", tostring(data.model), identifier or "?"), "skin")
        end
    end
    
    if not isValid then
        Log(string.format("✗ Structure skin invalide pour %s (pas de model)", identifier or "?"), "error")
        return nil
    end
    
    -- NORMALISATION : S'assurer que les champs critiques existent
    if not data.components then data.components = {} end
    if not data.props then data.props = {} end
    
    return data
end

-- ================================================================================================
-- 👤 NOM JOUEUR CONNECTÉ
-- ================================================================================================
local function GetPlayerName(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        if xPlayer and xPlayer.identifier == identifier then
            return xPlayer.getName()
        end
    end
    return nil
end

-- ================================================================================================
-- 🎭 OBTENIR MODEL PAR DÉFAUT SELON LE SEXE (Fallback)
-- ================================================================================================
local function GetDefaultModel(skinData)
    -- Si on a un skin valide avec model, on le retourne
    if skinData and skinData.model then
        return skinData.model
    end
    
    -- Sinon, fallback sur mp_m_freemode_01 (male par défaut)
    return "mp_m_freemode_01"
end

-- ================================================================================================
-- ⚡ RÉCUPÉRER TOP 1 GUNFIGHT (Mode spécifique)
-- ================================================================================================
local function FetchGunfightTop1(mode, callback)
    local startTime = GetGameTimer()
    
    -- ÉTAPE 1 : Récupérer le top 1 (identifier + elo UNIQUEMENT)
    local queryTop1 = [[
        SELECT identifier, elo
        FROM ]] .. Config.Database.gunfightStats .. [[
        WHERE mode = ? AND elo > 0
        ORDER BY elo DESC
        LIMIT 1
    ]]
    
    MySQL.Async.fetchAll(queryTop1, { mode }, function(result)
        local step1Time = math.floor(GetGameTimer() - startTime)
        
        if not result or #result == 0 then
            Log(string.format("[Gunfight %s] Aucun joueur trouvé", mode), "error")
            callback(nil)
            return
        end
        
        local top1 = result[1]
        local identifier = top1.identifier
        local elo = top1.elo
        
        Log(string.format("[Gunfight %s] Étape 1 : Identifier trouvé en %dms", mode, step1Time), "perf")
        
        -- ÉTAPE 2 : Récupérer le skin + nom
        local querySkin = [[
            SELECT firstname, lastname, ]] .. Config.Database.skinColumn .. [[
            FROM ]] .. Config.Database.users .. [[
            WHERE identifier = ?
            LIMIT 1
        ]]
        
        MySQL.Async.fetchAll(querySkin, { identifier }, function(userData)
            local totalTime = math.floor(GetGameTimer() - startTime)
            
            -- Récupérer le nom (connecté ou DB)
            local playerName = GetPlayerName(identifier)
            
            if not playerName and userData and #userData > 0 then
                local row = userData[1]
                playerName = (row.firstname or "") .. " " .. (row.lastname or "")
                playerName = playerName:gsub("^%s+", ""):gsub("%s+$", "")
            end
            
            if not playerName or playerName == "" then
                playerName = "Joueur"
            end
            
            -- Parser le skin avec logs détaillés
            local skinData = nil
            if userData and #userData > 0 then
                local rawSkin = userData[1][Config.Database.skinColumn]
                Log(string.format("[Gunfight %s] Skin brut (length: %d)", mode, rawSkin and #rawSkin or 0), "db")
                skinData = ParseSkin(rawSkin, identifier)
            else
                Log(string.format("[Gunfight %s] ✗ Joueur non trouvé dans users: %s", mode, identifier), "error")
            end
            
            -- Déterminer le model (avec fallback)
            local model = GetDefaultModel(skinData)
            
            local data = {
                identifier = identifier,
                name = playerName,
                elo = elo,
                skin = skinData,
                model = model, -- Ajout explicite du model
                mode = mode
            }
            
            Log(string.format("[Gunfight %s] TOP 1: %s (ELO: %d) - Model: %s - Total: %dms", 
                mode, playerName, elo, model, totalTime), "success")
            callback(data)
        end)
    end)
end

-- ================================================================================================
-- ⚡ RÉCUPÉRER TOP 3 CAT & MOUSE
-- ================================================================================================
local function FetchCatMouseTop3(callback)
    local startTime = GetGameTimer()
    
    -- ÉTAPE 1 : Récupérer le Top 3 avec le nom depuis catmouse_elo
    local queryTop3 = [[
        SELECT 
            cm.identifier,
            cm.name as stored_name,
            cm.elo,
            cm.wins,
            cm.losses,
            cm.win_streak,
            cm.best_streak,
            cm.total_matches
        FROM ]] .. Config.Database.catmouseElo .. [[ cm
        WHERE cm.elo > 0
        ORDER BY cm.elo DESC
        LIMIT 3
    ]]
    
    MySQL.Async.fetchAll(queryTop3, {}, function(results)
        local step1Time = math.floor(GetGameTimer() - startTime)
        
        if not results or #results == 0 then
            Log("[Cat & Mouse] Aucun joueur trouvé", "error")
            callback({})
            return
        end
        
        Log(string.format("[Cat & Mouse] Étape 1 : %d joueurs trouvés en %dms", #results, step1Time), "perf")
        
        local finalData = {}
        local processed = 0
        local totalPlayers = #results
        
        -- ÉTAPE 2 : Pour chaque joueur du Top 3, récupérer son skin
        for rank, player in ipairs(results) do
            local identifier = player.identifier
            local storedName = player.stored_name or ("Joueur #" .. rank)
            
            Log(string.format("[Cat & Mouse] Rank %d - Identifier: %s | Stored Name: %s", rank, identifier, storedName), "db")
            
            -- Essayer de récupérer le skin depuis users
            -- IMPORTANT : On cherche par identifier OU par license si l'identifier commence par "license:"
            local querySkin = [[
                SELECT firstname, lastname, ]] .. Config.Database.skinColumn .. [[
                FROM ]] .. Config.Database.users .. [[
                WHERE identifier = ? OR identifier LIKE CONCAT('char%:', SUBSTRING_INDEX(?, ':', -1))
                LIMIT 1
            ]]
            
            MySQL.Async.fetchAll(querySkin, { identifier, identifier }, function(userData)
                processed = processed + 1
                
                local playerName = GetPlayerName(identifier) -- Si connecté
                local skinData = nil
                
                -- Si on trouve le joueur dans la table users
                if userData and #userData > 0 then
                    local row = userData[1]
                    
                    -- Utiliser firstname/lastname si pas connecté
                    if not playerName then
                        playerName = (row.firstname or "") .. " " .. (row.lastname or "")
                        playerName = playerName:gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    
                    -- Parser le skin
                    local rawSkin = row[Config.Database.skinColumn]
                    Log(string.format("[Cat & Mouse] Rank %d - Skin brut (length: %d)", rank, rawSkin and #rawSkin or 0), "db")
                    skinData = ParseSkin(rawSkin, identifier)
                else
                    Log(string.format("[Cat & Mouse] Rank %d - ✗ Joueur non trouvé dans users: %s", rank, identifier), "error")
                end
                
                -- Fallback sur le nom stocké si aucun nom trouvé
                if not playerName or playerName == "" then
                    playerName = storedName
                end
                
                -- Déterminer le model
                local model = GetDefaultModel(skinData)
                
                local data = {
                    identifier = identifier,
                    name = playerName,
                    elo = player.elo,
                    wins = player.wins,
                    losses = player.losses,
                    winStreak = player.win_streak,
                    bestStreak = player.best_streak,
                    totalMatches = player.total_matches,
                    skin = skinData,
                    model = model, -- Ajout explicite du model
                    rank = rank
                }
                
                finalData[rank] = data
                
                Log(string.format("[Cat & Mouse] TOP %d: %s (ELO: %d) - Model: %s", 
                    rank, playerName, player.elo, model), "success")
                
                -- Callback quand tous les joueurs sont traités
                if processed == totalPlayers then
                    local totalTime = math.floor(GetGameTimer() - startTime)
                    Log(string.format("[Cat & Mouse] Top 3 complet en %dms", totalTime), "perf")
                    callback(finalData)
                end
            end)
        end
    end)
end

-- ================================================================================================
-- 🔄 MISE À JOUR CACHE COMPLET
-- ================================================================================================
local function UpdateAllCaches()
    local startTime = GetGameTimer()
    Log("Mise à jour du cache...", "cache")
    
    local tempCache = {
        gunfight = {},
        catmouse = {}
    }
    
    local gunfightModes = Config.GunfightModes or {}
    local expectedCallbacks = #gunfightModes + 1
    local completedCallbacks = 0
    
    local function CheckCompletion()
        completedCallbacks = completedCallbacks + 1
        
        if completedCallbacks == expectedCallbacks then
            ServerCache = tempCache
            lastUpdate = GetGameTimer()
            
            local totalTime = math.floor(GetGameTimer() - startTime)
            Log(string.format("Cache mis à jour (Total: %dms)", totalTime), "success")
            
            TriggerClientEvent('pvppodium:update', -1, ServerCache)
        end
    end
    
    -- Récupérer les Gunfight Top 1
    for _, mode in ipairs(gunfightModes) do
        FetchGunfightTop1(mode, function(data)
            tempCache.gunfight[mode] = data
            CheckCompletion()
        end)
    end
    
    -- Récupérer le Cat & Mouse Top 3
    FetchCatMouseTop3(function(data)
        tempCache.catmouse = data
        CheckCompletion()
    end)
end

-- ================================================================================================
-- 📡 EVENT: CLIENT DEMANDE LES DONNÉES
-- ================================================================================================
RegisterNetEvent('pvppodium:requestUpdate')
AddEventHandler('pvppodium:requestUpdate', function()
    local src = source
    
    Log("Joueur " .. src .. " demande les données", "cache")
    
    -- Vérifier si le cache est vide
    local hasGunfightData = false
    local hasCatMouseData = false
    
    for _, mode in ipairs(Config.GunfightModes) do
        if ServerCache.gunfight[mode] then
            hasGunfightData = true
            break
        end
    end
    
    if #ServerCache.catmouse > 0 then
        hasCatMouseData = true
    end
    
    if not hasGunfightData or not hasCatMouseData then
        Log("Cache incomplet, refresh...", "cache")
        UpdateAllCaches()
        SetTimeout(2000, function()
            TriggerClientEvent('pvppodium:update', src, ServerCache)
        end)
    else
        TriggerClientEvent('pvppodium:update', src, ServerCache)
        Log("Données envoyées au joueur " .. src, "cache")
    end
end)

-- ================================================================================================
-- 🎮 COMMANDE: REFRESH (ADMIN/CONSOLE)
-- ================================================================================================
RegisterCommand('refreshpodium', function(source)
    if source == 0 then
        print("^3[Podium]^0 Refresh...")
        UpdateAllCaches()
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local group = xPlayer.getGroup()
    if group == 'admin' or group == 'superadmin' then
        UpdateAllCaches()
        TriggerClientEvent('esx:showNotification', source, "~g~Podium mis à jour !")
    end
end, false)

-- ================================================================================================
-- 🎮 COMMANDE: AFFICHER CLASSEMENT (CONSOLE)
-- ================================================================================================
RegisterCommand('showpodium', function(source)
    if source == 0 then
        print("^3========================================^0")
        print("^3[Podium PVP] Classements^0")
        print("^3========================================^0")
        
        print("^2=== GUNFIGHT ===^0")
        for _, mode in ipairs(Config.GunfightModes) do
            local p = ServerCache.gunfight[mode]
            if p then
                print(string.format("^2[%s]^0 %s - ELO: %d - Model: %s", mode, p.name, p.elo, p.model or "?"))
            else
                print(string.format("^1[%s]^0 Aucun joueur", mode))
            end
        end
        
        print("^5=== CAT & MOUSE ===^0")
        for rank, p in ipairs(ServerCache.catmouse) do
            if p then
                print(string.format("^5[TOP %d]^0 %s - ELO: %d (W:%d L:%d) - Model: %s", 
                    rank, p.name, p.elo, p.wins, p.losses, p.model or "?"))
            else
                print(string.format("^1[TOP %d]^0 Aucun joueur", rank))
            end
        end
        
        print("^3========================================^0")
    end
end, false)

-- ================================================================================================
-- 🎮 COMMANDE: DEBUG CAT & MOUSE (CONSOLE)
-- ================================================================================================
RegisterCommand('debugcatmouse', function(source)
    if source ~= 0 then return end
    
    print("^3========================================^0")
    print("^3[DEBUG CAT & MOUSE] Analyse SQL^0")
    print("^3========================================^0")
    
    -- Test 1 : Vérifier la table catmouse_elo
    MySQL.Async.fetchAll("SELECT identifier, name, elo FROM " .. Config.Database.catmouseElo .. " ORDER BY elo DESC LIMIT 3", {}, function(results)
        print("^5=== Table catmouse_elo (Top 3) ===^0")
        if results and #results > 0 then
            for i, row in ipairs(results) do
                print(string.format("  [%d] Identifier: ^3%s^0 | Name: ^2%s^0 | ELO: ^6%d^0", i, row.identifier, row.name or "NULL", row.elo))
            end
        else
            print("^1  Aucune donnée trouvée !^0")
        end
        
        -- Test 2 : Pour chaque identifier, vérifier s'il existe dans users
        if results and #results > 0 then
            print("^5=== Vérification dans table users ===^0")
            for i, row in ipairs(results) do
                local identifier = row.identifier
                MySQL.Async.fetchAll("SELECT identifier, firstname, lastname, " .. Config.Database.skinColumn .. " FROM " .. Config.Database.users .. " WHERE identifier = ? LIMIT 1", 
                { identifier }, function(userData)
                    if userData and #userData > 0 then
                        local user = userData[1]
                        local skinRaw = user[Config.Database.skinColumn]
                        local skinLength = skinRaw and #skinRaw or 0
                        local skinParsed = ParseSkin(skinRaw, identifier)
                        local model = skinParsed and skinParsed.model or "NONE"
                        print(string.format("  [%d] ^2TROUVÉ^0 - %s %s | Skin: %d chars | Model: %s", 
                            i, user.firstname or "?", user.lastname or "?", skinLength, model))
                    else
                        print(string.format("  [%d] ^1NON TROUVÉ^0 - Identifier: %s", i, identifier))
                    end
                end)
            end
        end
        
        print("^3========================================^0")
    end)
end, false)

-- ================================================================================================
-- ⏰ AUTO-REFRESH
-- ================================================================================================
if Config.ServerCache.autoRefresh then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.ServerCache.refreshInterval)
            UpdateAllCaches()
        end
    end)
end

-- ================================================================================================
-- 🚀 INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    if Config.ServerCache.loadOnStart then
        Wait(Config.ServerCache.startupDelay)
        
        print("^2========================================^0")
        print("^2  PVP PODIUM v6.1.0 FIXED^0")
        print("^2  Gunfight + Cat & Mouse^0")
        print("^2  Skin Parsing Robuste^0")
        print("^2========================================^0")
        print("^3Gunfight Modes:^0 " .. table.concat(Config.GunfightModes, ", "))
        print("^3Cat & Mouse:^0 Top 3")
        print("^3Auto-refresh:^0 " .. (Config.ServerCache.autoRefresh and "^2OUI^0" or "^1NON^0"))
        print("^2========================================^0")
        
        UpdateAllCaches()
    end
end)

-- ================================================================================================
-- 📤 EXPORTS
-- ================================================================================================
exports('GetGunfightTop1', function(mode)
    return ServerCache.gunfight[mode]
end)

exports('GetCatMouseTop3', function()
    return ServerCache.catmouse
end)

exports('GetAllData', function()
    return ServerCache
end)

exports('ForceRefresh', function()
    UpdateAllCaches()
end)