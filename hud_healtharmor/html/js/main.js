// ═══════════════════════════════════════════════════════════════════════════
// HUD Health Armor Bank - JavaScript v2.2.0
// ═══════════════════════════════════════════════════════════════════════════

(function() {
    'use strict';

    const DANGER_THRESHOLD = 20;

    // Cache DOM
    const el = {
        hudTop: document.getElementById('hudTop'),
        hudBottom: document.getElementById('hudBottom'),
        hudId: document.getElementById('hudId'),
        textId: document.getElementById('textId'),
        hudBank: document.getElementById('hudBank'),
        textBank: document.getElementById('textBank'),
        hudHealth: document.getElementById('hudHealth'),
        fillHealth: document.getElementById('fillHealth'),
        hudArmor: document.getElementById('hudArmor'),
        fillArmor: document.getElementById('fillArmor')
    };

    // État
    const state = {
        health: -1,
        armor: -1,
        id: -1,
        bank: null,
        visible: true,
        danger: false
    };

    // Utilitaires
    function clamp(val) {
        return Math.max(0, Math.min(100, val));
    }

    // Updates
    function updateHealth(pct) {
        if (state.health === pct) return;
        
        const hp = clamp(pct);
        el.fillHealth.style.width = hp + '%';
        
        const isDanger = hp <= DANGER_THRESHOLD;
        if (isDanger !== state.danger) {
            el.hudHealth.classList.toggle('danger', isDanger);
            state.danger = isDanger;
        }
        
        state.health = hp;
    }

    function updateArmor(pct) {
        if (state.armor === pct) return;
        
        const armor = clamp(pct);
        el.fillArmor.style.width = armor + '%';
        state.armor = armor;
    }

    function updateId(id) {
        if (state.id === id) return;
        
        el.textId.textContent = id ? 'ID ' + id : 'ID -';
        state.id = id;
    }

    function updateBank(amount) {
        if (!el.hudBank) return;
        
        if (amount !== null && amount !== undefined) {
            el.hudBank.style.display = 'flex';
            if (state.bank !== amount) {
                el.textBank.textContent = amount;
                state.bank = amount;
            }
        } else {
            el.hudBank.style.display = 'none';
            state.bank = null;
        }
    }

    function toggleHud(show) {
        if (state.visible === show) return;
        
        const display = show ? 'flex' : 'none';
        el.hudTop.style.display = display;
        el.hudBottom.style.display = display;
        state.visible = show;
    }

    // Handler messages
    function handleMessage(data) {
        if (!data || !data.action) return;
        
        switch (data.action) {
            case 'update':
                updateHealth(Number(data.health) || 0);
                updateArmor(Number(data.armor) || 0);
                updateId(data.id !== undefined ? data.id : '');
                updateBank(data.bank !== undefined ? data.bank : null);
                break;
                
            case 'toggle':
                toggleHud(data.show !== false);
                break;
                
            case 'setBank':
                updateBank(data.bank !== undefined ? data.bank : null);
                break;
        }
    }

    // Event listener
    window.addEventListener('message', function(e) {
        handleMessage(e.data);
    });

    // Init
    function init() {
        updateHealth(0);
        updateArmor(0);
        updateId(0);
        updateBank(null);
        
        // Signal ready
        try {
            fetch('https://' + GetParentResourceName() + '/nuiReady', {
                method: 'POST',
                body: JSON.stringify({ ready: true })
            }).catch(function() {});
        } catch (e) {}
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Debug export
    window.HUD = { state, updateHealth, updateArmor, updateId, updateBank, toggleHud };

})();
