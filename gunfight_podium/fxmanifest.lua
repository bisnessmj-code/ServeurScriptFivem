shared_script '@WaveShield/resource/include.lua'

-- ================================================================================================
-- PVP PODIUM v5.1.0 ULTRA-LIGHT
-- ================================================================================================
-- 4 PEDs : Top 1 de chaque mode (1v1, 2v2, 3v3, 4v4)
-- Requêtes SQL < 5ms par mode
-- ================================================================================================

fx_version 'cerulean'
game 'gta5'

name 'gunfight_podium'
description 'PVP Podium v5.1.0 - Top 1 par mode (1v1, 2v2, 3v3, 4v4)'
author 'kichta'
version '5.1.0'

dependencies {
    'es_extended',
    'oxmysql'
}

shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_script 'client.lua'

lua54 'yes'

print([[
^2================================^0
^2  PVP PODIUM v5.1.0^0
^2================================^0
^3  4 PEDs : Top 1 par mode^0
^3  SQL < 5ms par requete^0
^2================================^0
]])