Config = {}

-- ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
-- ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
-- ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
-- ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
-- ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
-- ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 

-- Mode debug (affiche les logs)
Config.Debug = true  -- Activé pour les tests, désactiver en production

-- ██████╗ ██████╗ ███╗   ███╗██████╗  █████╗ ████████╗██╗██████╗ ██╗██╗     ██╗████████╗███████╗
-- ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗██║██║     ██║╚══██╔══╝██╔════╝
-- ██║     ██║   ██║██╔████╔██║██████╔╝███████║   ██║   ██║██████╔╝██║██║     ██║   ██║   █████╗  
-- ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║   ██║   ██║██╔══██╗██║██║     ██║   ██║   ██╔══╝  
-- ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║   ██║   ██║██████╔╝██║███████╗██║   ██║   ███████╗
--  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝╚═════╝ ╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝

-- Système de compatibilité avec d'autres scripts
-- Permet aux scripts de jeu (gunfight, etc.) de désactiver temporairement ce système

-- Activer le système de compatibilité
Config.EnableCompatibility = true

-- Liste des ressources qui peuvent désactiver le système
-- Si une de ces ressources est active, le système ne se déclenchera pas
Config.CompatibleResources = {
    "gf_gunfight",      -- Remplace par le nom de ton script gunfight
    "gf_deathmatch",    -- Autres scripts de jeu
    "gf_tdm",
    -- Ajoute ici les noms de tes autres scripts de jeu
}

-- Détection automatique par routing bucket
-- Si le joueur est dans un bucket différent de 0, le système sera désactivé
Config.DisableInBuckets = true
Config.AllowedBuckets = {0}  -- Liste des buckets où le système est actif (0 = monde normal)

-- ███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗
-- ██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║
-- ███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║
-- ╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║
-- ███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║
-- ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝

-- Position du spawn (lobby) - NOUVELLE POSITION
Config.SpawnPosition = {
    x = -5799.876953,
    y = -918.026367,
    z = 506.803711,
    heading = 87.874016
}

-- ███╗   ███╗ ██████╗ ██████╗ ████████╗
-- ████╗ ████║██╔═══██╗██╔══██╗╚══██╔══╝
-- ██╔████╔██║██║   ██║██████╔╝   ██║   
-- ██║╚██╔╝██║██║   ██║██╔══██╗   ██║   
-- ██║ ╚═╝ ██║╚██████╔╝██║  ██║   ██║   
-- ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

-- Timer avant de pouvoir respawn (en secondes)
Config.RespawnTimer = 3

-- Santé après respawn
Config.RespawnHealth = 200

-- ██╗  ██╗███████╗ █████╗ ██╗     
-- ██║  ██║██╔════╝██╔══██╗██║     
-- ███████║█████╗  ███████║██║     
-- ██╔══██║██╔══╝  ██╔══██║██║     
-- ██║  ██║███████╗██║  ██║███████╗
-- ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝

-- Durée du heal (en secondes)
Config.HealDuration = 2

-- Vie récupérée
Config.HealAmount = 200

-- Cooldown entre chaque heal (en secondes)
Config.HealCooldown = 1

-- Touches pour le heal (liste de contrôles FiveM)
-- 74 = H | 288 = F1 | 289 = F2 | 170 = F3
-- Liste complète : https://docs.fivem.net/docs/game-references/controls/
Config.HealKeys = {288}  -- F1 uniquement

-- ████████╗██╗  ██╗███████╗███╗   ███╗███████╗
-- ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝
-- ██║   ███████║█████╗  ██╔████╔██║█████╗  
--    ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝  
--    ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗
--    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝

-- Couleurs de l'interface
Config.Colors = {
    primary = "#00ff88",      -- Vert gunfight
    secondary = "#ff0055",    -- Rouge
    background = "#000000"    -- Noir
}