-- ═══════════════════════════════════════════════════════════════════════════
-- HUD Health Armor Bank - Configuration
-- Version: 2.2.0
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAMEWORK
-- ═══════════════════════════════════════════════════════════════════════════

-- Framework utilisé : 'ESX' ou 'QBCore'
-- ⚠️ IMPORTANT : Le HUD récupère l'argent via le framework, PAS via l'inventaire !
Config.Framework = 'ESX'

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG
-- ═══════════════════════════════════════════════════════════════════════════

-- Active les logs détaillés dans la console F8
Config.Debug = false

-- ═══════════════════════════════════════════════════════════════════════════
-- PARAMÈTRES GÉNÉRAUX
-- ═══════════════════════════════════════════════════════════════════════════

-- Active/désactive le HUD
Config.Enabled = true

-- Intervalle de mise à jour en ms (150-300ms recommandé)
Config.UpdateInterval = 200

-- Seuil de danger pour la santé (animation pulsation)
Config.DangerThreshold = 20

-- ═══════════════════════════════════════════════════════════════════════════
-- AFFICHAGE BANQUE
-- ═══════════════════════════════════════════════════════════════════════════

Config.Bank = {
    -- Active l'affichage du compte bancaire
    Enabled = true,
    
    -- Format : 'compact' (1.2M$) ou 'full' (1 234 567$)
    Format = 'compact',
    
    -- Symbole monétaire
    Symbol = '$',
    
    -- Séparateur milliers (mode 'full')
    Separator = ' '
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MASQUAGE HUD NATIF GTA
-- ═══════════════════════════════════════════════════════════════════════════

-- Masquer les barres natives santé/armure de GTA
Config.HideNativeBars = false

-- Composants HUD natifs à masquer (IDs)
-- Liste: https://docs.fivem.net/natives/?_0x6806C51AD12B83B8
Config.HideComponents = {
    3,  -- Cash
    4,  -- MP Cash
    7,  -- Area Name
}

-- ═══════════════════════════════════════════════════════════════════════════
-- COMPORTEMENT AVANCÉ
-- ═══════════════════════════════════════════════════════════════════════════

Config.Advanced = {
    -- Masquer le HUD dans certaines situations
    HideInVehicle = false,
    HideWhenDead = true,
    HideInPauseMenu = true,
    
    -- Durée des animations (ms)
    TransitionDuration = 220
}

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS & EVENTS DISPONIBLES
-- ═══════════════════════════════════════════════════════════════════════════

--[[
EXPORTS:
    exports['hud_healtharmor']:toggleHud(true/false)
    exports['hud_healtharmor']:updateBank(montant)
    exports['hud_healtharmor']:forceRefresh()
    exports['hud_healtharmor']:isHudVisible()

EVENTS:
    TriggerEvent('hud:toggle', true/false)
    TriggerEvent('hud:updateBank', montant)
]]
