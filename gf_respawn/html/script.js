// Variables
let deathTimer = null;
let healTimer = null;

// ═══════════════════════════════════════════════════════
// NOUVEAU : GESTION DU PROMPT LOBBY
// ═══════════════════════════════════════════════════════

function showLobbyPrompt() {
    const lobbyPrompt = document.getElementById('lobby-prompt');
    lobbyPrompt.classList.remove('hidden');
}

function hideLobbyPrompt() {
    const lobbyPrompt = document.getElementById('lobby-prompt');
    lobbyPrompt.classList.add('hidden');
}

// ═══════════════════════════════════════════════════════
// ÉCRAN DE MORT
// ═══════════════════════════════════════════════════════

function showDeath(data) {
    const deathScreen = document.getElementById('death-screen');
    const respawnOptions = document.getElementById('respawn-options');
    
    // ⚡ MODIFIE UNIQUEMENT --primary et --secondary (PAS --lobby-color)
    if (data.colors) {
        if (data.colors.primary) {
            document.documentElement.style.setProperty('--primary', data.colors.primary);
        }
        if (data.colors.secondary) {
            document.documentElement.style.setProperty('--secondary', data.colors.secondary);
        }
        // ⚠️ --lobby-color n'est JAMAIS modifiée (elle reste #ff2600)
    }
    
    // Affichage
    deathScreen.classList.remove('hidden');
    respawnOptions.classList.add('hidden');
    
    // Timer
    if (data.timer) {
        startDeathTimer(data.timer);
    }
}

function hideDeath() {
    const deathScreen = document.getElementById('death-screen');
    deathScreen.classList.add('hidden');
    
    if (deathTimer) {
        clearInterval(deathTimer);
        deathTimer = null;
    }
    
}

function startDeathTimer(seconds) {
    const timerText = document.getElementById('timer-seconds');
    const timerCircle = document.getElementById('timer-circle');
    const circumference = 283;
    
    let remaining = seconds;
    timerText.textContent = remaining;
    timerCircle.style.strokeDashoffset = 0;
    
    deathTimer = setInterval(() => {
        remaining--;
        timerText.textContent = remaining;
        
        // Animation du cercle
        const offset = circumference * (remaining / seconds);
        timerCircle.style.strokeDashoffset = offset;
        
        if (remaining <= 0) {
            clearInterval(deathTimer);
            deathTimer = null;
        }
    }, 1000);
}

function enableRespawn() {
    const respawnOptions = document.getElementById('respawn-options');
    respawnOptions.classList.remove('hidden');
}

// ═══════════════════════════════════════════════════════
// INTERFACE DE HEAL
// ═══════════════════════════════════════════════════════

function showHeal(data) {
    const healScreen = document.getElementById('heal-screen');
    const healCircle = document.getElementById('heal-circle');
    const circumference = 283;
    
    // ⚡ MODIFIE UNIQUEMENT --primary (PAS --lobby-color)
    if (data.colors && data.colors.primary) {
        document.documentElement.style.setProperty('--primary', data.colors.primary);
        // ⚠️ --lobby-color n'est JAMAIS modifiée
    }
    
    // Affichage
    healScreen.classList.remove('hidden');
    
    // Reset
    healCircle.style.strokeDashoffset = circumference;
    
    // Animation
    if (data.duration) {
        startHealAnimation(data.duration);
    }
    
}

function hideHeal() {
    const healScreen = document.getElementById('heal-screen');
    healScreen.classList.add('hidden');
    
    if (healTimer) {
        clearInterval(healTimer);
        healTimer = null;
    }
    
}

function startHealAnimation(duration) {
    const healCircle = document.getElementById('heal-circle');
    const healPercent = document.getElementById('heal-percent');
    const circumference = 283;
    const startTime = Date.now();
    
    healTimer = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const percentage = Math.floor(progress * 100);
        
        // Animation du cercle
        const offset = circumference * (1 - progress);
        healCircle.style.strokeDashoffset = offset;
        
        // Mise à jour du pourcentage
        healPercent.textContent = percentage + '%';
        
        if (progress >= 1) {
            clearInterval(healTimer);
            healTimer = null;
        }
    }, 50);
}

// ═══════════════════════════════════════════════════════
// COMMUNICATION AVEC LUA
// ═══════════════════════════════════════════════════════

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'showLobbyPrompt':
            showLobbyPrompt();
            break;
            
        case 'hideLobbyPrompt':
            hideLobbyPrompt();
            break;
            
        case 'showDeath':
            showDeath(data);
            break;
            
        case 'hideDeath':
            hideDeath();
            break;
            
        case 'enableRespawn':
            enableRespawn();
            break;
            
        case 'showHeal':
            showHeal(data);
            break;
            
        case 'hideHeal':
            hideHeal();
            break;
            
        default:
            
    }
});

// ═══════════════════════════════════════════════════════
// TESTS (en navigateur uniquement)
// ═══════════════════════════════════════════════════════

if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    
    document.addEventListener('keydown', (e) => {
        // 0 = Lobby prompt
        if (e.key === '0') {
            if (document.getElementById('lobby-prompt').classList.contains('hidden')) {
                showLobbyPrompt();
            } else {
                hideLobbyPrompt();
            }
        }
        
        // 1 = Mort
        if (e.key === '1') {
            showDeath({
                timer: 5,
                colors: { primary: '#00ff88', secondary: '#ff0055' }
            });
        }
        
        // 2 = Heal
        if (e.key === '2') {
            showHeal({
                duration: 5000,
                colors: { primary: '#00ff88' }
            });
        }
        
        // 3 = Tout masquer
        if (e.key === '3') {
            hideDeath();
            hideHeal();
            hideLobbyPrompt();
        }
    });
}

// Désactivation du clic droit
document.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    return false;
});

// Cleanup
window.addEventListener('beforeunload', () => {
    if (deathTimer) clearInterval(deathTimer);
    if (healTimer) clearInterval(healTimer);
});
