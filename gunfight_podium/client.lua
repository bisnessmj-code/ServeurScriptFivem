-- ================================================================================================
-- PVP PODIUM - CLIENT v6.1.0 FIXED - SKIN APPLICATION ROBUSTE
-- ================================================================================================
-- CORRECTIONS :
-- 1. ApplySkin() amélioré : gère les erreurs natives GTA
-- 2. Fallback model : utilise mp_m_freemode_01 si skin invalide
-- 3. Logs détaillés : debug complet de la création PED
-- 4. Retry logic : retente si la création échoue
-- ================================================================================================

-- ================================================================================================
-- 📦 VARIABLES
-- ================================================================================================
local podiumPeds = {
    gunfight = {},
    catmouse = {}
}
local podiumData = {
    gunfight = {},
    catmouse = {}
}
local blips = {}

-- ================================================================================================
-- 💾 CACHE LOCAL
-- ================================================================================================
local PlayerCache = {
    coords = vector3(0, 0, 0),
    nearestDist = 999999,
    isNear = false,
    lastUpdate = 0
}

-- ================================================================================================
-- 🛠️ LOG DEBUG
-- ================================================================================================
local function Log(message, logType)
    if not Config.Debug then return end
    local types = {
        error = "^1[ERROR]^0",
        success = "^2[OK]^0",
        ped = "^3[PED]^0",
        info = "^5[INFO]^0",
        skin = "^4[SKIN]^0"
    }
    print((types[logType] or "^6[Podium]^0") .. " " .. message)
end

-- ================================================================================================
-- 🔄 MISE À JOUR CACHE JOUEUR
-- ================================================================================================
local function UpdatePlayerCache()
    local now = GetGameTimer()
    if now - PlayerCache.lastUpdate < Config.ClientOptimization.cacheUpdateInterval then return end
    
    PlayerCache.coords = GetEntityCoords(PlayerPedId())
    PlayerCache.lastUpdate = now
    
    local minDist = 999999
    
    -- Check distance Gunfight
    for mode, cfg in pairs(Config.GunfightPodium) do
        local dist = #(PlayerCache.coords - cfg.pos)
        if dist < minDist then minDist = dist end
    end
    
    -- Check distance Cat & Mouse
    for _, cfg in pairs(Config.CatMousePodium) do
        local dist = #(PlayerCache.coords - cfg.pos)
        if dist < minDist then minDist = dist end
    end
    
    PlayerCache.nearestDist = minDist
    PlayerCache.isNear = minDist < Config.Text3D.maxDistance
end

-- ================================================================================================
-- 📝 TEXTE 3D
-- ================================================================================================
local function Draw3DText(x, y, z, text, scale)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(sx, sy)
        DrawRect(sx, sy + 0.0125, 0.015 + #text / 370, 0.03, 0, 0, 0, 150)
    end
end

-- ================================================================================================
-- 🧹 NETTOYER TOUS LES PEDS
-- ================================================================================================
local function CleanupAllPeds()
    Log("Nettoyage de tous les PEDs...", "ped")
    
    -- Cleanup Gunfight
    for mode, ped in pairs(podiumPeds.gunfight) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            Log("PED Gunfight supprimé: " .. mode, "ped")
        end
    end
    
    -- Cleanup Cat & Mouse
    for rank, ped in pairs(podiumPeds.catmouse) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            Log("PED Cat & Mouse supprimé: TOP" .. rank, "ped")
        end
    end
    
    podiumPeds = {
        gunfight = {},
        catmouse = {}
    }
end

-- ================================================================================================
-- 🎨 APPLIQUER SKIN (Robuste avec gestion d'erreurs)
-- ================================================================================================
local function ApplySkin(ped, skinData)
    if not skinData then 
        Log("Aucun skinData fourni, utilisation du model par défaut", "skin")
        return 
    end
    
    Wait(100) -- Laisser le temps au PED d'être chargé
    
    if not DoesEntityExist(ped) then
        Log("✗ PED n'existe plus, impossible d'appliquer le skin", "error")
        return
    end
    
    -- COMPONENTS (vêtements)
    if skinData.components then
        for _, comp in ipairs(skinData.components) do
            if comp.component_id and comp.component_id ~= 99 then
                local drawable = comp.drawable
                
                -- Normaliser le drawable
                if type(drawable) == "string" then 
                    drawable = tonumber(drawable:match("(%d+)")) or 0 
                end
                if type(drawable) ~= "number" then drawable = 0 end
                
                -- Appliquer directement (GTA gère les limites)
                SetPedComponentVariation(ped, comp.component_id, drawable, comp.texture or 0, 0)
            end
        end
        Log(string.format("✓ %d components appliqués", #skinData.components), "skin")
    end
    
    -- PROPS (accessoires)
    if skinData.props then
        for _, prop in ipairs(skinData.props) do
            if prop.prop_id then
                if prop.drawable and prop.drawable ~= -1 then
                    -- Appliquer le prop directement sans vérification (GTA le gère)
                    SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture or 0, true)
                else
                    ClearPedProp(ped, prop.prop_id)
                end
            end
        end
        Log(string.format("✓ %d props appliqués", #skinData.props), "skin")
    end
    
    -- HAIR
    if skinData.hair then
        SetPedComponentVariation(ped, 2, skinData.hair.style or 0, skinData.hair.texture or 0, 0)
        if skinData.hair.color then 
            SetPedHairColor(ped, skinData.hair.color, skinData.hair.highlight or 0) 
        end
        Log("✓ Hair appliqué", "skin")
    end
    
    -- EYE COLOR
    if skinData.eyeColor and skinData.eyeColor >= 0 then 
        SetPedEyeColor(ped, skinData.eyeColor) 
        Log("✓ Eye color appliqué", "skin")
    end
    
    -- HEAD BLEND (morphologie)
    if skinData.headBlend then
        local hb = skinData.headBlend
        local shapeMix, skinMix = hb.shapeMix or 0.5, hb.skinMix or 0.5
        
        -- Normaliser (peut être en pourcentage)
        if shapeMix > 1.0 then shapeMix = shapeMix / 100.0 end
        if skinMix > 1.0 then skinMix = skinMix / 100.0 end
        
        SetPedHeadBlendData(
            ped, 
            hb.shapeFirst or 0, 
            hb.shapeSecond or 0, 
            0, 
            hb.skinFirst or 0, 
            hb.skinSecond or 0, 
            0, 
            shapeMix, 
            skinMix, 
            0.0, 
            false
        )
        Log("✓ Head blend appliqué", "skin")
    end
    
    -- HEAD OVERLAYS (barbe, maquillage, etc.)
    if skinData.headOverlays then
        local map = {
            blemishes = 0,
            beard = 1,
            eyebrows = 2,
            ageing = 3,
            makeUp = 4,
            blush = 5,
            complexion = 6,
            sunDamage = 7,
            lipstick = 8,
            moleAndFreckles = 9,
            chestHair = 10,
            bodyBlemishes = 11
        }
        
        for name, idx in pairs(map) do
            local o = skinData.headOverlays[name]
            if o and o.style and o.style >= 0 and o.style < 255 then
                local opacity = o.opacity or 0
                if opacity > 1.0 then opacity = opacity / 10.0 end
                SetPedHeadOverlay(ped, idx, o.style, opacity)
                
                -- Couleur overlay (barbe, sourcils, etc.)
                if o.color and o.color > 0 then
                    SetPedHeadOverlayColor(ped, idx, 1, o.color, o.secondColor or o.color)
                end
            end
        end
        Log("✓ Head overlays appliqués", "skin")
    end
    
    -- FACE FEATURES (détails du visage)
    if skinData.faceFeatures then
        local map = {
            noseWidth = 0,
            nosePeakHigh = 1,
            nosePeakSize = 2,
            noseBoneHigh = 3,
            nosePeakLowering = 4,
            noseBoneTwist = 5,
            eyeBrownHigh = 6,
            eyeBrownForward = 7,
            cheeksBoneHigh = 8,
            cheeksBoneWidth = 9,
            cheeksWidth = 10,
            eyesOpening = 11,
            lipsThickness = 12,
            jawBoneWidth = 13,
            jawBoneBackSize = 14,
            chinBoneLowering = 15,
            chinBoneLenght = 16,
            chinBoneSize = 17,
            chinHole = 18,
            neckThickness = 19
        }
        
        for name, idx in pairs(map) do
            if skinData.faceFeatures[name] then 
                SetPedFaceFeature(ped, idx, skinData.faceFeatures[name]) 
            end
        end
        Log("✓ Face features appliqués", "skin")
    end
    
    Log("✅ Skin complet appliqué avec succès", "success")
end

-- ================================================================================================
-- 👤 CRÉER UN PED GUNFIGHT (avec retry logic)
-- ================================================================================================
local function CreateGunfightPed(mode, data, maxRetries)
    maxRetries = maxRetries or 3
    
    if not data then
        Log(string.format("✗ Aucune donnée pour mode %s", mode), "error")
        return
    end
    
    local cfg = Config.GunfightPodium[mode]
    if not cfg then
        Log(string.format("✗ Config introuvable pour mode %s", mode), "error")
        return
    end
    
    -- Cleanup ancien PED si existant
    if podiumPeds.gunfight[mode] and DoesEntityExist(podiumPeds.gunfight[mode]) then
        DeleteEntity(podiumPeds.gunfight[mode])
        Wait(100)
    end
    
    Log(string.format("Création PED Gunfight %s: %s (Model: %s)", mode, data.name, data.model or "?"), "ped")
    
    -- Utiliser le model du serveur OU fallback
    local modelName = data.model or "mp_m_freemode_01"
    local modelHash = GetHashKey(modelName)
    
    -- Charger le model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        Log(string.format("✗ Model non chargé après 5s: %s (tentatives restantes: %d)", modelName, maxRetries - 1), "error")
        
        if maxRetries > 1 then
            -- Retry avec le model par défaut
            data.model = "mp_m_freemode_01"
            Wait(500)
            return CreateGunfightPed(mode, data, maxRetries - 1)
        else
            Log(string.format("✗ Abandon création PED %s après %d tentatives", mode, 3), "error")
            return
        end
    end
    
    -- Créer le PED
    local ped = CreatePed(4, modelHash, cfg.pos.x, cfg.pos.y, cfg.pos.z, cfg.heading, false, true)
    
    if not DoesEntityExist(ped) then
        Log(string.format("✗ Échec création PED %s", mode), "error")
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- Configuration PED
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedConfigFlag(ped, 208, true) -- Disable ped flee
    SetPedConfigFlag(ped, 281, true) -- Disable ped melee
    
    -- Appliquer le skin si disponible
    if data.skin then
        ApplySkin(ped, data.skin)
    else
        Log(string.format("⚠ Aucun skin pour %s, utilisation du model de base", mode), "info")
    end
    
    -- Animation si configurée
    if Config.Animations.enabled and Config.Animations.scenarios.gunfight then
        TaskStartScenarioInPlace(ped, Config.Animations.scenarios.gunfight, 0, true)
    end
    
    -- Sauvegarder
    podiumPeds.gunfight[mode] = ped
    podiumData.gunfight[mode] = data
    
    SetModelAsNoLongerNeeded(modelHash)
    Log(string.format("✅ PED Gunfight %s créé: %s", mode, data.name), "success")
end

-- ================================================================================================
-- 👥 CRÉER UN PED CAT & MOUSE (avec retry logic)
-- ================================================================================================
local function CreateCatMousePed(rank, data, maxRetries)
    maxRetries = maxRetries or 3
    
    if not data then
        Log(string.format("✗ Aucune donnée pour rank %d", rank), "error")
        return
    end
    
    local posKey = "top" .. rank
    local cfg = Config.CatMousePodium[posKey]
    
    if not cfg then
        Log(string.format("✗ Config introuvable pour rank %d", rank), "error")
        return
    end
    
    -- Cleanup ancien PED si existant
    if podiumPeds.catmouse[rank] and DoesEntityExist(podiumPeds.catmouse[rank]) then
        DeleteEntity(podiumPeds.catmouse[rank])
        Wait(100)
    end
    
    Log(string.format("Création PED Cat & Mouse TOP%d: %s (Model: %s)", rank, data.name, data.model or "?"), "ped")
    
    -- Utiliser le model du serveur OU fallback
    local modelName = data.model or "mp_m_freemode_01"
    local modelHash = GetHashKey(modelName)
    
    -- Charger le model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        Log(string.format("✗ Model non chargé après 5s: %s (tentatives restantes: %d)", modelName, maxRetries - 1), "error")
        
        if maxRetries > 1 then
            -- Retry avec le model par défaut
            data.model = "mp_m_freemode_01"
            Wait(500)
            return CreateCatMousePed(rank, data, maxRetries - 1)
        else
            Log(string.format("✗ Abandon création PED TOP%d après %d tentatives", rank, 3), "error")
            return
        end
    end
    
    -- Créer le PED
    local ped = CreatePed(4, modelHash, cfg.pos.x, cfg.pos.y, cfg.pos.z, cfg.heading, false, true)
    
    if not DoesEntityExist(ped) then
        Log(string.format("✗ Échec création PED TOP%d", rank), "error")
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- Configuration PED
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedConfigFlag(ped, 208, true)
    SetPedConfigFlag(ped, 281, true)
    
    -- Appliquer le skin si disponible
    if data.skin then
        ApplySkin(ped, data.skin)
    else
        Log(string.format("⚠ Aucun skin pour TOP%d, utilisation du model de base", rank), "info")
    end
    
    -- Animation spécifique selon le rank
    if Config.Animations.enabled and Config.Animations.scenarios.catmouse then
        local scenario = Config.Animations.scenarios.catmouse["top" .. rank]
        if scenario then
            TaskStartScenarioInPlace(ped, scenario, 0, true)
        end
    end
    
    -- Sauvegarder
    podiumPeds.catmouse[rank] = ped
    podiumData.catmouse[rank] = data
    
    SetModelAsNoLongerNeeded(modelHash)
    Log(string.format("✅ PED Cat & Mouse TOP%d créé: %s", rank, data.name), "success")
end

-- ================================================================================================
-- 🔄 CRÉER TOUS LES PEDS
-- ================================================================================================
local function CreateAllPeds(serverData)
    if not serverData then
        Log("✗ Aucune donnée serveur reçue", "error")
        return
    end
    
    CleanupAllPeds()
    Wait(500)
    
    -- Créer PEDs Gunfight
    if serverData.gunfight then
        for _, mode in ipairs(Config.GunfightModes) do
            local data = serverData.gunfight[mode]
            if data then
                CreateGunfightPed(mode, data)
                Wait(200) -- Délai entre chaque création
            else
                Log(string.format("⚠ Pas de données Gunfight pour mode %s", mode), "info")
            end
        end
    end
    
    -- Créer PEDs Cat & Mouse
    if serverData.catmouse then
        for rank, data in ipairs(serverData.catmouse) do
            if data then
                CreateCatMousePed(rank, data)
                Wait(200) -- Délai entre chaque création
            else
                Log(string.format("⚠ Pas de données Cat & Mouse pour rank %d", rank), "info")
            end
        end
    end
    
    Log("✅ Tous les PEDs ont été créés", "success")
end

-- ================================================================================================
-- 📡 EVENT: RECEVOIR MISE À JOUR SERVEUR
-- ================================================================================================
RegisterNetEvent('pvppodium:update')
AddEventHandler('pvppodium:update', function(serverData)
    Log("Réception des données serveur", "info")
    CreateAllPeds(serverData)
end)

-- ================================================================================================
-- ⏱️ THREAD: CACHE JOUEUR
-- ================================================================================================
Citizen.CreateThread(function()
    while true do
        UpdatePlayerCache()
        Wait(Config.ClientOptimization.cacheUpdateInterval)
    end
end)

-- ================================================================================================
-- 🎨 THREAD: AFFICHAGE TEXTE 3D
-- ================================================================================================
Citizen.CreateThread(function()
    if not Config.Text3D.enabled then return end
    
    while true do
        if not PlayerCache.isNear then
            Wait(Config.ClientOptimization.distanceChecks.farWait)
        elseif PlayerCache.nearestDist > Config.Text3D.drawDistance then
            Wait(Config.ClientOptimization.distanceChecks.mediumWait)
        else
            Wait(Config.ClientOptimization.distanceChecks.nearWait)
        end
        
        if not PlayerCache.isNear then goto continue end
        
        -- Affichage Gunfight
        for mode, ped in pairs(podiumPeds.gunfight) do
            if DoesEntityExist(ped) and podiumData.gunfight[mode] and Config.GunfightPodium[mode] then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(PlayerCache.coords - pedCoords)
                
                if dist < Config.Text3D.drawDistance then
                    local p = podiumData.gunfight[mode]
                    local cfg = Config.GunfightPodium[mode]
                    local z = pedCoords.z + 1.0
                    
                    if Config.Text3D.showLabel then
                        z = z + Config.Text3D.spacing.label
                        Draw3DText(pedCoords.x, pedCoords.y, z, cfg.label, 0.4)
                    end
                    
                    if Config.Text3D.showName then
                        z = z - Config.Text3D.spacing.name
                        Draw3DText(pedCoords.x, pedCoords.y, z, p.name, 0.35)
                    end
                    
                    if Config.Text3D.showElo then
                        z = z - Config.Text3D.spacing.elo
                        Draw3DText(pedCoords.x, pedCoords.y, z, string.format(Config.Text3D.eloFormat, p.elo), 0.3)
                    end
                end
            end
        end
        
        -- Affichage Cat & Mouse
        for rank, ped in pairs(podiumPeds.catmouse) do
            if DoesEntityExist(ped) and podiumData.catmouse[rank] then
                local posKey = "top" .. rank
                local cfg = Config.CatMousePodium[posKey]
                
                if cfg then
                    local pedCoords = GetEntityCoords(ped)
                    local dist = #(PlayerCache.coords - pedCoords)
                    
                    if dist < Config.Text3D.drawDistance then
                        local p = podiumData.catmouse[rank]
                        local z = pedCoords.z + 1.0
                        
                        if Config.Text3D.showLabel then
                            z = z + Config.Text3D.spacing.label
                            Draw3DText(pedCoords.x, pedCoords.y, z, cfg.label, 0.4)
                        end
                        
                        if Config.Text3D.showName then
                            z = z - Config.Text3D.spacing.name
                            Draw3DText(pedCoords.x, pedCoords.y, z, p.name, 0.35)
                        end
                        
                        if Config.Text3D.showElo then
                            z = z - Config.Text3D.spacing.elo
                            Draw3DText(pedCoords.x, pedCoords.y, z, string.format(Config.Text3D.eloFormat, p.elo), 0.3)
                        end
                        
                        if Config.Text3D.showStats and p.wins and p.losses then
                            z = z - Config.Text3D.spacing.stats
                            Draw3DText(pedCoords.x, pedCoords.y, z, string.format(Config.Text3D.statsFormat, p.wins, p.losses), 0.25)
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
end)

-- ================================================================================================
-- 📌 BLIPS
-- ================================================================================================
Citizen.CreateThread(function()
    -- Blip Gunfight
    if Config.Blips.gunfight.enabled then
        local blip = AddBlipForCoord(Config.Blips.gunfight.pos)
        SetBlipSprite(blip, Config.Blips.gunfight.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.gunfight.scale)
        SetBlipColour(blip, Config.Blips.gunfight.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blips.gunfight.name)
        EndTextCommandSetBlipName(blip)
        blips.gunfight = blip
        Log("Blip Gunfight créé", "success")
    end
    
    -- Blip Cat & Mouse
    if Config.Blips.catmouse.enabled then
        local blip = AddBlipForCoord(Config.Blips.catmouse.pos)
        SetBlipSprite(blip, Config.Blips.catmouse.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.catmouse.scale)
        SetBlipColour(blip, Config.Blips.catmouse.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blips.catmouse.name)
        EndTextCommandSetBlipName(blip)
        blips.catmouse = blip
        Log("Blip Cat & Mouse créé", "success")
    end
end)

-- ================================================================================================
-- 🧹 NETTOYAGE
-- ================================================================================================
AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    CleanupAllPeds()
    for _, blip in pairs(blips) do
        if blip then RemoveBlip(blip) end
    end
end)

-- ================================================================================================
-- 🚀 INIT
-- ================================================================================================
Citizen.CreateThread(function()
    Wait(2000)
    Log("Client v6.1.0 FIXED initialisé", "success")
    Log("Demande de données au serveur...", "info")
    TriggerServerEvent('pvppodium:requestUpdate')
end)

-- ================================================================================================
-- 🎮 DEBUG
-- ================================================================================================
RegisterCommand('podiumdebug', function()
    print("^3=== PODIUM DEBUG v6.1.0 FIXED ===^0")
    print(string.format("Distance: %.1fm | Near: %s", PlayerCache.nearestDist, PlayerCache.isNear and "OUI" or "NON"))
    
    print("^2=== GUNFIGHT ===^0")
    print("^3Config:^0")
    for mode, cfg in pairs(Config.GunfightPodium) do
        print(string.format("  [%s] pos: (%.1f, %.1f, %.1f)", mode, cfg.pos.x, cfg.pos.y, cfg.pos.z))
    end
    print("^3PEDs actifs:^0")
    for mode, ped in pairs(podiumPeds.gunfight) do
        local data = podiumData.gunfight[mode]
        if ped and DoesEntityExist(ped) and data then
            local coords = GetEntityCoords(ped)
            local model = GetEntityModel(ped)
            print(string.format("  ^2[%s]^0 %s (ELO: %d) Model: %s @ (%.1f, %.1f, %.1f)", 
                mode, data.name, data.elo, data.model or "?", coords.x, coords.y, coords.z))
        else
            print(string.format("  ^1[%s]^0 PED invalide", mode))
        end
    end
    
    print("^5=== CAT & MOUSE ===^0")
    print("^3Config:^0")
    for key, cfg in pairs(Config.CatMousePodium) do
        print(string.format("  [%s] pos: (%.1f, %.1f, %.1f)", key, cfg.pos.x, cfg.pos.y, cfg.pos.z))
    end
    print("^3PEDs actifs:^0")
    for rank, ped in pairs(podiumPeds.catmouse) do
        local data = podiumData.catmouse[rank]
        if ped and DoesEntityExist(ped) and data then
            local coords = GetEntityCoords(ped)
            local model = GetEntityModel(ped)
            print(string.format("  ^2[TOP %d]^0 %s (ELO: %d, W:%d L:%d) Model: %s @ (%.1f, %.1f, %.1f)", 
                rank, data.name, data.elo, data.wins, data.losses, data.model or "?", coords.x, coords.y, coords.z))
        else
            print(string.format("  ^1[TOP %d]^0 PED invalide", rank))
        end
    end
end, false)

RegisterCommand('podiumrefresh', function()
    Log("Refresh manuel demandé", "info")
    TriggerServerEvent('pvppodium:requestUpdate')
end, false)