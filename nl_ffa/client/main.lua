local isInLobby = false
local currentLobby = nil
local playerInventory = nil
local isInGame = false
local killCount = 0
local deaths = 0
local respawnTimer = 0
local leaderboardOpen = false

-- Initialize the script
CreateThread(function()
    Wait(1000)
    CreateNPC()
    RegisterKeybinds()
    SetupTargeting()
end)

-- Create NPC for lobby interaction
function CreateNPC()
    local npc = Config.NPC
    
    -- Request model
    RequestModel(npc.model)
    while not HasModelLoaded(npc.model) do
        Wait(100)
    end
    
    -- Create ped
    local ped = CreatePed(4, npc.model, npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.coords.w, false, true)
    
    -- Configure ped
    SetEntityHeading(ped, npc.coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Set as mission entity to prevent despawn
    SetEntityAsMissionEntity(ped, true, true)
    
    if Config.Debug then
        print("^2[nl_ffa] NPC created at: " .. npc.coords.x .. ", " .. npc.coords.y .. ", " .. npc.coords.z)
    end
end

-- Setup ox_target interaction
function SetupTargeting()
    exports.ox_target:addModel(Config.NPC.model, {
        {
            name = 'ffa_npc',
            icon = Config.NPC.icon,
            label = Config.NPC.label,
            onSelect = function()
                if isInGame then
                    lib.notify({
                        title = 'FFA System',
                        description = 'You cannot access the menu while in a game!',
                        type = 'error'
                    })
                    return
                end
                OpenFFAMenu()
            end
        }
    })
end

-- Register keybinds
function RegisterKeybinds()
    -- Leaderboard toggle
    RegisterKeyMapping('ffa_leaderboard', 'Toggle FFA Leaderboard', 'keyboard', Config.Keys.leaderboard)
    RegisterCommand('ffa_leaderboard', function()
        if isInLobby and isInGame then
            ToggleLeaderboard()
        end
    end, false)
end

-- Open main FFA menu
function OpenFFAMenu()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openMenu",
        data = {
            maps = Config.Maps,
            weapons = Config.Weapons,
            gameSettings = Config.Game,
            isInLobby = isInLobby,
            currentLobby = currentLobby
        }
    })
end

-- Toggle leaderboard
function ToggleLeaderboard()
    leaderboardOpen = not leaderboardOpen
    
    if leaderboardOpen then
        TriggerServerEvent('nl_ffa:getLeaderboard', currentLobby.id)
    else
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "closeLeaderboard"
        })
    end
end

-- Backup player inventory
function BackupInventory()
    if GetResourceState('ox_inventory') == 'started' then
        -- Get inventory from ox_inventory
        TriggerServerEvent('nl_ffa:backupInventory')
    elseif GetResourceState('qb-inventory') == 'started' then
        -- Get inventory from qb-inventory
        TriggerServerEvent('nl_ffa:backupInventory')
    else
        -- Fallback for other inventory systems
        TriggerServerEvent('nl_ffa:backupInventory')
    end
end

-- Restore player inventory
function RestoreInventory()
    TriggerServerEvent('nl_ffa:restoreInventory')
end

-- Clear player inventory and weapons
function ClearInventory()
    RemoveAllPedWeapons(PlayerPedId(), true)
    TriggerServerEvent('nl_ffa:clearInventory')
end

-- Give weapons to player
function GiveWeapons(weaponSet)
    local playerPed = PlayerPedId()
    
    for _, weapon in ipairs(weaponSet.weapons) do
        GiveWeaponToPed(playerPed, GetHashKey(weapon), weaponSet.ammo, false, true)
    end
    
    -- Set health and armor
    SetEntityHealth(playerPed, Config.Game.defaultHP)
    SetPedArmour(playerPed, Config.Game.defaultArmor)
end

-- Respawn player at random spawn point
function RespawnPlayer()
    local playerPed = PlayerPedId()
    local map = Config.Maps[currentLobby.mapIndex]
    local spawnPoint = map.spawns[math.random(#map.spawns)]
    
    -- Teleport to spawn
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    
    -- Reset health and armor
    SetEntityHealth(playerPed, Config.Game.defaultHP)
    SetPedArmour(playerPed, Config.Game.defaultArmor)
    
    -- Give weapons again
    GiveWeapons(Config.Weapons[currentLobby.weaponIndex])
    
    -- Make player invincible for a moment
    SetEntityInvincible(playerPed, true)
    SetTimeout(3000, function()
        SetEntityInvincible(playerPed, false)
    end)
    
    lib.notify({
        title = 'FFA System',
        description = 'You have respawned!',
        type = 'success'
    })
end

-- Handle player death
function OnPlayerDeath()
    if not isInGame then return end
    
    deaths = deaths + 1
    
    lib.notify({
        title = 'FFA System',
        description = 'You died! Respawning in ' .. Config.Game.respawnTime .. ' seconds...',
        type = 'error'
    })
    
    -- Start respawn timer
    respawnTimer = Config.Game.respawnTime
    
    CreateThread(function()
        while respawnTimer > 0 do
            Wait(1000)
            respawnTimer = respawnTimer - 1
            
            if respawnTimer <= 0 then
                RespawnPlayer()
                break
            end
        end
    end)
end

-- Handle kill event
function OnPlayerKill()
    if not isInGame then return end
    
    killCount = killCount + 1
    TriggerServerEvent('nl_ffa:updateKills', currentLobby.id, killCount)
    
    lib.notify({
        title = 'FFA System',
        description = 'Kill confirmed! Total kills: ' .. killCount,
        type = 'success'
    })
end

-- Events from server
RegisterNetEvent('nl_ffa:joinedLobby', function(lobby)
    isInLobby = true
    currentLobby = lobby
    
    lib.notify({
        title = 'FFA System',
        description = 'Joined lobby: ' .. lobby.name,
        type = 'success'
    })
end)

RegisterNetEvent('nl_ffa:leftLobby', function()
    if isInGame then
        -- Restore inventory when leaving game
        RestoreInventory()
        isInGame = false
        
        -- Reset player state
        local playerPed = PlayerPedId()
        ClearPedTasksImmediately(playerPed)
        SetEntityHealth(playerPed, 200)
        SetPedArmour(playerPed, 0)
    end
    
    isInLobby = false
    currentLobby = nil
    killCount = 0
    deaths = 0
    
    lib.notify({
        title = 'FFA System',
        description = 'Left lobby',
        type = 'info'
    })
end)

RegisterNetEvent('nl_ffa:gameStarting', function(countdown)
    lib.notify({
        title = 'FFA System',
        description = 'Game starting in ' .. countdown .. ' seconds!',
        type = 'warning'
    })
end)

RegisterNetEvent('nl_ffa:gameStarted', function()
    isInGame = true
    
    -- Backup inventory
    BackupInventory()
    
    -- Clear current inventory
    ClearInventory()
    
    -- Teleport to map and give weapons
    local map = Config.Maps[currentLobby.mapIndex]
    local spawnPoint = map.spawns[math.random(#map.spawns)]
    local playerPed = PlayerPedId()
    
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    
    -- Give weapons
    GiveWeapons(Config.Weapons[currentLobby.weaponIndex])
    
    lib.notify({
        title = 'FFA System',
        description = 'Game started! Fight!',
        type = 'success'
    })
end)

RegisterNetEvent('nl_ffa:lobbyDeleted', function()
    if isInGame then
        RestoreInventory()
        isInGame = false
    end
    
    isInLobby = false
    currentLobby = nil
    killCount = 0
    deaths = 0
    
    lib.notify({
        title = 'FFA System',
        description = 'Lobby has been deleted',
        type = 'error'
    })
end)

RegisterNetEvent('nl_ffa:leaderboardData', function(leaderboard)
    if leaderboardOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "showLeaderboard",
            data = {
                leaderboard = leaderboard,
                playerKills = killCount,
                playerDeaths = deaths
            }
        })
    end
end)

RegisterNetEvent('nl_ffa:lobbiesList', function(lobbies)
    SendNUIMessage({
        action = "lobbiesList",
        data = lobbies
    })
end)

-- Original death detection as backup
CreateThread(function()
    while true do
        Wait(500)
        
        if isInGame then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) and respawnTimer == 0 then
                OnPlayerDeath()
            end
        end
    end
end)

-- Kill detection for other players
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local damage = args[5]
        local weapon = args[7]
        
        if isInGame and attacker == PlayerPedId() and IsPedAPlayer(victim) then
            local victimPlayerId = NetworkGetPlayerIndexFromPed(victim)
            if victimPlayerId ~= -1 and GetPlayerPed(victimPlayerId) ~= PlayerPedId() then
                -- Check if this damage killed the victim
                CreateThread(function()
                    Wait(100) -- Small delay to ensure death is registered
                    if IsEntityDead(victim) then
                        OnPlayerKill()
                    end
                end)
            end
        end
    end
end)

-- Additional death detection using health monitoring
CreateThread(function()
    local lastHealth = 0
    local wasAlive = true
    
    while true do
        Wait(250)
        
        if isInGame then
            local playerPed = PlayerPedId()
            local currentHealth = GetEntityHealth(playerPed)
            local isDead = IsEntityDead(playerPed)
            
            if wasAlive and isDead then
                OnPlayerDeath()
                wasAlive = false
            elseif not wasAlive and not isDead then
                wasAlive = true
            end
            
            lastHealth = currentHealth
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('createLobby', function(data, cb)
    TriggerServerEvent('nl_ffa:createLobby', data)
    cb('ok')
end)

RegisterNUICallback('joinLobby', function(data, cb)
    TriggerServerEvent('nl_ffa:joinLobby', data.lobbyId)
    cb('ok')
end)

RegisterNUICallback('leaveLobby', function(data, cb)
    TriggerServerEvent('nl_ffa:leaveLobby')
    cb('ok')
end)

RegisterNUICallback('startGame', function(data, cb)
    TriggerServerEvent('nl_ffa:startGame', currentLobby.id)
    cb('ok')
end)

RegisterNUICallback('getLobbies', function(data, cb)
    TriggerServerEvent('nl_ffa:getLobbies')
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeLeaderboard', function(data, cb)
    SetNuiFocus(false, false)
    leaderboardOpen = false
    cb('ok')
end)

-- Command to leave lobby
RegisterCommand(Config.Commands.leavelobby, function()
    if isInLobby then
        TriggerServerEvent('nl_ffa:leaveLobby')
    else
        lib.notify({
            title = 'FFA System',
            description = 'You are not in a lobby!',
            type = 'error'
        })
    end
end, false)