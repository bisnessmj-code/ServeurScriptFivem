# 📝 CHANGELOG - GF Respawn

## Version 5.0.0 (2025-01-06) - MAJEURE 🎉

### 🆕 Nouvelles fonctionnalités

#### Système de compatibilité multi-scripts
- Ajout d'un système complet de compatibilité pour éviter les interférences avec d'autres scripts
- Support des routing buckets pour la désactivation automatique
- Exports client et serveur pour contrôle manuel
- Events dédiés pour communication inter-scripts

#### Détection automatique des contextes de jeu
- Désactivation automatique quand le joueur est dans un bucket différent de 0
- Liste configurable de buckets autorisés
- Surveillance continue du bucket du joueur

#### API complète pour développeurs
- **Exports client** :
  - `DisableRespawnSystem()` - Désactiver le système
  - `EnableRespawnSystem()` - Activer le système
  - `IsRespawnSystemEnabled()` - Vérifier le statut
  
- **Exports serveur** :
  - `DisableRespawnForPlayer(playerId)` - Désactiver pour un joueur
  - `EnableRespawnForPlayer(playerId)` - Activer pour un joueur
  - `SetPlayerBucketWithNotification(playerId, bucket)` - Changer bucket avec notification

- **Events** :
  - `gf_respawn:disable` / `gf_respawn:enable` (client)
  - `gf_respawn:disableForPlayer` / `gf_respawn:enableForPlayer` (serveur)
  - `gf_respawn:updateBucket` - Notification de changement de bucket

### ⚙️ Configuration

Nouvelles options dans `config.lua` :

```lua
-- Système de compatibilité
Config.EnableCompatibility = true
Config.CompatibleResources = {...}
Config.DisableInBuckets = true
Config.AllowedBuckets = {0}
```

### 🔧 Améliorations

- Le système ne se déclenche plus quand désactivé (optimisation)
- Nettoyage automatique de l'interface si désactivé pendant un état de mort
- Logs détaillés en mode debug pour faciliter l'intégration
- Thread de surveillance du bucket avec update automatique
- Protection contre les déclenchements multiples

### 📚 Documentation

- Ajout d'un README complet avec guide d'intégration
- Fichier INTEGRATION_EXAMPLES.lua avec 7 exemples concrets
- FAQ détaillée et tableau comparatif des méthodes
- Section troubleshooting

### 🐛 Corrections

- Fix : Le système ne se déclenchait pas toujours lors d'une mort en dehors d'un jeu
- Fix : Interface NUI restait affichée lors d'une désactivation en plein respawn
- Fix : Cooldown du heal qui persistait après désactivation/réactivation

### 🔄 Changements techniques

- Refactorisation complète du système de détection de mort
- Ajout de la fonction `IsSystemActive()` pour vérifications centralisées
- Amélioration des threads avec conditions de Wait() optimisées
- Support des buckets négatifs et au-delà de 255

---

## Version 4.0.0 (2025-01-05)

### ✨ Fonctionnalités
- Système de respawn avec timer configurable
- Deux options de respawn : sur place ou au lobby
- Système de heal avec animation et barre de progression
- Interface NUI moderne et épurée
- Support des effets visuels (blur, fade, ragdoll)

### ⚙️ Configuration
- Timer de respawn configurable
- Position du lobby personnalisable
- Durée et montant du heal ajustables
- Cooldown du heal configurable
- Couleurs de l'interface personnalisables

### 🎨 Interface
- Design épuré style gunfight
- Animations fluides
- Timer circulaire avec compte à rebours
- Cartes de respawn interactives
- Interface de heal avec pourcentage

### 🔧 Technique
- Architecture modulaire
- Code optimisé et commenté
- Logs de debug détaillés
- Gestion propre des ressources
- Cleanup automatique

---

## Version 3.0.0 (2024-12-XX)

### Améliorations
- Amélioration du système de heal
- Optimisation des threads
- Nouveaux effets visuels

---

## Version 2.0.0 (2024-11-XX)

### Nouveautés
- Ajout du système de heal
- Interface NUI basique
- Mode debug

---

## Version 1.0.0 (2024-10-XX)

### Première version
- Système de respawn basique
- Timer simple
- Respawn au spawn uniquement

---

## 🔮 Roadmap future

### Version 5.1.0 (Prochainement)
- [ ] Support des frameworks (ESX, QBCore, etc.)
- [ ] Système de permissions pour les respawns
- [ ] Statistiques de mort/respawn par joueur
- [ ] Export des stats en JSON/CSV
- [ ] Webhook Discord pour logs

### Version 6.0.0 (À venir)
- [ ] Interface de configuration in-game
- [ ] Modes de difficulté (hardcore, casual, etc.)
- [ ] Système de pénalités à la mort
- [ ] Respawn avec coût (argent, items, etc.)
- [ ] Zones de respawn multiples

---

## 📊 Statistiques

- **Lignes de code** : ~1200
- **Fichiers** : 8
- **Taille** : ~150 KB
- **Performance** : 0.01ms en moyenne
- **Compatibilité** : FiveM build 2802+

---

## 🙏 Remerciements

Merci à la communauté FiveM pour les retours et suggestions !

**Créé avec ❤️ par KichtaBoyUnity pour HyperShot Gunfight**
