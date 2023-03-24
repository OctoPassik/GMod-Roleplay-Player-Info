RunConsoleCommand("cl_updaterate 66")

local function loadFonts()
    surface.CreateFont("DarkRPHUD2", {
        size = 23,
        weight = 400,
        antialias = true,
        shadow = false,
        font = "Roboto",
        extended = true,
    })
end

loadFonts()

local Professions = {
    ["Cop"] = {
        color = Color(0, 0, 255),
        models = {"models/player/kerry/policeru_01_patrol.mdl", "models/player/kerry/policeru_02_patrol.mdl", "models/player/kerry/policeru_03_patrol.mdl", "models/player/kerry/policeru_04_patrol.mdl", "models/player/kerry/policeru_05_patrol.mdl", "models/player/kerry/policeru_06_patrol.mdl", "models/player/kerry/policeru_07_patrol.mdl"}
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
        models = {"models/player/kerry/policeru_01.mdl", "models/player/kerry/police_01_female.mdl"}
    }
}

-- Create PlayerModels table for easy access to profession information
local PlayerModels = {}

for profession, info in pairs(Professions) do
    for _, model in ipairs(info.models) do
        PlayerModels[model] = {
            team = profession,
            color = info.color
        }
    end
end

local maxDistance = 500 -- Set the maximum distance at which information will be visible
local fadeDistance = 100 -- Set the distance at which information will fade

local function drawShadowedText(text, font, x, y, color, alignX, alignY)
    draw.DrawText(text, font, x + 1, y + 1, Color(0, 0, 0, color.a), alignX, alignY)
    draw.DrawText(text, font, x, y, color, alignX, alignY)
end

local playerDataCache = {}

local function getRandomColor()
    return Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
end

local function getRandomProfession()
    local professions = {"Surgeon", "Alcoholic", "Hitchhiker", "Cook", "Artist", "Conductor", "Layabout", "Model", "Spiritual Mentor", "Biologist", "Lawyer", "Firefighter", "Banker", "Flight Attendant", "Businesswoman", "Chess Player", "TV Host", "Diplomat", "Judge", "Disinformant", "Writer", "Psychotherapist", "Stripper", "Sadist", "Astronaut", "Satanist", "Waste Sorter", "Philosopher", "Hairdresser", "Journalist", "Salesperson", "Astrologer", "Dancer", "Photographer", "Prosecutor", "Hunter", "Worker", "Director", "Impresario", "Marine", "Cyberpunk", "Filthy", "Veterinarian", "Mining Engineer", "Teacher", "Theater Critic", "Fortune Teller", "Computer Specialist", "Sommelier", "Call Girl", "Metallurgist", "Taekwondo Master", "Football Player", "Hockey Player", "Cosplayer", "Clown", "Doctor", "Singer", "Stylist", "Pharmacist", "Architect", "Loader", "Psychologist", "Giant of Thought", "Accountant", "Cynologist", "Rapper", "Sniper", "Pathologist", "Lawyer", "Carpenter", "Masseur", "Spy", "Rescuer", "Consultant"}

    return professions[math.random(#professions)]
end

local function clearCacheIfModelChanged(ply)
    local currentModel = ply:GetModel()
    local cachedModel = playerDataCache[ply] and playerDataCache[ply].model

    if cachedModel and cachedModel ~= currentModel then
        playerDataCache[ply] = nil
    end
end

hook.Add("HUDPaint", "DrawPlayerInfo", function()
    local localPlayer = LocalPlayer()
    local screenWidth, screenHeight = ScrW(), ScrH()

    for _, ply in ipairs(player.GetAll()) do
        clearCacheIfModelChanged(ply)
        if not ply:Alive() or ply.buildmode or ply:GetNWBool("isGhost") then continue end
        local customJob = ply:GetNWString("CustomJob", "")
        local profession = customJob ~= "" and customJob or ply:GetNWString("profession", "Unknown")
        local professionColor = Color(255, 255, 255)
        local model = ply:GetModel()
        local playerInfo = PlayerModels[model]

        if not playerInfo then
            if not playerDataCache[ply] then
                playerDataCache[ply] = {
                    team = getRandomProfession(),
                    color = getRandomColor()
                }
            end

            playerInfo = playerDataCache[ply]
        end

        if playerInfo then
            local plyPos = ply:GetPos()
            local localPos = localPlayer:GetPos()
            local distance = localPos:Distance(plyPos)
            if distance > maxDistance then continue end

            local traceData = {
                start = localPos,
                endpos = plyPos,
                filter = {localPlayer, ply}
            }

            local trace = util.TraceLine(traceData)
            if trace.HitWorld then continue end

            -- Check if the player is in the field of view
            -- Check if the player is in the field of view
            local eyeTrace = util.TraceLine({
                start = localPlayer:EyePos(),
                endpos = plyPos,
                filter = {localPlayer, ply}
            })

            if eyeTrace.Hit and ply ~= localPlayer then continue end
            local pos = ply:EyePos()
            pos.z = pos.z + 10
            pos = pos:ToScreen()
            pos.y = pos.y - 50
            if pos.x < 0 or pos.y < 0 or pos.x > screenWidth or pos.y > screenHeight then continue end
            local alpha = 255

            if distance > maxDistance - fadeDistance then
                alpha = math.Clamp((maxDistance - distance) / fadeDistance * 255, 0, 255)
            end

            local plyTeam = playerInfo.team
            local plyColor = Color(playerInfo.color.r, playerInfo.color.g, playerInfo.color.b, alpha)
            drawShadowedText(ply:Nick(), "DarkRPHUD2", pos.x, pos.y, plyColor, TEXT_ALIGN_CENTER)
            local health = "Health: " .. math.max(0, ply:Health())
            drawShadowedText(health, "DarkRPHUD2", pos.x, pos.y + 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
            drawShadowedText(plyTeam, "DarkRPHUD2", pos.x, pos.y + 40, plyColor, TEXT_ALIGN_CENTER)
        end
    end
end)