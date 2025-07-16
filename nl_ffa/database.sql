-- Optional SQL script for persistent lobby storage
-- Only needed if Config.UseDatabase = true in shared/config.lua

CREATE TABLE IF NOT EXISTS `ffa_lobbies` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `creator` int(11) NOT NULL,
    `map_index` int(11) NOT NULL,
    `weapon_index` int(11) NOT NULL,
    `max_players` int(11) NOT NULL,
    `players` json NOT NULL,
    `status` enum('waiting','starting','active') DEFAULT 'waiting',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ffa_player_inventories` (
    `player_id` int(11) NOT NULL,
    `inventory_data` json NOT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional: Stats tracking table
CREATE TABLE IF NOT EXISTS `ffa_player_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_id` varchar(50) NOT NULL,
    `player_name` varchar(255) NOT NULL,
    `total_kills` int(11) DEFAULT 0,
    `total_deaths` int(11) DEFAULT 0,
    `games_played` int(11) DEFAULT 0,
    `last_played` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;