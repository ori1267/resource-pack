Config = {}

-- General Settings
Config.Locale = "en"
Config.Debug = false

-- NPC Settings
Config.NPC = {
    model = "s_m_y_dealer_01",
    coords = vector4(213.32, -810.77, 30.73, 160.0), -- Legion Square
    label = "FFA Manager",
    icon = "fas fa-gun"
}

-- Database Settings (if using persistent lobbies)
Config.UseDatabase = false

-- Maps Configuration
Config.Maps = {
    {
        name = "Sandy Shores Airfield",
        spawns = {
            vector3(1747.52, 3273.43, 41.15),
            vector3(1744.11, 3266.85, 41.15),
            vector3(1738.31, 3283.29, 41.15),
            vector3(1751.71, 3280.12, 41.15),
            vector3(1754.89, 3286.94, 41.15),
            vector3(1741.44, 3276.52, 41.15),
            vector3(1765.33, 3278.88, 41.15),
            vector3(1759.12, 3291.44, 41.15)
        },
        center = vector3(1750.0, 3280.0, 41.0),
        radius = 50.0
    },
    {
        name = "Construction Site",
        spawns = {
            vector3(-159.13, -1638.99, 34.03),
            vector3(-162.45, -1631.82, 34.03),
            vector3(-155.78, -1629.34, 34.03),
            vector3(-151.33, -1635.88, 34.03),
            vector3(-148.92, -1642.11, 34.03),
            vector3(-164.55, -1645.77, 34.03),
            vector3(-169.22, -1639.43, 34.03),
            vector3(-157.89, -1646.22, 34.03)
        },
        center = vector3(-158.0, -1638.0, 34.0),
        radius = 30.0
    },
    {
        name = "Del Perro Pier",
        spawns = {
            vector3(-1850.12, -1231.45, 13.02),
            vector3(-1847.33, -1224.78, 13.02),
            vector3(-1841.44, -1228.91, 13.02),
            vector3(-1838.67, -1235.23, 13.02),
            vector3(-1855.78, -1238.44, 13.02),
            vector3(-1852.91, -1242.67, 13.02),
            vector3(-1844.23, -1245.11, 13.02),
            vector3(-1859.45, -1227.88, 13.02)
        },
        center = vector3(-1850.0, -1235.0, 13.0),
        radius = 40.0
    }
}

-- Weapons Configuration
Config.Weapons = {
    {
        name = "Pistol",
        weapons = {"WEAPON_PISTOL"},
        ammo = 120
    },
    {
        name = "SMG",
        weapons = {"WEAPON_SMG"},
        ammo = 240
    },
    {
        name = "Rifle",
        weapons = {"WEAPON_ASSAULTRIFLE"},
        ammo = 180
    },
    {
        name = "Sniper",
        weapons = {"WEAPON_SNIPERRIFLE"},
        ammo = 60
    },
    {
        name = "Mixed",
        weapons = {"WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_ASSAULTRIFLE"},
        ammo = 150
    }
}

-- Game Settings
Config.Game = {
    minPlayers = 2,
    maxPlayers = 16,
    countdownTime = 10, -- seconds before game starts
    respawnTime = 5, -- seconds to wait before respawn after death
    defaultHP = 200,
    defaultArmor = 100
}

-- Commands
Config.Commands = {
    leavelobby = "leavelobby"
}

-- Keybinds
Config.Keys = {
    leaderboard = "G"
}

-- UI Theme
Config.Theme = {
    primary = "#3b82f6",
    secondary = "#1f2937",
    success = "#10b981",
    danger = "#ef4444",
    warning = "#f59e0b"
}