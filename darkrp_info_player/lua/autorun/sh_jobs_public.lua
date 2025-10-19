-- ============================================================
-- Configuration
-- ============================================================

local CONFIG = {
    maxDistance = 500,
    fadeDistance = 100,
    fontName = "DarkRPHUD2",
    fontSize = 23,
    updateRate = "66"
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
-- Client initialization
-- ============================================================

if CLIENT then
    RunConsoleCommand("cl_updaterate", CONFIG.updateRate)

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
-- Data structures
-- ============================================================

local playerModelMap = {}
local playerDataCache = {}

for profession, data in pairs(PROFESSIONS) do
    for _, model in ipairs(data.models) do
        playerModelMap[model] = {
            team = profession,
            color = data.color
        }
    end
end

-- ============================================================
-- Server-side profession management
-- ============================================================

if SERVER then
    local function assignRandomProfession(ply)
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

    hook.Add("PlayerInitialSpawn", "RPI_AssignProfession", function(ply)
        assignRandomProfession(ply)
    end)

    hook.Add("PlayerSpawn", "RPI_AssignProfession", function(ply)
        assignRandomProfession(ply)
    end)

    hook.Add("PlayerSetModel", "RPI_ReassignProfession", function(ply)
        clearProfessionData(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                assignRandomProfession(ply)
            end
        end)
    end)

    timer.Simple(1, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                assignRandomProfession(ply)
            end
        end
    end)
end

-- ============================================================
-- Client-side rendering
-- ============================================================

if CLIENT then
    local function drawShadowedText(text, font, x, y, color, alignX, alignY)
        draw.DrawText(text, font, x + 1, y + 1, Color(0, 0, 0, color.a), alignX, alignY)
        draw.DrawText(text, font, x, y, color, alignX, alignY)
    end

    local function clearCacheIfModelChanged(ply)
        local currentModel = ply:GetModel()
        local cachedModel = playerDataCache[ply] and playerDataCache[ply].model

        if cachedModel and cachedModel ~= currentModel then
            playerDataCache[ply] = nil
        end
    end

    local function getPlayerInfo(ply)
        local model = ply:GetModel()
        local info = playerModelMap[model]

        if not info then
            local profession = ply:GetNWString("RandomProfession", "")
            if profession == "" then return nil end

            if not playerDataCache[ply] or playerDataCache[ply].model ~= model then
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

            info = playerDataCache[ply]
        end

        return info
    end

    local function shouldDrawPlayer(ply, localPlayer, distance)
        if not ply:Alive() or ply.buildmode or ply:GetNWBool("isGhost") then
            return false
        end

        if distance > CONFIG.maxDistance then
            return false
        end

        local plyPos = ply:GetPos()
        local localPos = localPlayer:GetPos()

        local trace = util.TraceLine({
            start = localPos,
            endpos = plyPos,
            filter = {localPlayer, ply}
        })

        if trace.HitWorld then
            return false
        end

        local eyeTrace = util.TraceLine({
            start = localPlayer:EyePos(),
            endpos = plyPos,
            filter = {localPlayer, ply}
        })

        if eyeTrace.Hit and ply ~= localPlayer then
            return false
        end

        return true
    end

    local function calculateAlpha(distance)
        if distance > CONFIG.maxDistance - CONFIG.fadeDistance then
            return math.Clamp((CONFIG.maxDistance - distance) / CONFIG.fadeDistance * 255, 0, 255)
        end
        return 255
    end

    hook.Add("HUDPaint", "RPI_DrawPlayerInfo", function()
        local localPlayer = LocalPlayer()
        local screenWidth, screenHeight = ScrW(), ScrH()

        for _, ply in ipairs(player.GetAll()) do
            clearCacheIfModelChanged(ply)

            local distance = localPlayer:GetPos():Distance(ply:GetPos())
            if not shouldDrawPlayer(ply, localPlayer, distance) then continue end

            local playerInfo = getPlayerInfo(ply)
            if not playerInfo or not playerInfo.team then continue end

            local pos = ply:EyePos()
            pos.z = pos.z + 10
            pos = pos:ToScreen()
            pos.y = pos.y - 50

            if pos.x < 0 or pos.y < 0 or pos.x > screenWidth or pos.y > screenHeight then
                continue
            end

            local alpha = calculateAlpha(distance)
            local color = Color(playerInfo.color.r, playerInfo.color.g, playerInfo.color.b, alpha)
            local whiteColor = Color(255, 255, 255, alpha)

            drawShadowedText(ply:Nick(), CONFIG.fontName, pos.x, pos.y, color, TEXT_ALIGN_CENTER)
            drawShadowedText("Health: " .. math.max(0, ply:Health()), CONFIG.fontName, pos.x, pos.y + 20, whiteColor, TEXT_ALIGN_CENTER)
            drawShadowedText(playerInfo.team, CONFIG.fontName, pos.x, pos.y + 40, color, TEXT_ALIGN_CENTER)
        end
    end)
end
