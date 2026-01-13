-- ═══════════════════════════════════════════════════════════════════════
-- Configuration ESX SafeZone v3.1.0
-- ARCHITECTURE ANTI-CRASH GARANTIE + PROTECTION FANCA_ANTITANK
-- Performance: <0.01% CPU | Compatible: qs-multicharacter + fanca_antitank
-- ═══════════════════════════════════════════════════════════════════════

Config = {}

-- ═══════════════════════════════════════════════════════════════════════
-- 🐛 DEBUG & LOGS
-- ═══════════════════════════════════════════════════════════════════════
Config.Debug = false        -- Logs détaillés (false en production)
Config.ServerLogs = false    -- Logs serveur (recommandé: true pour debug fanca_antitank)

-- ═══════════════════════════════════════════════════════════════════════
-- 🛡️ PROTECTION FANCA_ANTITANK
-- ═══════════════════════════════════════════════════════════════════════
Config.BlockAttacksFromSafeZone = true  -- ✅ Bloquer les attaques DEPUIS une safezone
Config.NotifyAttackerOnBlock = false     -- ✅ Notifier l'attaquant si cible protégée

-- ═══════════════════════════════════════════════════════════════════════
-- 🎨 CONFIGURATION VISUELLE
-- ═══════════════════════════════════════════════════════════════════════
Config.Visual = {
    showMarkers = false,    -- ❌ DÉSACTIVÉ (cause de lag)
    showBlips = true,       -- ✅ ACTIF : blips sur la carte
}

-- ═══════════════════════════════════════════════════════════════════════
-- 💬 NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════
Config.Notifications = {
    enabled = false,         -- ✅ Notifications activées
    type = 'chat',          -- 'chat' ou 'esx'
    
    messages = {
        entering = '🛡️ ~g~Zone sécurisée - Armes désactivées',
        leaving = '⚠️ ~y~Zone sécurisée désactivée',
    }
}

-- ═══════════════════════════════════════════════════════════════════════
-- 🗺️ DÉFINITION DES ZONES SÉCURISÉES
-- ═══════════════════════════════════════════════════════════════════════
Config.SafeZones = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- ZONE 1 : LEGION SQUARE
    -- ═══════════════════════════════════════════════════════════════════════
    {
        name = 'Legion Square',
        id = 'legion_square',
        
        geometry = {
            type = 'cylinder',
            position = vector3(-5798.782226, -918.791198, 502.489990),
            radius = 40.0,
            height = 22.0,
        },
        
        effects = {
            disableWeapons = true,      -- ✅ Armes désactivées
            disableMelee = true,        -- ✅ Mêlée désactivée
            disableHeadshots = true,    -- ✅ Protection fanca_antitank headshots
            speedMultiplier = 6.0,      -- Vitesse x6
            godMode = true,             -- ✅ Invincibilité
        },
        
        visual = {
            blip = {
                enabled = true,
                sprite = 310,
                color = 2,
                scale = 0.9,
                label = 'Safe Zone - Legion Square'
            }
        },
        
        enabled = true,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- ZONE 2 : ZONE PERSONNALISÉE
    -- ═══════════════════════════════════════════════════════════════════════
    {
        name = 'Zone Sécurisée #2',
        id = 'safezone_custom_2',
        
        geometry = {
            type = 'cylinder',
            position = vector3(-1439.643921, -2816.399902, 430.928955),
            radius = 40.0,
            height = 20.0,
        },
        
        effects = {
            disableWeapons = false,     -- Armes autorisées
            disableMelee = true,        -- ✅ Mêlée désactivée (coups de poing)
            disableHeadshots = false,   -- ❌ Headshots autorisés (zone combat)
            speedMultiplier = 4.0,      -- Vitesse x4
            godMode = true,             -- ✅ Invincibilité (mais headshots possibles)
        },
        
        visual = {
            blip = {
                enabled = true,
                sprite = 310,
                color = 3,
                scale = 0.9,
                label = 'Safe Zone #2'
            }
        },
        
        enabled = true,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- ZONE 3 : ZONE PERSONNALISÉE
    -- ═══════════════════════════════════════════════════════════════════════
    {
        name = 'Zone Sécurisée #3',
        id = 'safezone_custom_3',
        
        geometry = {
            type = 'cylinder',
            position = vector3(1709.301147, 3252.698975, 41.024170),
            radius = 40.0,
            height = 20.0,
        },
        
        effects = {
            disableWeapons = false,     -- Armes autorisées
            disableMelee = true,        -- ✅ Mêlée désactivée (coups de poing)
            disableHeadshots = false,   -- ❌ Headshots autorisés
            speedMultiplier = 4.0,      -- Vitesse x4
            godMode = true,             -- ✅ Invincibilité
        },
        
        visual = {
            blip = {
                enabled = true,
                sprite = 310,
                color = 3,
                scale = 0.9,
                label = 'Safe Zone #3'
            }
        },
        
        enabled = true,
    },
}

-- ═══════════════════════════════════════════════════════════════════════
-- 🔧 FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════════════════

function Config.GetActiveZonesCount()
    local count = 0
    for _, zone in ipairs(Config.SafeZones) do
        if zone.enabled then
            count = count + 1
        end
    end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════
-- 📝 NOTES D'INTÉGRATION FANCA_ANTITANK
-- ═══════════════════════════════════════════════════════════════════════
--[[
    
    🛡️ PROTECTION MULTI-NIVEAUX :
    
    1. Hook weaponDamageAdjust (serveur)
       → Bloque TOUS les dégâts sur les joueurs en zone
       → Fonctionne même si l'attaquant est hors zone
    
    2. Événement fanca_antitank:kill (serveur)
       → Annule les kills forcés si victime en zone
       → Protection contre les headshots instantanés
    
    3. SetDisableHeadshots (serveur → client)
       → Désactive les headshots côté client fanca_antitank
       → Active automatiquement si disableHeadshots = true ou disableWeapons = true
    
    4. GodMode + Invincibilité (client)
       → Protection locale contre les dégâts
       → Redondance avec les protections serveur
    
    ⚙️ CONFIGURATION PAR ZONE :
    
    Pour une zone ULTRA-SÉCURISÉE (aucun combat possible) :
    {
        effects = {
            disableWeapons = true,
            disableMelee = true,
            disableHeadshots = true,
            godMode = true,
        }
    }
    
    Pour une zone de COMBAT ÉQUILIBRÉ (pas de headshots) :
    {
        effects = {
            disableWeapons = false,
            disableMelee = false,
            disableHeadshots = true,
            godMode = false,
        }
    }
    
    Pour une zone SEMI-PROTÉGÉE (invincible mais attaques possibles) :
    {
        effects = {
            disableWeapons = false,
            disableMelee = false,
            disableHeadshots = false,
            godMode = true,
        }
    }
    
    🔍 COMMANDES DEBUG :
    
    /safezone_list     → Liste des joueurs en zone
    /safezone_debug    → Informations sur l'intégration fanca_antitank
    /safezone info     → Informations client
    
]]