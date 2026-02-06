-- ============================================================
-- Configuration
-- ============================================================

local CONFIG = {
    maxDistance = 500,
    fadeDistance = 100,
    fontName = "DarkRPHUD2",
    fontSize = 23,
    headOffset = 10,
    screenYOffset = -50,
    lineSpacing = 20
}

local PROFESSIONS = {
    ["Cop"] = {
        color = Color(0, 0, 255),
        models = {
            "models/player/kerry/policeru_01_patrol.mdl",
            "models/player/kerry/policeru_02_patrol.mdl",
            "models/player/kerry/policeru_03_patrol.mdl",
            "models/player/kerry/policeru_04_patrol.mdl",
            "models/player/kerry/policeru_05_patrol.mdl",
            "models/player/kerry/policeru_06_patrol.mdl",
            "models/player/kerry/policeru_07_patrol.mdl"
        }
    },
    ["Drug Dealer"] = {
        color = Color(127, 63, 63),
        models = {"models/player/arctic.mdl"}
    },
    ["John Rambo"] = {
        color = Color(127, 0, 0),
        models = {"models/player/guerilla.mdl"}
    },
    ["Police Officer"] = {
        color = Color(0, 128, 255),
        models = {
            "models/player/kerry/policeru_01.mdl",
            "models/player/kerry/police_01_female.mdl"
        }
    }
}

local RANDOM_PROFESSIONS = {
    "Surgeon", "Alcoholic", "Hitchhiker", "Cook", "Artist", "Conductor", "Layabout", "Model",
    "Spiritual Mentor", "Biologist", "Lawyer", "Firefighter", "Banker", "Flight Attendant",
    "Businesswoman", "Chess Player", "TV Host", "Diplomat", "Judge", "Disinformant", "Writer",
    "Psychotherapist", "Stripper", "Sadist", "Astronaut", "Satanist", "Waste Sorter",
    "Philosopher", "Hairdresser", "Journalist", "Salesperson", "Astrologer", "Dancer",
    "Photographer", "Prosecutor", "Hunter", "Worker", "Director", "Impresario", "Marine",
    "Cyberpunk", "Filthy", "Veterinarian", "Mining Engineer", "Teacher", "Theater Critic",
    "Fortune Teller", "Computer Specialist", "Sommelier", "Call Girl", "Metallurgist",
    "Taekwondo Master", "Football Player", "Hockey Player", "Cosplayer", "Clown", "Doctor",
    "Singer", "Stylist", "Pharmacist", "Architect", "Loader", "Psychologist", "Giant of Thought",
    "Accountant", "Cynologist", "Rapper", "Sniper", "Pathologist", "Carpenter", "Masseur",
    "Spy", "Rescuer", "Consultant"
}

-- ============================================================
-- Data structures
-- ============================================================

local playerModelMap = {}

for profession, data in pairs(PROFESSIONS) do
    for _, model in ipairs(data.models) do
        playerModelMap[model] = {
            team = profession,
            color = data.color
        }
    end
end

-- ============================================================
-- Client initialization
-- ============================================================

if CLIENT then
    surface.CreateFont(CONFIG.fontName, {
        font = "Roboto",
        size = CONFIG.fontSize,
        weight = 400,
        antialias = true,
        shadow = false,
        extended = true
    })
end

-- ============================================================
-- Server-side profession management
-- ============================================================

if SERVER then
    local function assignRandomProfession(ply)
        if not IsValid(ply) then return end

        local model = ply:GetModel()
        if playerModelMap[model] then return end

        if ply:GetNWString("RandomProfession", "") == "" then
            local profession = RANDOM_PROFESSIONS[math.random(#RANDOM_PROFESSIONS)]
            local color = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))

            ply:SetNWString("RandomProfession", profession)
            ply:SetNWInt("RandomColorR", color.r)
            ply:SetNWInt("RandomColorG", color.g)
            ply:SetNWInt("RandomColorB", color.b)
        end
    end

    local function clearProfessionData(ply)
        ply:SetNWString("RandomProfession", "")
        ply:SetNWInt("RandomColorR", 0)
        ply:SetNWInt("RandomColorG", 0)
        ply:SetNWInt("RandomColorB", 0)
    end

    hook.Add("PlayerInitialSpawn", "RPI_AssignProfessionInitial", assignRandomProfession)

    hook.Add("PlayerSpawn", "RPI_AssignProfessionSpawn", assignRandomProfession)

    hook.Add("PlayerSetModel", "RPI_ReassignProfession", function(ply)
        clearProfessionData(ply)
        assignRandomProfession(ply)
    end)

    hook.Add("Initialize", "RPI_InitExistingPlayers", function()
        for _, ply in ipairs(player.GetAll()) do
            assignRandomProfession(ply)
        end
    end)
end

-- ============================================================
-- Client-side rendering
-- ============================================================

if CLIENT then
    local playerDataCache = {}

    -- Pre-allocated reusable objects to avoid per-frame allocations
    local shadowColor = Color(0, 0, 0, 255)
    local tempColor = Color(0, 0, 0, 255)
    local whiteColor = Color(255, 255, 255, 255)
    local traceData = {start = Vector(), endpos = Vector(), filter = {}}

    local function drawShadowedText(text, font, x, y, color, alignX, alignY)
        shadowColor.a = color.a
        draw.SimpleText(text, font, x + 1, y + 1, shadowColor, alignX, alignY)
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
    end

    local function getPlayerInfo(ply)
        local model = ply:GetModel()
        local info = playerModelMap[model]

        if info then
            playerDataCache[ply] = nil
            return info
        end

        local profession = ply:GetNWString("RandomProfession", "")
        if profession == "" then return nil end

        local cached = playerDataCache[ply]
        if not cached or cached.model ~= model then
            playerDataCache[ply] = {
                team = profession,
                color = Color(
                    ply:GetNWInt("RandomColorR", 255),
                    ply:GetNWInt("RandomColorG", 255),
                    ply:GetNWInt("RandomColorB", 255)
                ),
                model = model
            }
        end

        return playerDataCache[ply]
    end

    local function isVisible(localEyePos, targetPos, localPlayer, ply)
        traceData.start = localEyePos
        traceData.endpos = targetPos
        traceData.filter[1] = localPlayer
        traceData.filter[2] = ply

        local trace = util.TraceLine(traceData)
        return not trace.Hit
    end

    local function calculateAlpha(distance)
        if distance > CONFIG.maxDistance - CONFIG.fadeDistance then
            return math.Clamp((CONFIG.maxDistance - distance) / CONFIG.fadeDistance * 255, 0, 255)
        end
        return 255
    end

    -- Clean up cache on player disconnect to prevent memory leaks
    hook.Add("EntityRemoved", "RPI_ClearCache", function(ent)
        if ent:IsPlayer() then
            playerDataCache[ent] = nil
        end
    end)

    local screenW, screenH = ScrW(), ScrH()

    hook.Add("OnScreenSizeChanged", "RPI_UpdateScreenSize", function()
        screenW, screenH = ScrW(), ScrH()
    end)

    hook.Add("HUDPaint", "RPI_DrawPlayerInfo", function()
        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end

        local localEyePos = localPlayer:EyePos()

        for _, ply in ipairs(player.GetAll()) do
            if ply == localPlayer then continue end
            if not IsValid(ply) or not ply:Alive() then continue end
            if ply.buildmode or ply:GetNWBool("isGhost") then continue end

            local plyEyePos = ply:EyePos()
            local distance = localEyePos:Distance(plyEyePos)

            if distance > CONFIG.maxDistance then continue end
            if not isVisible(localEyePos, plyEyePos, localPlayer, ply) then continue end

            local playerInfo = getPlayerInfo(ply)
            if not playerInfo or not playerInfo.team then continue end

            local pos = plyEyePos + Vector(0, 0, CONFIG.headOffset)
            pos = pos:ToScreen()
            pos.y = pos.y + CONFIG.screenYOffset

            if pos.x < 0 or pos.y < 0 or pos.x > screenW or pos.y > screenH then
                continue
            end

            local alpha = calculateAlpha(distance)

            tempColor.r = playerInfo.color.r
            tempColor.g = playerInfo.color.g
            tempColor.b = playerInfo.color.b
            tempColor.a = alpha
            whiteColor.a = alpha

            drawShadowedText(ply:Nick(), CONFIG.fontName, pos.x, pos.y, tempColor, TEXT_ALIGN_CENTER)
            drawShadowedText(string.format("Health: %d", math.max(0, ply:Health())), CONFIG.fontName, pos.x, pos.y + CONFIG.lineSpacing, whiteColor, TEXT_ALIGN_CENTER)
            drawShadowedText(playerInfo.team, CONFIG.fontName, pos.x, pos.y + CONFIG.lineSpacing * 2, tempColor, TEXT_ALIGN_CENTER)
        end
    end)
end
