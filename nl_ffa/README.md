# NL FFA Script

A comprehensive Free For All (FFA) script for FiveM with lobby system, leaderboards, and automatic inventory management.

## Features

- **NPC Interaction**: Talk to an NPC using ox_target to access the FFA system
- **Lobby System**: Create and join lobbies with custom settings
- **Map Selection**: Choose from multiple predefined combat areas
- **Weapon Selection**: Various weapon loadouts (Pistol, SMG, Rifle, Sniper, Mixed)
- **Player Limits**: Set lobby capacity from 2-16 players
- **Automatic Inventory Management**: Backs up and restores player inventory
- **Respawn System**: 5-second wait time, then respawn at random locations
- **Kill Tracking**: Real-time kill/death statistics
- **Leaderboard**: Press G to view top players in your lobby
- **Auto-cleanup**: Lobbies automatically delete when empty

## Dependencies

- **ox_lib**: Modern UI and notifications
- **ox_target**: NPC interaction system
- **oxmysql**: Database operations (optional)

## Installation

1. Download the `nl_ffa` folder to your resources directory
2. Add `ensure nl_ffa` to your server.cfg
3. Make sure dependencies are installed and started before nl_ffa
4. Restart your server

## Configuration

Edit `shared/config.lua` to customize:

- **NPC Location**: Change the coordinates where the FFA NPC spawns
- **Maps**: Add/modify combat areas with spawn points
- **Weapons**: Customize weapon loadouts and ammo amounts
- **Game Settings**: Adjust player limits, countdown times, respawn delays
- **Theme**: Modify UI colors and styling

## Usage

### For Players

1. **Access the System**: Go to the NPC (default: Legion Square) and interact with ox_target
2. **Create a Lobby**: 
   - Click "Create Lobby"
   - Enter lobby name
   - Select map and weapons
   - Set max players
   - Click "Create Lobby"
3. **Join a Lobby**:
   - Click "Join Lobby"
   - Select from available lobbies
   - Click on desired lobby to join
4. **Start Game** (Lobby Creator only):
   - Click "Start Game" when ready
   - All players will get a countdown
   - Fight begins after countdown ends
5. **In-Game**:
   - Press `G` to view leaderboard
   - Use `/leavelobby` command to exit
   - Automatically respawn after death

### Commands

- `/leavelobby` - Leave current lobby and restore inventory

### Keybinds

- `G` - Toggle leaderboard (only in active games)

## Game Flow

1. **Lobby Creation**: Creator sets up lobby with desired settings
2. **Waiting for Players**: Others can join until lobby is full
3. **Game Start**: Creator initiates countdown (default: 10 seconds)
4. **Combat Phase**: 
   - Players spawn with selected weapons
   - Kill tracking begins
   - Automatic respawn after death
5. **End Game**: Players can leave anytime with `/leavelobby`

## Technical Details

### Inventory Management
- Automatically backs up player inventory when game starts
- Clears inventory and gives combat weapons
- Restores original inventory when leaving lobby

### Respawn System
- 5-second death timer (configurable)
- Random spawn point selection within map boundaries
- Temporary invincibility after respawn
- Weapon/health restoration

### Lobby Management
- Real-time player count updates
- Automatic creator reassignment if original creator leaves
- Server-side validation for all actions
- Memory cleanup when lobbies are empty

## Customization

### Adding New Maps

Edit `Config.Maps` in `shared/config.lua`:

```lua
{
    name = "Your Map Name",
    spawns = {
        vector3(x1, y1, z1),
        vector3(x2, y2, z2),
        -- Add 6-8 spawn points for best experience
    },
    center = vector3(centerX, centerY, centerZ),
    radius = 50.0 -- Combat area radius
}
```

### Adding New Weapons

Edit `Config.Weapons` in `shared/config.lua`:

```lua
{
    name = "Your Weapon Set",
    weapons = {"WEAPON_HASH1", "WEAPON_HASH2"},
    ammo = 200 -- Total ammo per weapon
}
```

### Styling the UI

Modify `ui/style.css` to change colors, fonts, and layout.

## Troubleshooting

### Common Issues

1. **NPC not appearing**: Check coordinates in config.lua
2. **UI not opening**: Ensure ox_lib is installed and started
3. **Target not working**: Verify ox_target dependency
4. **Inventory issues**: Check your server's inventory system compatibility

### Debug Mode

Enable debug mode in `shared/config.lua`:
```lua
Config.Debug = true
```

This will show console messages for troubleshooting.

## Support

For issues or questions, join our Discord server: https://discord.gg/0resmon

## Credits

Created by 0Resmon for the FiveM community.

## License

This script is provided free for use in FiveM servers. Redistribution for commercial purposes is not permitted.