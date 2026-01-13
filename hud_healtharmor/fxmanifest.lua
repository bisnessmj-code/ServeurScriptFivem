shared_script '@WaveShield/resource/include.lua'

-- ═══════════════════════════════════════════════════════════════════════════
-- HUD Health Armor Bank - Manifest
-- Version: 2.2.0 (Architecture Bridge)
-- ⚠️ SANS WaveShield - Compatible ESX / QBCore
-- ═══════════════════════════════════════════════════════════════════════════

fx_version 'cerulean'
game 'gta5'

name 'hud_healtharmor'
author 'Dev FiveM'
description 'HUD moderne : Santé, Armure, Banque, ID - Architecture Bridge isolée'
version '2.2.0'

-- ═══════════════════════════════════════════════════════════════════════════
-- ⚠️ IMPORTANT: PAS DE WaveShield ici !
-- Si tu as besoin de WaveShield, ajoute-le UNIQUEMENT sur les ressources
-- qui en ont vraiment besoin, PAS sur un HUD.
-- ═══════════════════════════════════════════════════════════════════════════

-- Interface NUI
ui_page 'html/index.html'

-- Ordre de chargement important :
-- 1. Config (variables globales)
-- 2. Bridge (isolation framework)
-- 3. Client (logique HUD)

shared_scripts {
    'config.lua'
}

client_scripts {
    'bridge.lua',
    'client.lua'
}

-- Fichiers NUI
files {
    'html/index.html',
    'html/css/styles.css',
    'html/js/main.js'
}

-- Lua 5.4 pour meilleures performances
lua54 'yes'

-- ═══════════════════════════════════════════════════════════════════════════
-- DÉPENDANCES : Décommenter selon ton framework
-- ═══════════════════════════════════════════════════════════════════════════

-- dependencies {
--     'es_extended',  -- Pour ESX
--     -- 'qb-core',   -- Pour QBCore
-- }
