let currentData = {};
let isInLobby = false;

// Initialize UI
document.addEventListener('DOMContentLoaded', function() {
    // Setup form submission
    document.getElementById('createLobbyForm').addEventListener('submit', function(e) {
        e.preventDefault();
        createLobby();
    });
    
    // Setup escape key to close menus
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });
});

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openMenu':
            openMenu(data.data);
            break;
        case 'showLeaderboard':
            showLeaderboard(data.data);
            break;
        case 'closeLeaderboard':
            closeLeaderboard();
            break;
        case 'lobbiesList':
            displayLobbies(data.data);
            break;
    }
});

// Open main menu
function openMenu(data) {
    currentData = data;
    isInLobby = data.isInLobby;
    
    // Populate dropdowns
    populateMapSelect(data.maps);
    populateWeaponSelect(data.weapons);
    
    // Show current lobby info if in lobby
    if (isInLobby && data.currentLobby) {
        updateCurrentLobbyInfo(data.currentLobby);
        document.getElementById('currentLobbyInfo').style.display = 'block';
    } else {
        document.getElementById('currentLobbyInfo').style.display = 'none';
    }
    
    document.getElementById('app').style.display = 'flex';
    showMainMenu();
}

// Close menu
function closeMenu() {
    document.getElementById('app').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Show main menu
function showMainMenu() {
    hideAllMenus();
    document.getElementById('mainMenu').style.display = 'block';
}

// Show create lobby menu
function showCreateLobby() {
    if (isInLobby) {
        showNotification('You are already in a lobby!', 'error');
        return;
    }
    
    hideAllMenus();
    document.getElementById('createLobbyMenu').style.display = 'block';
    
    // Reset form
    document.getElementById('createLobbyForm').reset();
    document.getElementById('maxPlayersInput').value = 8;
}

// Show join lobby menu
function showJoinLobby() {
    if (isInLobby) {
        showNotification('You are already in a lobby!', 'error');
        return;
    }
    
    hideAllMenus();
    document.getElementById('joinLobbyMenu').style.display = 'block';
    
    // Load lobbies
    refreshLobbies();
}

// Hide all menus
function hideAllMenus() {
    const menus = ['mainMenu', 'createLobbyMenu', 'joinLobbyMenu'];
    menus.forEach(menu => {
        document.getElementById(menu).style.display = 'none';
    });
}

// Populate map select dropdown
function populateMapSelect(maps) {
    const select = document.getElementById('mapSelect');
    select.innerHTML = '<option value="">Select a map</option>';
    
    maps.forEach((map, index) => {
        const option = document.createElement('option');
        option.value = index + 1;
        option.textContent = map.name;
        select.appendChild(option);
    });
}

// Populate weapon select dropdown
function populateWeaponSelect(weapons) {
    const select = document.getElementById('weaponSelect');
    select.innerHTML = '<option value="">Select weapons</option>';
    
    weapons.forEach((weapon, index) => {
        const option = document.createElement('option');
        option.value = index + 1;
        option.textContent = weapon.name;
        select.appendChild(option);
    });
}

// Update current lobby info
function updateCurrentLobbyInfo(lobby) {
    document.getElementById('lobbyName').textContent = lobby.name;
    document.getElementById('lobbyPlayers').textContent = `${lobby.players.length}/${lobby.maxPlayers}`;
    document.getElementById('lobbyMap').textContent = currentData.maps[lobby.mapIndex - 1]?.name || 'Unknown';
    document.getElementById('lobbyWeapons').textContent = currentData.weapons[lobby.weaponIndex - 1]?.name || 'Unknown';
    
    // Show start button only for lobby creator
    const startBtn = document.getElementById('startGameBtn');
    if (lobby.creator === getCurrentPlayerId()) {
        startBtn.style.display = 'block';
    } else {
        startBtn.style.display = 'none';
    }
}

// Create lobby
function createLobby() {
    const formData = {
        name: document.getElementById('lobbyNameInput').value.trim(),
        mapIndex: parseInt(document.getElementById('mapSelect').value),
        weaponIndex: parseInt(document.getElementById('weaponSelect').value),
        maxPlayers: parseInt(document.getElementById('maxPlayersInput').value)
    };
    
    // Validation
    if (!formData.name) {
        showNotification('Please enter a lobby name', 'error');
        return;
    }
    
    if (!formData.mapIndex || !formData.weaponIndex) {
        showNotification('Please select map and weapons', 'error');
        return;
    }
    
    if (formData.maxPlayers < 2 || formData.maxPlayers > 16) {
        showNotification('Max players must be between 2 and 16', 'error');
        return;
    }
    
    // Send to client
    fetch(`https://${GetParentResourceName()}/createLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
    });
    
    closeMenu();
}

// Join lobby
function joinLobby(lobbyId) {
    fetch(`https://${GetParentResourceName()}/joinLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ lobbyId: lobbyId })
    });
    
    closeMenu();
}

// Leave lobby
function leaveLobby() {
    fetch(`https://${GetParentResourceName()}/leaveLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
    
    closeMenu();
}

// Start game
function startGame() {
    fetch(`https://${GetParentResourceName()}/startGame`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
    
    closeMenu();
}

// Refresh lobbies
function refreshLobbies() {
    document.getElementById('lobbiesList').innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner fa-spin"></i>
            Loading lobbies...
        </div>
    `;
    
    fetch(`https://${GetParentResourceName()}/getLobbies`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Display lobbies list
function displayLobbies(lobbies) {
    const container = document.getElementById('lobbiesList');
    
    if (!lobbies || lobbies.length === 0) {
        container.innerHTML = `
            <div class="no-lobbies">
                <i class="fas fa-exclamation-triangle"></i>
                <h3>No lobbies available</h3>
                <p>Create a new lobby to get started!</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = '';
    
    lobbies.forEach(lobby => {
        const lobbyCard = document.createElement('div');
        lobbyCard.className = 'lobby-card';
        lobbyCard.onclick = () => joinLobby(lobby.id);
        
        lobbyCard.innerHTML = `
            <h4>${escapeHtml(lobby.name)}</h4>
            <div class="lobby-card-info">
                <span>Creator: <strong>${escapeHtml(lobby.creator)}</strong></span>
                <span>Players: <strong>${lobby.players}/${lobby.maxPlayers}</strong></span>
                <span>Map: <strong>${escapeHtml(lobby.map)}</strong></span>
                <span>Weapons: <strong>${escapeHtml(lobby.weapons)}</strong></span>
            </div>
        `;
        
        container.appendChild(lobbyCard);
    });
}

// Show leaderboard
function showLeaderboard(data) {
    document.getElementById('playerKills').textContent = data.playerKills || 0;
    document.getElementById('playerDeaths').textContent = data.playerDeaths || 0;
    
    const leaderboardList = document.getElementById('leaderboardList');
    leaderboardList.innerHTML = '';
    
    if (!data.leaderboard || data.leaderboard.length === 0) {
        leaderboardList.innerHTML = '<div class="no-lobbies"><p>No players in lobby</p></div>';
        document.getElementById('leaderboard').style.display = 'block';
        return;
    }
    
    data.leaderboard.forEach((player, index) => {
        const entry = document.createElement('div');
        entry.className = `leaderboard-entry rank-${index + 1}`;
        
        if (index < 3) {
            entry.classList.add(`rank-${index + 1}`);
        }
        
        entry.innerHTML = `
            <div class="player-info">
                <div class="rank">${index + 1}</div>
                <span class="player-name">${escapeHtml(player.name)}</span>
            </div>
            <div class="player-kills">${player.kills}</div>
        `;
        
        leaderboardList.appendChild(entry);
    });
    
    document.getElementById('leaderboard').style.display = 'block';
}

// Close leaderboard
function closeLeaderboard() {
    document.getElementById('leaderboard').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeLeaderboard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Helper functions
function getCurrentPlayerId() {
    // This would need to be passed from the client
    return window.currentPlayerId || 0;
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas ${getNotificationIcon(type)}"></i>
        <span>${escapeHtml(message)}</span>
    `;
    
    // Style notification
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getNotificationColor(type)};
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        gap: 10px;
        z-index: 10000;
        animation: slideIn 0.3s ease-out;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-out';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

function getNotificationIcon(type) {
    switch(type) {
        case 'success': return 'fa-check-circle';
        case 'error': return 'fa-exclamation-circle';
        case 'warning': return 'fa-exclamation-triangle';
        default: return 'fa-info-circle';
    }
}

function getNotificationColor(type) {
    switch(type) {
        case 'success': return 'linear-gradient(135deg, #10b981 0%, #059669 100%)';
        case 'error': return 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)';
        case 'warning': return 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)';
        default: return 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'nl_ffa';
}

// CSS for notifications
const notificationStyles = document.createElement('style');
notificationStyles.textContent = `
    @keyframes slideIn {
        from {
            opacity: 0;
            transform: translateX(100%);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }
    
    @keyframes slideOut {
        from {
            opacity: 1;
            transform: translateX(0);
        }
        to {
            opacity: 0;
            transform: translateX(100%);
        }
    }
`;
document.head.appendChild(notificationStyles);