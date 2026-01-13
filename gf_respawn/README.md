# 🎮 GF Respawn v5.0 - Système de Respawn Compatible

## 📋 Présentation

Système de respawn optimisé avec **compatibilité multi-scripts** pour éviter les interférences avec d'autres systèmes de jeu (gunfight, deathmatch, TDM, etc.).

## ✨ Nouveautés v5.0

- ✅ **Système de compatibilité** : Désactive automatiquement le respawn quand le joueur est dans un jeu
- ✅ **Support routing buckets** : Détection automatique des buckets pour isoler les jeux
- ✅ **Exports multiples** : Contrôle depuis n'importe quel script (client & serveur)
- ✅ **Events dédiés** : Communication simplifiée entre scripts
- ✅ **Configuration flexible** : Activable/désactivable selon vos besoins

---

## 🔧 Configuration (config.lua)

### Système de compatibilité

```lua
-- Activer le système de compatibilité
Config.EnableCompatibility = true

-- Liste des ressources compatibles (optionnel)
Config.CompatibleResources = {
    "gf_gunfight",      -- Nom de votre script gunfight
    "gf_deathmatch",
    "gf_tdm",
}

-- Détection par routing bucket (recommandé)
Config.DisableInBuckets = true
Config.AllowedBuckets = {0}  -- Le système ne fonctionne que dans le bucket 0 (monde normal)
```

### Explication

- **EnableCompatibility** : Active le système de compatibilité
- **DisableInBuckets** : Si `true`, le système se désactive automatiquement dans les buckets différents de 0
- **AllowedBuckets** : Liste des buckets où le système reste actif (par défaut seulement le bucket 0)

---

## 🎯 Intégration avec vos scripts de jeu

Il existe **3 méthodes** pour désactiver le respawn quand un joueur entre dans un jeu :

### Méthode 1 : Routing Buckets (RECOMMANDÉ ⭐)

**La plus simple et la plus efficace**. Si vos scripts de jeu utilisent des routing buckets, le système se désactivera **automatiquement**.

#### Exemple dans votre script gunfight :

```lua
-- Côté serveur
RegisterNetEvent('gunfight:startGame')
AddEventHandler('gunfight:startGame', function(playerId)
    -- Placer le joueur dans un bucket isolé (1, 2, 3, etc.)
    SetPlayerRoutingBucket(playerId, 1)
    
    -- Le système gf_respawn se désactivera automatiquement !
end)

RegisterNetEvent('gunfight:endGame')
AddEventHandler('gunfight:endGame', function(playerId)
    -- Remettre le joueur dans le bucket normal
    SetPlayerRoutingBucket(playerId, 0)
    
    -- Le système gf_respawn se réactivera automatiquement !
end)
```

**Avantages** :
- Aucun code supplémentaire nécessaire
- Fonctionne avec tous les scripts qui utilisent des buckets
- Gestion automatique

---

### Méthode 2 : Exports (Simple)

Si vous ne voulez pas utiliser les buckets, utilisez les exports.

#### Côté client :

```lua
-- Désactiver le système
exports['gf_respawn']:DisableRespawnSystem()

-- Activer le système
exports['gf_respawn']:EnableRespawnSystem()

-- Vérifier le statut
local isActive = exports['gf_respawn']:IsRespawnSystemEnabled()
```

#### Exemple dans votre script gunfight (client) :

```lua
-- Quand le joueur rejoint un match
RegisterNetEvent('gunfight:playerJoinMatch')
AddEventHandler('gunfight:playerJoinMatch', function()
    -- Désactiver le respawn de gf_respawn
    exports['gf_respawn']:DisableRespawnSystem()
    
    print("^2[GUNFIGHT]^7 Système de respawn gf_respawn désactivé")
end)

-- Quand le joueur quitte le match
RegisterNetEvent('gunfight:playerLeaveMatch')
AddEventHandler('gunfight:playerLeaveMatch', function()
    -- Réactiver le respawn
    exports['gf_respawn']:EnableRespawnSystem()
    
    print("^2[GUNFIGHT]^7 Système de respawn gf_respawn réactivé")
end)
```

#### Côté serveur :

```lua
-- Désactiver pour un joueur spécifique
exports['gf_respawn']:DisableRespawnForPlayer(playerId)

-- Activer pour un joueur spécifique
exports['gf_respawn']:EnableRespawnForPlayer(playerId)
```

---

### Méthode 3 : Events (Flexible)

Vous pouvez aussi utiliser des events pour contrôler le système.

#### Côté client :

```lua
-- Désactiver le système
TriggerEvent('gf_respawn:disable')

-- Activer le système
TriggerEvent('gf_respawn:enable')
```

#### Côté serveur :

```lua
-- Désactiver pour un joueur
TriggerClientEvent('gf_respawn:disable', playerId)

-- Activer pour un joueur
TriggerClientEvent('gf_respawn:enable', playerId)

-- Ou via l'event serveur
TriggerEvent('gf_respawn:disableForPlayer', playerId)
TriggerEvent('gf_respawn:enableForPlayer', playerId)
```

---

## 📝 Exemple complet : Script Gunfight

Voici un exemple complet d'intégration avec un script gunfight.

### Avec routing buckets (recommandé) :

```lua
-- server/main.lua de votre script gunfight

local activePlayers = {}

RegisterNetEvent('gunfight:startGame')
AddEventHandler('gunfight:startGame', function()
    local playerId = source
    
    -- Placer le joueur dans un bucket isolé
    SetPlayerRoutingBucket(playerId, 1)
    
    activePlayers[playerId] = true
    
    print(string.format("^2[GUNFIGHT]^7 Joueur %d en jeu (bucket 1)", playerId))
end)

RegisterNetEvent('gunfight:endGame')
AddEventHandler('gunfight:endGame', function()
    local playerId = source
    
    -- Remettre dans le monde normal
    SetPlayerRoutingBucket(playerId, 0)
    
    activePlayers[playerId] = nil
    
    print(string.format("^2[GUNFIGHT]^7 Joueur %d hors jeu (bucket 0)", playerId))
end)

-- Cleanup à la déconnexion
AddEventHandler('playerDropped', function()
    local playerId = source
    
    if activePlayers[playerId] then
        activePlayers[playerId] = nil
    end
end)
```

**C'est tout !** Avec les buckets, aucun code supplémentaire n'est nécessaire.

---

### Sans routing buckets (avec exports) :

```lua
-- server/main.lua de votre script gunfight

local activePlayers = {}

RegisterNetEvent('gunfight:startGame')
AddEventHandler('gunfight:startGame', function()
    local playerId = source
    
    -- Désactiver le système de respawn pour ce joueur
    exports['gf_respawn']:DisableRespawnForPlayer(playerId)
    
    activePlayers[playerId] = true
    
    print(string.format("^2[GUNFIGHT]^7 Joueur %d en jeu, respawn désactivé", playerId))
end)

RegisterNetEvent('gunfight:endGame')
AddEventHandler('gunfight:endGame', function()
    local playerId = source
    
    -- Réactiver le système de respawn
    exports['gf_respawn']:EnableRespawnForPlayer(playerId)
    
    activePlayers[playerId] = nil
    
    print(string.format("^2[GUNFIGHT]^7 Joueur %d hors jeu, respawn réactivé", playerId))
end)

-- Cleanup à la déconnexion
AddEventHandler('playerDropped', function()
    local playerId = source
    
    if activePlayers[playerId] then
        activePlayers[playerId] = nil
    end
end)
```

---

## 🎯 Cas d'utilisation

### 1. Gunfight / Deathmatch
```lua
-- Début du match
SetPlayerRoutingBucket(playerId, 1)  -- Désactivation auto

-- Fin du match
SetPlayerRoutingBucket(playerId, 0)  -- Réactivation auto
```

### 2. TDM avec équipes
```lua
-- Rejoindre équipe rouge (bucket 10)
SetPlayerRoutingBucket(playerId, 10)

-- Rejoindre équipe bleue (bucket 11)
SetPlayerRoutingBucket(playerId, 11)

-- Quitter le match
SetPlayerRoutingBucket(playerId, 0)
```

### 3. Zones spéciales
```lua
-- Zone d'entraînement
TriggerClientEvent('gf_respawn:disable', playerId)

-- Sortie de la zone
TriggerClientEvent('gf_respawn:enable', playerId)
```

---

## 🔍 Debug

Activez le mode debug dans `config.lua` :

```lua
Config.Debug = true
```

Logs typiques :

```
[GF-RESPAWN] Système désactivé : joueur dans un jeu (isInGame = true)
[GF-RESPAWN] Système désactivé : bucket 1 non autorisé
[GF-RESPAWN] OnPlayerDeath ignoré : système désactivé
[GF-RESPAWN] Bucket mis à jour : 0
[GF-RESPAWN] === SYSTÈME ACTIVÉ ===
```

---

## 📊 Comparaison des méthodes

| Méthode | Difficulté | Automatique | Recommandé |
|---------|-----------|-------------|------------|
| Routing Buckets | ⭐ Facile | ✅ Oui | ✅ OUI |
| Exports | ⭐⭐ Moyen | ❌ Non | ⚡ Si pas de buckets |
| Events | ⭐⭐ Moyen | ❌ Non | ⚡ Pour flexibilité |

---

## ❓ FAQ

### Q : Le système se désactive tout seul ?
**R :** Vérifiez que vous n'êtes pas dans un bucket différent de 0. Utilisez `/getbucket` pour le vérifier.

### Q : Comment savoir si le système est actif ?
**R :** Utilisez l'export :
```lua
local isActive = exports['gf_respawn']:IsRespawnSystemEnabled()
print("Système actif : " .. tostring(isActive))
```

### Q : Puis-je utiliser plusieurs méthodes ensemble ?
**R :** Oui ! Par exemple, vous pouvez utiliser les buckets ET les exports pour un contrôle maximal.

### Q : Comment désactiver complètement la compatibilité ?
**R :** Dans `config.lua` :
```lua
Config.EnableCompatibility = false
```

### Q : Le heal fonctionne-t-il aussi avec le système ?
**R :** Oui ! Le heal (touche H) est aussi désactivé automatiquement quand le système est inactif.

---

## 🔄 Migration depuis l'ancienne version

Si vous aviez la v4.0, voici les changements :

1. **Configuration** : Ajoutez les nouvelles options dans `config.lua`
```lua
Config.EnableCompatibility = true
Config.DisableInBuckets = true
Config.AllowedBuckets = {0}
```

2. **Vos scripts** : Rien à changer si vous utilisez des buckets ! Sinon, ajoutez les exports comme expliqué ci-dessus.

---

## 🎮 Commandes de test

Créez un fichier `test_commands.lua` pour tester :

```lua
-- client/test_commands.lua (à ajouter dans fxmanifest.lua en dev)

RegisterCommand('respawn_disable', function()
    exports['gf_respawn']:DisableRespawnSystem()
    print("^2Système désactivé")
end)

RegisterCommand('respawn_enable', function()
    exports['gf_respawn']:EnableRespawnSystem()
    print("^2Système activé")
end)

RegisterCommand('respawn_status', function()
    local status = exports['gf_respawn']:IsRespawnSystemEnabled()
    print("^2Système : " .. (status and "ACTIF" or "INACTIF"))
end)

RegisterCommand('setbucket', function(source, args)
    local bucket = tonumber(args[1]) or 0
    TriggerServerEvent('test:setBucket', bucket)
end)
```

```lua
-- server/test_commands.lua

RegisterNetEvent('test:setBucket')
AddEventHandler('test:setBucket', function(bucket)
    local playerId = source
    SetPlayerRoutingBucket(playerId, bucket)
    print(string.format("^2Joueur %d placé dans bucket %d", playerId, bucket))
end)
```

Commandes in-game :
- `/respawn_disable` - Désactiver le système
- `/respawn_enable` - Activer le système
- `/respawn_status` - Voir le statut
- `/setbucket 1` - Changer de bucket

---

## 📞 Support

Si vous avez des questions sur l'intégration avec vos scripts, activez le debug et partagez les logs.

**Note** : Ce système est conçu pour être **totalement invisible** pour le joueur. Il n'affecte que le comportement interne du script.

---

## 🚀 Bonnes pratiques

1. **Toujours utiliser les buckets** si possible (méthode recommandée)
2. **Tester** avec le mode debug activé
3. **Nettoyer** les états à la déconnexion du joueur
4. **Documenter** vos intégrations pour la maintenance
5. **Vérifier** que le système est réactivé après chaque match

---

## 📄 Licence

Créé par KichtaBoyUnity pour HyperShot Gunfight.
Version 5.0.0 - 2025

**Bonne chance avec votre serveur ! 🎮**
