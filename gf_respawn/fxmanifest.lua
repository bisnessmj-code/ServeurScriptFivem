shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'KichtaBoyUnity - HyperShot Gunfight'
description 'Système de respawn optimisé avec compatibilité multi-scripts'
version '5.0.0'

shared_scripts {
    'config/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Exports côté client
exports {
    'DisableRespawnSystem',
    'EnableRespawnSystem',
    'IsRespawnSystemEnabled'
}

-- Exports côté serveur
server_exports {
    'DisableRespawnForPlayer',
    'EnableRespawnForPlayer',
    'SetPlayerBucketWithNotification'
}
