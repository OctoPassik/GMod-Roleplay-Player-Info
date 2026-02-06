# RolePlay Player Info Display

A Garry's Mod addon for DarkRP servers that displays player information (name, health, profession) above each player's head. Professions are assigned based on player models, with random assignment as a fallback for unrecognized models.

## Features

- **Overhead player info** — name, health, and profession displayed above each player
- **Model-based professions** — predefined professions tied to specific player models
- **Random fallback** — 70+ random professions with random colors for unrecognized models
- **Distance fade** — text smoothly fades out at range and disappears beyond max distance
- **Line-of-sight** — info only shown when the player is actually visible (raycasting)
- **DarkRP integration** — respects build mode and ghost states
- **Performance optimized** — client-side caching, pre-allocated objects, no per-frame allocations

## Installation

### Steam Workshop

Subscribe to the addon on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2952870974).

### Manual

1. Download or clone this repository
2. Copy the `darkrp_info_player` folder into your server's `garrysmod/addons/` directory
3. Restart the server

```
garrysmod/addons/
└── darkrp_info_player/
    └── lua/
        └── autorun/
            └── sh_jobs_public.lua
```

## Configuration

All settings are in the `CONFIG` table at the top of `sh_jobs_public.lua`:

```lua
local CONFIG = {
    maxDistance = 500,      -- Max distance (units) at which info is visible
    fadeDistance = 100,     -- Distance over which text fades out
    fontName = "DarkRPHUD2", -- Font identifier
    fontSize = 23,         -- Font size in pixels
    headOffset = 10,       -- Vertical offset above the player's head (units)
    screenYOffset = -50,   -- Screen-space Y offset
    lineSpacing = 20       -- Spacing between lines (pixels)
}
```

## Adding Custom Professions

To add a new profession tied to specific player models, edit the `PROFESSIONS` table:

```lua
local PROFESSIONS = {
    ["Cop"] = {
        color = Color(0, 0, 255),
        models = {
            "models/player/kerry/policeru_01_patrol.mdl",
            "models/player/kerry/policeru_02_patrol.mdl",
            -- add more models here
        }
    },
    -- Add your own:
    ["Medic"] = {
        color = Color(0, 255, 0),
        models = {
            "models/player/your_medic_model.mdl"
        }
    },
}
```

To add more random professions for players with unrecognized models, edit the `RANDOM_PROFESSIONS` table:

```lua
local RANDOM_PROFESSIONS = {
    "Surgeon", "Alcoholic", "Hitchhiker",
    -- add more here
}
```

## How It Works

**Server side:**
- On player spawn or model change, the server checks if the model matches a predefined profession
- If not, a random profession and random color are assigned via networked variables (`NWString` / `NWInt`)

**Client side:**
- Every frame, iterates over all players and checks distance + line-of-sight
- Renders name, health, and profession above visible players with shadow text for readability
- Caches profession data per player, invalidates on model change
- Cleans up cache on player disconnect

## Requirements

- **Garry's Mod** with a DarkRP-based gamemode (works on other gamemodes too, but DarkRP features like build mode and ghost detection won't apply)

## License

This project is provided as-is. Feel free to modify and use it on your servers.
