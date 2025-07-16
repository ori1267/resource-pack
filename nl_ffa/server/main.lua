local lobbies = {}
local playerData = {}
local lobbyIdCounter = 1

-- Initialize database if enabled
if Config.UseDatabase then
    CreateThread(function()
        MySQL.ready(function()
            MySQL.execute([[
                CREATE TABLE IF NOT EXISTS ffa_lobbies (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    creator INT NOT NULL,
                    map_index INT NOT NULL,
                    weapon_index INT NOT NULL,
                    max_players INT NOT NULL,
                    players JSON NOT NULL,
                    status ENUM('waiting', 'starting', 'active') DEFAULT 'waiting',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ]])
            
            MySQL.execute([[
                CREATE TABLE IF NOT EXISTS ffa_player_inventories (
                    player_id INT PRIMARY KEY,
                    inventory_data JSON NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            ]])
        end)
    end)
end

-- Helper functions
function GetPlayerIdentifier(source)
    local identifier = nil
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(id, "license:") then
            identifier = id
            break
        end
    end
    return identifier
end

function GetPlayerName(source)
    return GetPlayerName(source) or "Unknown"
end

function CreateLobby(source, data)
    local playerId = GetPlayerIdentifier(source)
    local playerName = GetPlayerName(source)
    
    -- Check if player is already in a lobby
    if playerData[source] and playerData[source].lobbyId then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'You are already in a lobby!',
            type = 'error'
        })
        return
    end
    
    -- Validate data
    if not data.name or not data.mapIndex or not data.weaponIndex or not data.maxPlayers then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Invalid lobby data!',
            type = 'error'
        })
        return
    end
    
    -- Create lobby
    local lobby = {
        id = lobbyIdCounter,
        name = data.name,
        creator = source,
        creatorId = playerId,
        creatorName = playerName,
        mapIndex = tonumber(data.mapIndex),
        weaponIndex = tonumber(data.weaponIndex),
        maxPlayers = tonumber(data.maxPlayers),
        players = {
            {
                source = source,
                id = playerId,
                name = playerName,
                kills = 0,
                deaths = 0
            }
        },
        status = 'waiting',
        createdAt = os.time()
    }
    
    lobbies[lobbyIdCounter] = lobby
    
    -- Set player data
    playerData[source] = {
        lobbyId = lobbyIdCounter,
        inventory = nil
    }
    
    lobbyIdCounter = lobbyIdCounter + 1
    
    TriggerClientEvent('nl_ffa:joinedLobby', source, lobby)
    
    if Config.Debug then
        print("^2[nl_ffa] Lobby created: " .. lobby.name .. " by " .. playerName)
    end
end

function JoinLobby(source, lobbyId)
    local playerId = GetPlayerIdentifier(source)
    local playerName = GetPlayerName(source)
    
    -- Check if player is already in a lobby
    if playerData[source] and playerData[source].lobbyId then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'You are already in a lobby!',
            type = 'error'
        })
        return
    end
    
    -- Check if lobby exists
    local lobby = lobbies[lobbyId]
    if not lobby then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Lobby not found!',
            type = 'error'
        })
        return
    end
    
    -- Check if lobby is full
    if #lobby.players >= lobby.maxPlayers then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Lobby is full!',
            type = 'error'
        })
        return
    end
    
    -- Check if lobby is not waiting
    if lobby.status ~= 'waiting' then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Game is already in progress!',
            type = 'error'
        })
        return
    end
    
    -- Add player to lobby
    table.insert(lobby.players, {
        source = source,
        id = playerId,
        name = playerName,
        kills = 0,
        deaths = 0
    })
    
    -- Set player data
    playerData[source] = {
        lobbyId = lobbyId,
        inventory = nil
    }
    
    TriggerClientEvent('nl_ffa:joinedLobby', source, lobby)
    
    -- Notify all players in lobby
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('lib:notify', player.source, {
            title = 'FFA System',
            description = playerName .. ' joined the lobby (' .. #lobby.players .. '/' .. lobby.maxPlayers .. ')',
            type = 'info'
        })
    end
    
    if Config.Debug then
        print("^2[nl_ffa] Player " .. playerName .. " joined lobby: " .. lobby.name)
    end
end

function LeaveLobby(source)
    local playerLobbyData = playerData[source]
    if not playerLobbyData or not playerLobbyData.lobbyId then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'You are not in a lobby!',
            type = 'error'
        })
        return
    end
    
    local lobby = lobbies[playerLobbyData.lobbyId]
    if not lobby then
        playerData[source] = nil
        return
    end
    
    local playerName = GetPlayerName(source)
    
    -- Remove player from lobby
    for i, player in ipairs(lobby.players) do
        if player.source == source then
            table.remove(lobby.players, i)
            break
        end
    end
    
    -- Clear player data
    playerData[source] = nil
    
    TriggerClientEvent('nl_ffa:leftLobby', source)
    
    -- Check if lobby is empty
    if #lobby.players == 0 then
        lobbies[playerLobbyData.lobbyId] = nil
        if Config.Debug then
            print("^1[nl_ffa] Lobby deleted: " .. lobby.name .. " (empty)")
        end
    else
        -- If creator left, assign new creator
        if lobby.creator == source then
            lobby.creator = lobby.players[1].source
            lobby.creatorId = lobby.players[1].id
            lobby.creatorName = lobby.players[1].name
            
            TriggerClientEvent('lib:notify', lobby.creator, {
                title = 'FFA System',
                description = 'You are now the lobby creator!',
                type = 'info'
            })
        end
        
        -- Notify remaining players
        for _, player in ipairs(lobby.players) do
            TriggerClientEvent('lib:notify', player.source, {
                title = 'FFA System',
                description = playerName .. ' left the lobby (' .. #lobby.players .. '/' .. lobby.maxPlayers .. ')',
                type = 'info'
            })
        end
    end
    
    if Config.Debug then
        print("^3[nl_ffa] Player " .. playerName .. " left lobby")
    end
end

function StartGame(source, lobbyId)
    local lobby = lobbies[lobbyId]
    if not lobby then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Lobby not found!',
            type = 'error'
        })
        return
    end
    
    -- Check if player is the creator
    if lobby.creator ~= source then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Only the lobby creator can start the game!',
            type = 'error'
        })
        return
    end
    
    -- Check minimum players
    if #lobby.players < Config.Game.minPlayers then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Not enough players! Need at least ' .. Config.Game.minPlayers .. ' players.',
            type = 'error'
        })
        return
    end
    
    -- Check if already starting/active
    if lobby.status ~= 'waiting' then
        TriggerClientEvent('lib:notify', source, {
            title = 'FFA System',
            description = 'Game is already starting or active!',
            type = 'error'
        })
        return
    end
    
    lobby.status = 'starting'
    
    -- Start countdown
    local countdown = Config.Game.countdownTime
    
    CreateThread(function()
        while countdown > 0 do
            -- Notify all players
            for _, player in ipairs(lobby.players) do
                TriggerClientEvent('nl_ffa:gameStarting', player.source, countdown)
            end
            
            Wait(1000)
            countdown = countdown - 1
        end
        
        -- Start the game
        lobby.status = 'active'
        
        for _, player in ipairs(lobby.players) do
            TriggerClientEvent('nl_ffa:gameStarted', player.source)
        end
        
        if Config.Debug then
            print("^2[nl_ffa] Game started in lobby: " .. lobby.name)
        end
    end)
end

function GetLobbies(source)
    local availableLobbies = {}
    
    for _, lobby in pairs(lobbies) do
        if lobby.status == 'waiting' and #lobby.players < lobby.maxPlayers then
            table.insert(availableLobbies, {
                id = lobby.id,
                name = lobby.name,
                creator = lobby.creatorName,
                players = #lobby.players,
                maxPlayers = lobby.maxPlayers,
                map = Config.Maps[lobby.mapIndex].name,
                weapons = Config.Weapons[lobby.weaponIndex].name
            })
        end
    end
    
    TriggerClientEvent('nl_ffa:lobbiesList', source, availableLobbies)
end

function GetLeaderboard(source, lobbyId)
    local lobby = lobbies[lobbyId]
    if not lobby then return end
    
    -- Sort players by kills
    local sortedPlayers = {}
    for _, player in ipairs(lobby.players) do
        table.insert(sortedPlayers, player)
    end
    
    table.sort(sortedPlayers, function(a, b)
        return a.kills > b.kills
    end)
    
    TriggerClientEvent('nl_ffa:leaderboardData', source, sortedPlayers)
end

function UpdateKills(source, lobbyId, kills)
    local lobby = lobbies[lobbyId]
    if not lobby then return end
    
    -- Find and update player
    for _, player in ipairs(lobby.players) do
        if player.source == source then
            player.kills = kills
            break
        end
    end
end

function BackupInventory(source)
    local playerLobbyData = playerData[source]
    if not playerLobbyData then return end
    
    -- This would integrate with your inventory system
    -- For now, we'll just mark that inventory was backed up
    playerLobbyData.inventory = "backed_up"
    
    if Config.Debug then
        print("^2[nl_ffa] Inventory backed up for player: " .. source)
    end
end

function RestoreInventory(source)
    local playerLobbyData = playerData[source]
    if not playerLobbyData or not playerLobbyData.inventory then return end
    
    -- This would integrate with your inventory system
    -- For now, we'll just clear the backup flag
    playerLobbyData.inventory = nil
    
    if Config.Debug then
        print("^2[nl_ffa] Inventory restored for player: " .. source)
    end
end

function ClearInventory(source)
    -- This would integrate with your inventory system
    -- For now, we'll just trigger a client event
    TriggerClientEvent('nl_ffa:inventoryCleared', source)
    
    if Config.Debug then
        print("^2[nl_ffa] Inventory cleared for player: " .. source)
    end
end

-- Events
RegisterNetEvent('nl_ffa:createLobby', CreateLobby)
RegisterNetEvent('nl_ffa:joinLobby', JoinLobby)
RegisterNetEvent('nl_ffa:leaveLobby', LeaveLobby)
RegisterNetEvent('nl_ffa:startGame', StartGame)
RegisterNetEvent('nl_ffa:getLobbies', GetLobbies)
RegisterNetEvent('nl_ffa:getLeaderboard', GetLeaderboard)
RegisterNetEvent('nl_ffa:updateKills', UpdateKills)
RegisterNetEvent('nl_ffa:backupInventory', BackupInventory)
RegisterNetEvent('nl_ffa:restoreInventory', RestoreInventory)
RegisterNetEvent('nl_ffa:clearInventory', ClearInventory)

-- Player disconnection handling
AddEventHandler('playerDropped', function()
    local source = source
    if playerData[source] then
        LeaveLobby(source)
    end
end)

-- Resource stop handling
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Restore inventories for all players
        for source, data in pairs(playerData) do
            if data.inventory then
                RestoreInventory(source)
            end
        end
    end
end)

if Config.Debug then
    print("^2[nl_ffa] Server initialized successfully")
end