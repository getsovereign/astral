local Website = "https://gist.githubusercontent.com/getsovereign/26adce898bba431b840f4990e797d7d3/raw"
local Check = 5

local httpGet
if request then httpGet = function(url) return request({Url = url, Method = "GET"}).Body end
elseif httpget then httpGet = function(url) return httpget(url) end
elseif syn and syn.request then httpGet = function(url) return syn.request({Url = url, Method = "GET"}).Body end
elseif http and http.request then httpGet = function(url) return http.request({Url = url, Method = "GET"}).Body end
else error("No supported HTTP function found.") end

local function checkGist()
    local ok, body = pcall(httpGet, Website .. "?t=" .. tick())
    if not ok or not body then return nil end
    return body:lower()
end

local function kick()
    pcall(function() game.Players.LocalPlayer:Kick("You are on the list.") end)
    pcall(function() game:Shutdown() end)
end

task.spawn(function()
    while true do
        local body = checkGist()
        if body and body:match("yes") then
            kick()
            return
        end
        task.wait(Check)
    end
end)

-- Main script
local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local SilentAimEnabled = false
local TeamCheck = false
local WallCheck = false
local Prediction = false
local BulletDropCompensation = false
local HitPart = "Head"
local FieldOfView = 150

local ShowFieldOfView = false
local ShowTracer = false
local FieldOfViewColor = Color3.fromRGB(255, 255, 255)
local TracerColor = Color3.fromRGB(255, 255, 255)

local Window = Library:CreateWindow({
    Title = "Astral Solutions",
    Footer = "Brought to you by Astral Solutions",
    AutoShow = true,
    Resizable = false,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    World = Window:AddTab("World", "globe"),
    Misc = Window:AddTab("Misc", "package"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local TabBox = Tabs.Combat:AddLeftTabbox()
local Aimbot = TabBox:AddTab("Aimbot")
local Visual = TabBox:AddTab("Visual")

Aimbot:AddToggle("SilentAimEnabled", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(v) SilentAimEnabled = v end,
})

Aimbot:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(v) TeamCheck = v end,
})

Aimbot:AddToggle("WallCheck", {
    Text = "Wall Check",
    Default = false,
    Callback = function(v) WallCheck = v end,
})

Aimbot:AddToggle("Prediction", {
    Text = "Prediction",
    Default = false,
    Callback = function(v) Prediction = v end,
})

Aimbot:AddToggle("BulletDropCompensation", {
    Text = "Bullet Drop Compensation",
    Default = false,
    Callback = function(v) BulletDropCompensation = v end,
})

Aimbot:AddDropdown("HitPart", {
    Values = {"Head", "Torso", "HumanoidRootPart", "Random"},
    Default = "Head",
    Text = "Target Part",
    Callback = function(v) HitPart = v end,
})

Visual:AddToggle("ShowFieldOfView", {
    Text = "Show FOV",
    Default = false,
    Callback = function(v) ShowFieldOfView = v end,
}):AddColorPicker("FieldOfViewColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) FieldOfViewColor = v end,
})

Visual:AddToggle("ShowTracer", {
    Text = "Show Tracer",
    Default = false,
    Callback = function(v) ShowTracer = v end,
}):AddColorPicker("TracerColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) TracerColor = v end,
})

Visual:AddSlider("FieldOfView", {
    Text = "FOV Size",
    Default = 150,
    Min = 10,
    Max = 800,
    Rounding = 0,
    Callback = function(v) FieldOfView = v end,
})

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 2
SnapLine.Transparency = 1
SnapLine.Visible = false

local Esp = {
    Enabled = false,
    Box = false,
    Name = false,
    Distance = false,
    Skeleton = false,
    TeamCheck = false,
    VisibleCheck = false,
    MaxDistance = 2000,
    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(255, 255, 255),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
}

local SkyboxEnabled = false
local SkyboxSelected = "None"
local SkyboxOriginal = nil

local SkyboxPresets = {
    ["Blue Sky"] = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"},
    Vaporwave = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"},
    Redshift = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"},
    Blaze = {"150939022", "150939038", "150939047", "150939056", "150939063", "150939082"},
    ["Dark Night"] = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"},
    ["Bright Pink"] = {"271042516", "271077243", "271042556", "271042310", "271042467", "271077958"},
    ["Purple Sky"] = {"570557514", "570557775", "570557559", "570557620", "570557672", "570557727"},
    Galaxy = {"15125283003", "15125281008", "15125277539", "15125279325", "15125274388", "15125275800"},
    ["Pinky Sky"] = {"11427769401", "11427770685", "11427769401", "11427769401", "11427769401", "11427771954"},
}

do
    local existing = Lighting:FindFirstChildOfClass("Sky")
    if existing then
        SkyboxOriginal = existing:Clone()
        SkyboxOriginal.Name = "_original_sky"
    end
end

local function ApplySkybox(name)
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") and child.Name ~= "_original_sky" then
            child:Destroy()
        end
    end
    local ids = SkyboxPresets[name]
    if not ids then
        if SkyboxOriginal then
            local clone = SkyboxOriginal:Clone()
            clone.Name = "Sky"
            clone.Parent = Lighting
        end
        return
    end
    local sky = Instance.new("Sky")
    sky.Name = name
    sky.SkyboxBk = "rbxassetid://" .. ids[1]
    sky.SkyboxDn = "rbxassetid://" .. ids[2]
    sky.SkyboxFt = "rbxassetid://" .. ids[3]
    sky.SkyboxLf = "rbxassetid://" .. ids[4]
    sky.SkyboxRt = "rbxassetid://" .. ids[5]
    sky.SkyboxUp = "rbxassetid://" .. ids[6]
    sky.Parent = Lighting
end

local PlayerDrawings = {}

local R15Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "HumanoidRootPart"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local R6Bones = {
    {"Head", "Torso"}, {"Torso", "HumanoidRootPart"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local R15BodyParts = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local R6BodyParts = {
    "Head", "Torso", "HumanoidRootPart",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local RigTypeCache = setmetatable({}, {__mode = "k"})
local function IsR6(char)
    local cached = RigTypeCache[char]
    if cached ~= nil then return cached end
    local r6 = char:FindFirstChild("Torso") ~= nil and char:FindFirstChild("UpperTorso") == nil
    RigTypeCache[char] = r6
    return r6
end

local RaycastParamsInstance = RaycastParams.new()
RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsInstance.IgnoreWater = true
local RaycastFilter = {nil, nil}

local function HasLineOfSight(origin, targetPosition, targetCharacter)
    local direction = targetPosition - origin
    local distance = direction.Magnitude
    if distance < 0.01 then return true end
    RaycastFilter[1] = LocalPlayer.Character
    RaycastFilter[2] = targetCharacter
    RaycastParamsInstance.FilterDescendantsInstances = RaycastFilter
    return workspace:Raycast(origin, direction.Unit * distance, RaycastParamsInstance) == nil
end

local function CreateEspForPlayer(player)
    if player == LocalPlayer or PlayerDrawings[player] then return end

    local drawings = {
        boxTopOutline = Drawing.new("Line"),
        boxBottomOutline = Drawing.new("Line"),
        boxLeftOutline = Drawing.new("Line"),
        boxRightOutline = Drawing.new("Line"),
        boxTop = Drawing.new("Line"),
        boxBottom = Drawing.new("Line"),
        boxLeft = Drawing.new("Line"),
        boxRight = Drawing.new("Line"),
        nameText = Drawing.new("Text"),
        distanceText = Drawing.new("Text"),
        skeletonLines = {},
        skeletonOutlines = {},
    }

    for _, key in ipairs({"boxTopOutline", "boxBottomOutline", "boxLeftOutline", "boxRightOutline"}) do
        local line = drawings[key]
        line.Visible = false
        line.Color = Color3.new(0, 0, 0)
        line.Thickness = 3
        line.Transparency = 1
        line.ZIndex = 1
    end

    for _, key in ipairs({"boxTop", "boxBottom", "boxLeft", "boxRight"}) do
        local line = drawings[key]
        line.Visible = false
        line.Color = Esp.BoxColor
        line.Thickness = 1
        line.Transparency = 1
        line.ZIndex = 2
    end

    drawings.nameText.Visible = false
    drawings.nameText.Font = 2
    drawings.nameText.Size = 13
    drawings.nameText.Color = Esp.NameColor
    drawings.nameText.Outline = true
    drawings.nameText.OutlineColor = Color3.new(0, 0, 0)
    drawings.nameText.Center = true
    drawings.nameText.ZIndex = 3

    drawings.distanceText.Visible = false
    drawings.distanceText.Font = 2
    drawings.distanceText.Size = 13
    drawings.distanceText.Color = Esp.DistanceColor
    drawings.distanceText.Outline = true
    drawings.distanceText.OutlineColor = Color3.new(0, 0, 0)
    drawings.distanceText.Center = true
    drawings.distanceText.ZIndex = 3

    PlayerDrawings[player] = drawings
end

local function RemoveEspForPlayer(player)
    local drawings = PlayerDrawings[player]
    if not drawings then return end
    drawings.boxTopOutline:Remove()
    drawings.boxBottomOutline:Remove()
    drawings.boxLeftOutline:Remove()
    drawings.boxRightOutline:Remove()
    drawings.boxTop:Remove()
    drawings.boxBottom:Remove()
    drawings.boxLeft:Remove()
    drawings.boxRight:Remove()
    drawings.nameText:Remove()
    drawings.distanceText:Remove()
    for _, line in pairs(drawings.skeletonLines) do line:Remove() end
    for _, line in pairs(drawings.skeletonOutlines) do line:Remove() end
    PlayerDrawings[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do CreateEspForPlayer(player) end
Players.PlayerAdded:Connect(CreateEspForPlayer)
Players.PlayerRemoving:Connect(RemoveEspForPlayer)

local function GetBoundingBox(character, camera)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local bodyParts = IsR6(character) and R6BodyParts or R15BodyParts
    local hasAny = false

    for i = 1, #bodyParts do
        local part = character:FindFirstChild(bodyParts[i])
        if part and part:IsA("BasePart") then
            hasAny = true
            local size = part.Size * 0.5
            local cf = part.CFrame
            local cx, cy, cz = cf.X, cf.Y, cf.Z
            local rxv, ryv, rzv = cf.RightVector.X * size.X, cf.RightVector.Y * size.X, cf.RightVector.Z * size.X
            local uxv, uyv, uzv = cf.UpVector.X * size.Y, cf.UpVector.Y * size.Y, cf.UpVector.Z * size.Y
            local bxv, byv, bzv = cf.LookVector.X * size.Z, cf.LookVector.Y * size.Z, cf.LookVector.Z * size.Z

            local positions = {
                Vector3.new(cx - rxv - uxv - bxv, cy - ryv - uyv - byv, cz - rzv - uzv - bzv),
                Vector3.new(cx - rxv - uxv + bxv, cy - ryv - uyv + byv, cz - rzv - uzv + bzv),
                Vector3.new(cx - rxv + uxv - bxv, cy - ryv + uyv - byv, cz - rzv + uzv - bzv),
                Vector3.new(cx - rxv + uxv + bxv, cy - ryv + uyv + byv, cz - rzv + uzv + bzv),
                Vector3.new(cx + rxv - uxv - bxv, cy + ryv - uyv - byv, cz + rzv - uzv - bzv),
                Vector3.new(cx + rxv - uxv + bxv, cy + ryv - uyv + byv, cz + rzv - uzv + bzv),
                Vector3.new(cx + rxv + uxv - bxv, cy + ryv + uyv - byv, cz + rzv + uzv - bzv),
                Vector3.new(cx + rxv + uxv + bxv, cy + ryv + uyv + byv, cz + rzv + uzv + bzv),
            }

            for j = 1, 8 do
                local sp, on = camera:WorldToViewportPoint(positions[j])
                if on then
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
    end

    if not hasAny or minX == math.huge then return nil end
    return minX - 2, minY - 2, (maxX - minX) + 4, (maxY - minY) + 4, (minX + maxX) * 0.5
end

local function HideEsp(drawings)
    drawings.boxTopOutline.Visible = false
    drawings.boxBottomOutline.Visible = false
    drawings.boxLeftOutline.Visible = false
    drawings.boxRightOutline.Visible = false
    drawings.boxTop.Visible = false
    drawings.boxBottom.Visible = false
    drawings.boxLeft.Visible = false
    drawings.boxRight.Visible = false
    drawings.nameText.Visible = false
    drawings.distanceText.Visible = false
    for _, line in pairs(drawings.skeletonLines) do line.Visible = false end
    for _, line in pairs(drawings.skeletonOutlines) do line.Visible = false end
end

local EspAccumulator = 0
RunService.RenderStepped:Connect(function(deltaTime)
    EspAccumulator = EspAccumulator + deltaTime
    if EspAccumulator < 0.04 then return end
    EspAccumulator = 0

    if not Esp.Enabled then
        if next(PlayerDrawings) then
            for _, drawings in pairs(PlayerDrawings) do HideEsp(drawings) end
        end
        return
    end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not rootPart or not camera then return end

    local myTeam = LocalPlayer.Team
    local maxDistance = Esp.MaxDistance
    local maxDistanceSquared = maxDistance * maxDistance
    local rootPos = rootPart.Position
    local cameraPosition = camera.CFrame.Position
    local showBox = Esp.Box
    local showName = Esp.Name
    local showDistance = Esp.Distance
    local showSkeleton = Esp.Skeleton

    for player, drawings in pairs(PlayerDrawings) do
        local targetCharacter = player.Character
        local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

        if not (targetCharacter and targetRoot and targetHumanoid and targetHumanoid.Health > 0) then
            HideEsp(drawings)
            continue
        end

        if Esp.TeamCheck and myTeam and player.Team == myTeam then
            HideEsp(drawings)
            continue
        end

        local deltaX = targetRoot.Position.X - rootPos.X
        local deltaY = targetRoot.Position.Y - rootPos.Y
        local deltaZ = targetRoot.Position.Z - rootPos.Z
        local distanceSquared = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

        if distanceSquared > maxDistanceSquared then
            HideEsp(drawings)
            continue
        end

        if Esp.VisibleCheck then
            local head = targetCharacter:FindFirstChild("Head") or targetRoot
            if not HasLineOfSight(cameraPosition, head.Position, targetCharacter) then
                HideEsp(drawings)
                continue
            end
        end

        local bx, by, bw, bh, bcx = GetBoundingBox(targetCharacter, camera)
        if not bx then
            HideEsp(drawings)
            continue
        end

        local distance = math.sqrt(distanceSquared)
        local textSize = math.clamp(math.floor(400 / (distance ^ 0.45)), 12, 16)
        local boxThickness = math.clamp(math.floor(250 / distance), 1, 2)
        local outlineThickness = boxThickness + 1

        local minBoxDim = math.min(bw, bh)
        if outlineThickness > minBoxDim * 0.3 then
            outlineThickness = math.max(1, math.floor(minBoxDim * 0.3))
        end

        local x1, y1 = bx, by
        local x2, y2 = bx + bw, by + bh

        if showBox then
            local v1 = Vector2.new(x1, y1)
            local v2 = Vector2.new(x2, y1)
            local v3 = Vector2.new(x1, y2)
            local v4 = Vector2.new(x2, y2)

            drawings.boxTopOutline.From = v1
            drawings.boxTopOutline.To = v2
            drawings.boxTopOutline.Thickness = outlineThickness
            drawings.boxTopOutline.Visible = true
            drawings.boxBottomOutline.From = v3
            drawings.boxBottomOutline.To = v4
            drawings.boxBottomOutline.Thickness = outlineThickness
            drawings.boxBottomOutline.Visible = true
            drawings.boxLeftOutline.From = v1
            drawings.boxLeftOutline.To = v3
            drawings.boxLeftOutline.Thickness = outlineThickness
            drawings.boxLeftOutline.Visible = true
            drawings.boxRightOutline.From = v2
            drawings.boxRightOutline.To = v4
            drawings.boxRightOutline.Thickness = outlineThickness
            drawings.boxRightOutline.Visible = true

            drawings.boxTop.From = v1
            drawings.boxTop.To = v2
            drawings.boxTop.Thickness = boxThickness
            drawings.boxTop.Color = Esp.BoxColor
            drawings.boxTop.Visible = true
            drawings.boxBottom.From = v3
            drawings.boxBottom.To = v4
            drawings.boxBottom.Thickness = boxThickness
            drawings.boxBottom.Color = Esp.BoxColor
            drawings.boxBottom.Visible = true
            drawings.boxLeft.From = v1
            drawings.boxLeft.To = v3
            drawings.boxLeft.Thickness = boxThickness
            drawings.boxLeft.Color = Esp.BoxColor
            drawings.boxLeft.Visible = true
            drawings.boxRight.From = v2
            drawings.boxRight.To = v4
            drawings.boxRight.Thickness = boxThickness
            drawings.boxRight.Color = Esp.BoxColor
            drawings.boxRight.Visible = true
        else
            drawings.boxTopOutline.Visible = false
            drawings.boxBottomOutline.Visible = false
            drawings.boxLeftOutline.Visible = false
            drawings.boxRightOutline.Visible = false
            drawings.boxTop.Visible = false
            drawings.boxBottom.Visible = false
            drawings.boxLeft.Visible = false
            drawings.boxRight.Visible = false
        end

        if showName then
            drawings.nameText.Size = textSize
            drawings.nameText.Text = player.DisplayName
            drawings.nameText.Position = Vector2.new(bcx, by - textSize - 4)
            drawings.nameText.Color = Esp.NameColor
            drawings.nameText.Visible = true
        else
            drawings.nameText.Visible = false
        end

        if showDistance then
            drawings.distanceText.Size = textSize
            drawings.distanceText.Text = math.floor(distance) .. "m"
            drawings.distanceText.Position = Vector2.new(bcx, by + bh + 4)
            drawings.distanceText.Color = Esp.DistanceColor
            drawings.distanceText.Visible = true
        else
            drawings.distanceText.Visible = false
        end

        if showSkeleton then
            local bones = IsR6(targetCharacter) and R6Bones or R15Bones
            for i = 1, #bones do
                if not drawings.skeletonLines[i] then
                    local line = Drawing.new("Line")
                    line.Thickness = 1
                    line.Transparency = 1
                    line.ZIndex = 2
                    line.Visible = false
                    drawings.skeletonLines[i] = line
                    local outline = Drawing.new("Line")
                    outline.Color = Color3.new(0, 0, 0)
                    outline.Thickness = 3
                    outline.Transparency = 1
                    outline.ZIndex = 1
                    outline.Visible = false
                    drawings.skeletonOutlines[i] = outline
                end
                local line = drawings.skeletonLines[i]
                local outline = drawings.skeletonOutlines[i]
                local bone = bones[i]
                local partA = targetCharacter:FindFirstChild(bone[1])
                local partB = targetCharacter:FindFirstChild(bone[2])
                if partA and partB then
                    local posA, onA = camera:WorldToViewportPoint(partA.Position)
                    local posB, onB = camera:WorldToViewportPoint(partB.Position)
                    if onA and onB then
                        local v1 = Vector2.new(posB.X, posB.Y)
                        local v2 = Vector2.new(posA.X, posA.Y)
                        line.From = v1
                        line.To = v2
                        line.Thickness = boxThickness
                        line.Color = Esp.SkeletonColor
                        line.Visible = true
                        outline.From = v1
                        outline.To = v2
                        outline.Thickness = boxThickness + 1
                        outline.Visible = true
                    else
                        line.Visible = false
                        outline.Visible = false
                    end
                else
                    line.Visible = false
                    outline.Visible = false
                end
            end
        else
            for _, line in pairs(drawings.skeletonLines) do line.Visible = false end
            for _, line in pairs(drawings.skeletonOutlines) do line.Visible = false end
        end
    end
end)

local EspGroup = Tabs.Visuals:AddLeftGroupbox("Player Visuals")

EspGroup:AddToggle("EspEnabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v) Esp.Enabled = v end,
})

EspGroup:AddToggle("EspBox", {
    Text = "Draw Box",
    Default = false,
    Callback = function(v) Esp.Box = v end,
}):AddColorPicker("EspBoxColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        Esp.BoxColor = v
        for _, drawings in pairs(PlayerDrawings) do
            drawings.boxTop.Color = v
            drawings.boxBottom.Color = v
            drawings.boxLeft.Color = v
            drawings.boxRight.Color = v
        end
    end,
})

EspGroup:AddToggle("EspName", {
    Text = "Draw Name",
    Default = false,
    Callback = function(v) Esp.Name = v end,
}):AddColorPicker("EspNameColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        Esp.NameColor = v
        for _, drawings in pairs(PlayerDrawings) do drawings.nameText.Color = v end
    end,
})

EspGroup:AddToggle("EspDistance", {
    Text = "Draw Distance",
    Default = false,
    Callback = function(v) Esp.Distance = v end,
}):AddColorPicker("EspDistanceColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        Esp.DistanceColor = v
        for _, drawings in pairs(PlayerDrawings) do drawings.distanceText.Color = v end
    end,
})

EspGroup:AddToggle("EspSkeleton", {
    Text = "Draw Skeleton",
    Default = false,
    Callback = function(v) Esp.Skeleton = v end,
}):AddColorPicker("EspSkeletonColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        Esp.SkeletonColor = v
        for _, drawings in pairs(PlayerDrawings) do
            for _, line in pairs(drawings.skeletonLines) do line.Color = v end
        end
    end,
})

EspGroup:AddToggle("EspTeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(v) Esp.TeamCheck = v end,
})

EspGroup:AddToggle("EspVisibleCheck", {
    Text = "Visible Check",
    Default = false,
    Callback = function(v) Esp.VisibleCheck = v end,
})

EspGroup:AddSlider("EspMaxDistance", {
    Text = "Max Distance",
    Default = 2000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(v) Esp.MaxDistance = v end,
})

local PlayerCache = {}
local PlayerCacheCount = 0
local PlayerCacheSet = setmetatable({}, {__mode = "k"})

local function PlayerCacheAdd(player)
    if PlayerCacheSet[player] then return end
    PlayerCacheSet[player] = true
    PlayerCacheCount = PlayerCacheCount + 1
    PlayerCache[PlayerCacheCount] = player
end

local function PlayerCacheRemove(player)
    if not PlayerCacheSet[player] then return end
    PlayerCacheSet[player] = nil
    for i = 1, PlayerCacheCount do
        if PlayerCache[i] == player then
            PlayerCache[i] = PlayerCache[PlayerCacheCount]
            PlayerCache[PlayerCacheCount] = nil
            PlayerCacheCount = PlayerCacheCount - 1
            return
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do PlayerCacheAdd(player) end
Players.PlayerAdded:Connect(PlayerCacheAdd)
Players.PlayerRemoving:Connect(PlayerCacheRemove)

local HitPartCache = setmetatable({}, {__mode = "k"})

local function GetHitPart(character)
    local mode = HitPart
    if mode == "Random" then
        local r = math.random()
        mode = r < 0.5 and "Head" or (r < 0.8 and "Torso" or "HumanoidRootPart")
    end
    local cached = HitPartCache[character]
    if cached and cached.mode == mode then
        local part = cached.part
        if part and part.Parent then return part end
    end
    local part
    if mode == "Head" then
        part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    elseif mode == "Torso" then
        part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
            or character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart")
    else
        part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    end
    HitPartCache[character] = {mode = mode, part = part}
    return part
end

local function FindClosestTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local viewportSize = camera.ViewportSize
    local centerX, centerY = viewportSize.X * 0.5, viewportSize.Y * 0.5
    local fieldOfViewSquared = FieldOfView * FieldOfView
    local myTeam, myTeamColor = LocalPlayer.Team, LocalPlayer.TeamColor
    local best, bestDistance = nil, math.huge

    for i = 1, PlayerCacheCount do
        local player = PlayerCache[i]
        if player and player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local skip = false
                    if TeamCheck then
                        local playerTeam = player.Team
                        if playerTeam and myTeam then
                            if playerTeam == myTeam then skip = true end
                        else
                            local playerColor = player.TeamColor
                            if playerColor and myTeamColor and playerColor == myTeamColor then skip = true end
                        end
                    end
                    if not skip then
                        local part = GetHitPart(character)
                        if part then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dx, dy = screenPos.X - centerX, screenPos.Y - centerY
                                local distSquared = dx * dx + dy * dy
                                if distSquared <= fieldOfViewSquared and distSquared < bestDistance then
                                    bestDistance = distSquared
                                    best = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local CachedTarget = nil
local CachedTargetNext = 0
local function GetCachedTarget()
    local now = os.clock()
    if now < CachedTargetNext then return CachedTarget end
    CachedTargetNext = now + 0.1
    CachedTarget = FindClosestTarget()
    return CachedTarget
end

local WeaponConfigModule, WeaponConfigFolder
do
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local module = shared and shared:FindFirstChild("WeaponConfigManager")
    if module then
        WeaponConfigFolder = module
        if module:IsA("ModuleScript") then
            local ok, required = pcall(require, module)
            if ok and type(required) == "table" and type(required.GetMuzzleConfig) == "function" then
                WeaponConfigModule = required
            end
        end
    end
end

local WeaponStatsCache = {}
local function GetWeaponStats(weaponName, muzzleIndex, bulletIndex)
    if not weaponName then return nil end
    local key = weaponName .. "|" .. (muzzleIndex or 1) .. "|" .. (bulletIndex or 1)
    local cached = WeaponStatsCache[key]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end
    local muzzleConfig
    if WeaponConfigModule then
        local ok, result = pcall(function() return WeaponConfigModule:GetMuzzleConfig(weaponName, muzzleIndex or 1) end)
        if ok and type(result) == "table" then muzzleConfig = result end
    end
    if not muzzleConfig and WeaponConfigFolder then
        local weaponModule = WeaponConfigFolder:FindFirstChild(weaponName)
        if weaponModule and weaponModule:IsA("ModuleScript") then
            local ok, config = pcall(require, weaponModule)
            if ok and type(config) == "table" then muzzleConfig = config[muzzleIndex or 1] or config[1] end
        end
    end
    if not muzzleConfig then WeaponStatsCache[key] = false return nil end
    local bulletSettings = muzzleConfig.BulletSettings and muzzleConfig.BulletSettings[bulletIndex or 1]
    if not bulletSettings then WeaponStatsCache[key] = false return nil end
    local stats = {
        v0 = bulletSettings.MuzzleVelocity or 0,
        K = bulletSettings.Drag or 0,
    }
    WeaponStatsCache[key] = stats
    return stats
end

local function TimeOfFlight(v0, K, dist)
    if dist <= 0 then return 0 end
    if K > 1e-6 then
        local maxDistance = v0 / K
        if dist >= maxDistance then return math.huge end
        return -(1 / K) * math.log(1 - dist * K / v0)
    end
    return v0 > 1e-6 and dist / v0 or math.huge
end

local SA_ITERATIONS = 4
local function SolveAim(origin, targetPosition, velocity, stats, gravity)
    local predicted = targetPosition
    for _ = 1, SA_ITERATIONS do
        local timeOfFlight = TimeOfFlight(stats.v0, stats.K, (predicted - origin).Magnitude)
        if timeOfFlight ~= timeOfFlight or timeOfFlight == math.huge then break end
        local future = Prediction and (targetPosition + velocity * timeOfFlight) or targetPosition
        local lift = BulletDropCompensation and Vector3.new(0, 0.5 * gravity * timeOfFlight * timeOfFlight, 0) or Vector3.zero
        predicted = future + lift
    end
    return (predicted - origin).Unit
end

local BulletTracerEnabled = false
local BulletTracerSize = 0.1
local BulletTracerDuration = 1
local BulletTracerTransparency = 0
local BulletTracerMaterial = Enum.Material.ForceField
local BulletTracerColor = Color3.fromRGB(255, 255, 255)
local BulletTracerRange = 1000
local MaxActiveTracers = 12

local BulletTracerFolder = Instance.new("Folder")
BulletTracerFolder.Name = "BulletTracers"
BulletTracerFolder.Parent = workspace

local BulletTracerParams = RaycastParams.new()
BulletTracerParams.FilterType = Enum.RaycastFilterType.Exclude
BulletTracerParams.IgnoreWater = true
local BulletTracerFilter = {nil}

local ActiveTracers = {}

local function AddTracer(from, to)
    local direction = to - from
    local distance = direction.Magnitude
    if distance < 0.1 then return end

    if #ActiveTracers >= MaxActiveTracers then
        local oldest = table.remove(ActiveTracers, 1)
        if oldest then oldest:Destroy() end
    end

    local part = Instance.new("Part")
    part.Name = "Tracer"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Massless = true
    part.Locked = true
    part.Size = Vector3.new(BulletTracerSize, BulletTracerSize, distance)
    part.CFrame = CFrame.lookAt(from + direction * 0.5, to)
    part.Color = BulletTracerColor
    part.Material = BulletTracerMaterial
    part.Transparency = BulletTracerTransparency
    part:SetAttribute("born", os.clock())
    part.Parent = BulletTracerFolder
    ActiveTracers[#ActiveTracers + 1] = part
end

local function FireBulletTracer(origin, direction)
    BulletTracerFilter[1] = LocalPlayer.Character
    BulletTracerParams.FilterDescendantsInstances = BulletTracerFilter
    local result = workspace:Raycast(origin, direction * BulletTracerRange, BulletTracerParams)
    local endPosition = result and result.Position or (origin + direction * BulletTracerRange)
    AddTracer(origin, endPosition)
end

local function ClearBulletTracers()
    for i = #ActiveTracers, 1, -1 do
        pcall(function() ActiveTracers[i]:Destroy() end)
    end
    table.clear(ActiveTracers)
end

local TracerAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
    if #ActiveTracers == 0 then return end
    TracerAccumulator = TracerAccumulator + deltaTime
    if TracerAccumulator < 0.1 then return end
    TracerAccumulator = 0
    local now = os.clock()
    for i = #ActiveTracers, 1, -1 do
        local part = ActiveTracers[i]
        if not part.Parent then
            table.remove(ActiveTracers, i)
        else
            local age = now - (part:GetAttribute("born") or 0)
            if age >= BulletTracerDuration then
                part:Destroy()
                table.remove(ActiveTracers, i)
            end
        end
    end
end)

local FireHooked = nil
local function HookFire(tbl)
    local key, original
    for k, v in pairs(tbl) do
        if type(v) == "function" and k ~= "init" and k ~= "fire" then
            key, original = k, v
            break
        end
    end
    if not key then return end

    tbl[key] = function(weaponName, muzzleIndex, bulletIndex, origin, directions, opts)
        local tracerOrigin = origin
        local tracerDirection = directions[1]
        local aimTarget = GetCachedTarget()

        if SilentAimEnabled and aimTarget and aimTarget.Character then
            local aimPart = GetHitPart(aimTarget.Character)
            local humanoidRootPart = aimTarget.Character:FindFirstChild("HumanoidRootPart")
            if aimPart and humanoidRootPart then
                local weaponNameString = type(weaponName) == "string" and weaponName
                    or (typeof(weaponName) == "Instance" and weaponName.Name or nil)
                local stats = weaponNameString and GetWeaponStats(weaponNameString, muzzleIndex, bulletIndex) or nil
                local aimDirection
                if stats and stats.v0 > 0 then
                    aimDirection = SolveAim(origin, aimPart.Position, humanoidRootPart.AssemblyLinearVelocity, stats, workspace.Gravity)
                else
                    aimDirection = (aimPart.Position - origin).Unit
                end
                local blocked = WallCheck and not HasLineOfSight(origin, aimPart.Position, aimTarget.Character)
                if not blocked then
                    for i = 1, #directions do directions[i] = aimDirection end
                    tracerDirection = aimDirection
                end
            end
        end

        if BulletTracerEnabled and tracerDirection and typeof(tracerDirection) == "Vector3" then
            local shouldDraw = true

            if WallCheck then
                local checkPos
                local excludeChar
                if aimTarget and aimTarget.Character and SilentAimEnabled then
                    local checkPart = aimTarget.Character:FindFirstChild("Head")
                        or aimTarget.Character:FindFirstChild("HumanoidRootPart")
                    if checkPart then checkPos = checkPart.Position end
                    excludeChar = aimTarget.Character
                end
                checkPos = checkPos or (tracerOrigin + tracerDirection * BulletTracerRange)
                if not HasLineOfSight(tracerOrigin, checkPos, excludeChar) then
                    shouldDraw = false
                end
            end

            if shouldDraw and aimTarget and aimTarget.Character and SilentAimEnabled then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local theirRoot = aimTarget.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and theirRoot and (myRoot.Position - theirRoot.Position).Magnitude > Esp.MaxDistance then
                    shouldDraw = false
                end
            end

            if shouldDraw then
                FireBulletTracer(tracerOrigin, tracerDirection)
            end
        end

        return original(weaponName, muzzleIndex, bulletIndex, origin, directions, opts)
    end
    FireHooked = tbl
end

task.spawn(function()
    local delay = 0.1
    while true do
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local ballisticsClient = playerScripts and playerScripts:FindFirstChild("BallisticsClient")
        local clientFire = ballisticsClient and ballisticsClient:FindFirstChild("ClientFire")
        if clientFire then
            local ok, module = pcall(require, clientFire)
            if ok and type(module) == "table" and module ~= FireHooked then
                HookFire(module)
                delay = 10
            end
        end
        task.wait(delay)
        if delay < 1 then delay = delay * 1.5 end
    end
end)

local VisualAccumulator = 0
RunService.RenderStepped:Connect(function(deltaTime)
    if not ShowFieldOfView and not ShowTracer then
        if FOVCircle.Visible then FOVCircle.Visible = false end
        if SnapLine.Visible then SnapLine.Visible = false end
        return
    end

    VisualAccumulator = VisualAccumulator + deltaTime
    if VisualAccumulator < 0.05 then return end
    VisualAccumulator = 0

    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewportSize = camera.ViewportSize

    if ShowFieldOfView then
        FOVCircle.Position = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
        FOVCircle.Radius = FieldOfView
        FOVCircle.Color = FieldOfViewColor
        FOVCircle.Visible = true
    elseif FOVCircle.Visible then
        FOVCircle.Visible = false
    end

    if ShowTracer then
        local target = GetCachedTarget()
        local drawn = false

        if target and target.Character then
            local aimPart = GetHitPart(target.Character)
            local theirRoot = target.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            local distanceOK = true
            if myRoot and theirRoot and SilentAimEnabled then
                distanceOK = (myRoot.Position - theirRoot.Position).Magnitude <= Esp.MaxDistance
            end

            local visibleOK = true
            if WallCheck and myRoot and aimPart then
                visibleOK = HasLineOfSight(myRoot.Position, aimPart.Position, target.Character)
            end

            if distanceOK and visibleOK and aimPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    SnapLine.Color = TracerColor
                    SnapLine.From = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
                    SnapLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    SnapLine.Visible = true
                    drawn = true
                end
            end
        end

        if not drawn and SnapLine.Visible then SnapLine.Visible = false end
    elseif SnapLine.Visible then
        SnapLine.Visible = false
    end
end)

local BulletTracerGroup = Tabs.Combat:AddGroupbox({
    Side = "Left",
    Name = "Bullet Tracer",
})

BulletTracerGroup:AddToggle("BulletTracerEnabled", {
    Text = "Enable Bullet Tracer",
    Default = false,
    Callback = function(v)
        BulletTracerEnabled = v
        if not v then ClearBulletTracers() end
    end,
}):AddColorPicker("BulletTracerColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) BulletTracerColor = v end,
})

BulletTracerGroup:AddSlider("BulletTracerSize", {
    Text = "Size",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v) BulletTracerSize = v end,
})

BulletTracerGroup:AddSlider("BulletTracerDuration", {
    Text = "Duration",
    Default = 1,
    Min = 0,
    Max = 5,
    Rounding = 0,
    Callback = function(v) BulletTracerDuration = v end,
})

BulletTracerGroup:AddSlider("BulletTracerTransparency", {
    Text = "Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(v) BulletTracerTransparency = v end,
})

BulletTracerGroup:AddDropdown("BulletTracerMaterial", {
    Values = {"Neon", "SmoothPlastic", "ForceField", "Glass", "Ice", "Metal", "DiamondPlate", "Concrete", "Fabric", "Sand", "Wood", "WoodPlanks", "Cobblestone", "Granite", "Marble", "Pebble"},
    Default = "ForceField",
    Text = "Material",
    Callback = function(v) BulletTracerMaterial = Enum.Material[v] or Enum.Material.ForceField end,
})

local GunModsGroup = Tabs.Combat:AddGroupbox({
    Side = "Right",
    Name = "Gun Mods",
})

local HitsoundGroup = Tabs.Combat:AddGroupbox({
    Side = "Right",
    Name = "Hitsounds",
})

local NoRecoilEnabled = false
local NoSpreadEnabled = false

local RecoilController = require(ReplicatedStorage.Client.Tools.Weapon.controllers.RecoilController)

local RecoilHooked = {}

local function InstallNoRecoil()
    if not RecoilController then return end
    local targets = {}
    if type(RecoilController.rNDvKCHx7N) == "function" then
        table.insert(targets, RecoilController.rNDvKCHx7N)
    end
    if type(RecoilController.update) == "function" then
        table.insert(targets, RecoilController.update)
    end
    for _, fn in ipairs(targets) do
        if not RecoilHooked[fn] then
            RecoilHooked[fn] = true
            local isUpdate = fn == RecoilController.update
            pcall(hookfunction, fn, function(...)
                if NoRecoilEnabled then
                    if isUpdate and RecoilController.getSpring then
                        for _, name in ipairs({"offset", "rotation", "handle", "camera"}) do
                            local ok, sp = pcall(RecoilController.getSpring, name)
                            if ok and type(sp) == "table" then
                                if sp.Position then sp.Position = Vector3.zero end
                                if sp.Velocity then sp.Velocity = Vector3.zero end
                                if sp.Target then sp.Target = Vector3.zero end
                            end
                        end
                    end
                    return
                end
                return fn(...)
            end)
        end
    end
end

local function RemoveNoRecoil()
    for fn in pairs(RecoilHooked) do
        pcall(restorefunction, fn)
    end
    table.clear(RecoilHooked)
end

GunModsGroup:AddToggle("NoRecoilEnabled", {
    Text = "No Recoil",
    Default = false,
    Callback = function(v)
        NoRecoilEnabled = v
        if v then InstallNoRecoil() else RemoveNoRecoil() end
    end,
})

local SpreadHooked = {}
local SpreadInstalled = false

local function InstallNoSpread()
    if SpreadInstalled then return end
    SpreadInstalled = true
    for _, func in pairs(getgc()) do
        if type(func) == "function" and islclosure(func) then
            local info = debug.getinfo(func)
            if info.source and info.source:find("Weapon", 1, true) then
                local name = info.name
                if name and (name:find("Spread") or name:find("Bloom") or name:find("Inaccuracy")) then
                    if not SpreadHooked[func] then
                        SpreadHooked[func] = true
                        pcall(hookfunction, func, function(...)
                            if NoSpreadEnabled then return 0 end
                            return func(...)
                        end)
                    end
                end
            end
        end
    end
end

local function RemoveNoSpread()
    for func in pairs(SpreadHooked) do
        pcall(restorefunction, func)
    end
    table.clear(SpreadHooked)
    SpreadInstalled = false
end

GunModsGroup:AddToggle("NoSpreadEnabled", {
    Text = "No Spread",
    Default = false,
    Callback = function(v)
        NoSpreadEnabled = v
        if v then InstallNoSpread() else RemoveNoSpread() end
    end,
})

local InstantEquipEnabled = false
local FakeTask = setmetatable({}, {
    __index = function(_, key)
        if key == "wait" then
            return function(t)
                if InstantEquipEnabled then return end
                return task.wait(t)
            end
        end
        return task[key]
    end,
})

local EquipHooked = {}
local EquipSwapped = {}

local function ApplyInstantEquip()
    for _, func in pairs(getgc()) do
        if type(func) == "function" and islclosure(func) then
            local info = debug.getinfo(func)
            if info.source and info.source:find("InventoryController", 1, true) then
                if not EquipSwapped[func] then
                    EquipSwapped[func] = true
                    local ok, upvalues = pcall(debug.getupvalues, func)
                    if ok and upvalues then
                        for i, value in ipairs(upvalues) do
                            if value == task then
                                pcall(debug.setupvalue, func, i, FakeTask)
                            end
                        end
                    end
                end
                if info.name == "canStartSwitch" then
                    if not EquipHooked[func] then
                        EquipHooked[func] = true
                        pcall(hookfunction, func, function() return true end)
                    end
                elseif info.name == "showLoading" or info.name == "holdForTrack" then
                    if not EquipHooked[func] then
                        EquipHooked[func] = true
                        pcall(hookfunction, func, function() end)
                    end
                end
            end
        end
    end
end

local function RemoveInstantEquip()
    for func in pairs(EquipHooked) do
        pcall(restorefunction, func)
    end
    table.clear(EquipHooked)
end

GunModsGroup:AddToggle("InstantEquipEnabled", {
    Text = "Instant Equip",
    Default = false,
    Callback = function(v)
        InstantEquipEnabled = v
        if v then
            ApplyInstantEquip()
        else
            RemoveInstantEquip()
            table.clear(EquipSwapped)
        end
    end,
})

local HitsoundIds = {
    ["Team Fortress 2"] = "rbxassetid://138901307926331",
    ["Call of Duty"] = "rbxassetid://77082587278347",
    ["Bubble"] = "rbxassetid://119697580657161",
    ["Skeet"] = "rbxassetid://140247876667835",
    ["Neverlose"] = "rbxassetid://139452805868562",
}

local HitsoundsEnabled = false
local HitsoundSelected = "None"
local HitsoundVolume = 5
local HitsoundCooldown = 0

local HitsoundInstance = Instance.new("Sound")
HitsoundInstance.Volume = HitsoundVolume
HitsoundInstance.Parent = game:GetService("SoundService")

pcall(function()
    local ProjectileCaster = require(ReplicatedStorage.Shared.Ballistics.ProjectileCaster)
    local oldFire = ProjectileCaster.Fire
    ProjectileCaster.Fire = function(params)
        local oldImpact = params.OnImpact
        params.OnImpact = function(hit)
            local projectile = hit.Projectile
            if projectile and projectile.Owner == LocalPlayer and HitsoundsEnabled and HitsoundSelected ~= "None" then
                local now = os.clock()
                if now - HitsoundCooldown > 0.05 then
                    local instance = hit.Instance
                    local model = instance and instance:FindFirstAncestorOfClass("Model")
                    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        HitsoundCooldown = now
                        HitsoundInstance.SoundId = HitsoundIds[HitsoundSelected] or ""
                        HitsoundInstance.Volume = HitsoundVolume
                        HitsoundInstance:Play()
                    end
                end
            end
            if oldImpact then oldImpact(hit) end
        end
        return oldFire(params)
    end
end)

HitsoundGroup:AddToggle("HitsoundsEnabled", {
    Text = "Enable Hitsounds",
    Default = false,
    Callback = function(v) HitsoundsEnabled = v end,
})

HitsoundGroup:AddDropdown("HitsoundSelected", {
    Values = {"None", "Team Fortress 2", "Call of Duty", "Bubble", "Skeet", "Neverlose"},
    Default = "None",
    Text = "Hitsound",
    Callback = function(v)
        HitsoundSelected = v
        if v ~= "None" then
            HitsoundInstance.SoundId = HitsoundIds[v] or ""
        end
    end,
})

HitsoundGroup:AddSlider("HitsoundVolume", {
    Text = "Volume",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(v)
        HitsoundVolume = v / 20
        HitsoundInstance.Volume = HitsoundVolume
    end,
})

local AmbienceEnabled = false
local AmbienceColor = Color3.fromRGB(255, 255, 255)
local AmbienceOriginal

local function ApplyAmbience()
    if not AmbienceOriginal then
        AmbienceOriginal = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows,
        }
    end
    Lighting.Ambient = AmbienceColor
    Lighting.OutdoorAmbient = AmbienceColor
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
end

local function RestoreAmbience()
    if not AmbienceOriginal then return end
    pcall(function()
        Lighting.Ambient = AmbienceOriginal.Ambient
        Lighting.OutdoorAmbient = AmbienceOriginal.OutdoorAmbient
        Lighting.Brightness = AmbienceOriginal.Brightness
        Lighting.ClockTime = AmbienceOriginal.ClockTime
        Lighting.GlobalShadows = AmbienceOriginal.GlobalShadows
    end)
    AmbienceOriginal = nil
end

local NoFogEnabled = false
local NoFoliageEnabled = false
local NoGrassEnabled = false

local FoliageStore = {}
local FoliageConnection

local function RemoveGrass()
    pcall(function()
        if setscriptable then setscriptable(workspace.Terrain, "Decoration", true) end
        if sethiddenproperty then
            sethiddenproperty(workspace.Terrain, "Decoration", false)
        else
            workspace.Terrain.Decoration = false
        end
    end)
end

local function RestoreGrass()
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(workspace.Terrain, "Decoration", true)
        else
            workspace.Terrain.Decoration = true
        end
    end)
end

local function HideFoliage()
    local map = workspace:FindFirstChild("Map")
    local vegetation = map and map:FindFirstChild("Vegetation")
    if not vegetation then return end
    for _, descendant in ipairs(vegetation:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if FoliageStore[descendant] == nil then FoliageStore[descendant] = descendant.LocalTransparencyModifier end
            descendant.LocalTransparencyModifier = 1
        end
    end
end

local function ShowFoliage()
    for instance, original in pairs(FoliageStore) do
        if instance and instance.Parent then instance.LocalTransparencyModifier = original end
    end
    table.clear(FoliageStore)
end

local function WatchFoliage()
    if FoliageConnection then return end
    local map = workspace:FindFirstChild("Map")
    local vegetation = map and map:FindFirstChild("Vegetation")
    if not vegetation then return end
    FoliageConnection = vegetation.DescendantAdded:Connect(function(descendant)
        if NoFoliageEnabled and descendant:IsA("BasePart") then
            if FoliageStore[descendant] == nil then FoliageStore[descendant] = descendant.LocalTransparencyModifier end
            descendant.LocalTransparencyModifier = 1
        end
    end)
end

local function UnwatchFoliage()
    if FoliageConnection then FoliageConnection:Disconnect() FoliageConnection = nil end
end

local FogOriginal

local function SaveFog()
    if FogOriginal then return end
    FogOriginal = {
        End = Lighting.FogEnd,
        Start = Lighting.FogStart,
        Color = Lighting.FogColor,
        Atmospheres = {},
    }
    for _, instance in ipairs(Lighting:GetDescendants()) do
        if instance:IsA("Atmosphere") then
            FogOriginal.Atmospheres[instance] = {Density = instance.Density, Haze = instance.Haze, Glare = instance.Glare}
        end
    end
end

local function RemoveFog()
    SaveFog()
    pcall(function()
        Lighting.FogEnd = math.huge
        Lighting.FogStart = 0
    end)
    for _, instance in ipairs(Lighting:GetDescendants()) do
        if instance:IsA("Atmosphere") then
            pcall(function()
                instance.Density = 0
                instance.Haze = 0
                instance.Glare = 0
            end)
        end
    end
end

local function RestoreFog()
    if not FogOriginal then return end
    pcall(function()
        Lighting.FogEnd = FogOriginal.End
        Lighting.FogStart = FogOriginal.Start
        Lighting.FogColor = FogOriginal.Color
    end)
    for instance, props in pairs(FogOriginal.Atmospheres) do
        if instance and instance.Parent then
            pcall(function()
                instance.Density = props.Density
                instance.Haze = props.Haze
                instance.Glare = props.Glare
            end)
        end
    end
    FogOriginal = nil
end

local WorldGroup = Tabs.World:AddLeftGroupbox("World Visuals")

WorldGroup:AddToggle("AmbienceEnabled", {
    Text = "Ambience",
    Default = false,
    Callback = function(v)
        AmbienceEnabled = v
        if v then ApplyAmbience() else RestoreAmbience() end
    end,
}):AddColorPicker("AmbienceColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        AmbienceColor = v
        if AmbienceEnabled then
            Lighting.Ambient = v
            Lighting.OutdoorAmbient = v
        end
    end,
})

WorldGroup:AddToggle("NoFogEnabled", {
    Text = "No Fog",
    Default = false,
    Callback = function(v)
        NoFogEnabled = v
        if v then RemoveFog() else RestoreFog() end
    end,
})

WorldGroup:AddToggle("NoFoliageEnabled", {
    Text = "No Foliage",
    Default = false,
    Callback = function(v)
        NoFoliageEnabled = v
        if v then
            HideFoliage()
            WatchFoliage()
        else
            UnwatchFoliage()
            ShowFoliage()
        end
    end,
})

WorldGroup:AddToggle("NoGrassEnabled", {
    Text = "No Grass",
    Default = false,
    Callback = function(v)
        NoGrassEnabled = v
        if v then RemoveGrass() else RestoreGrass() end
    end,
})

local SkyboxGroup = Tabs.World:AddRightGroupbox("Skybox Visuals")

SkyboxGroup:AddToggle("SkyboxEnabled", {
    Text = "Enable Skybox",
    Default = false,
    Callback = function(v)
        SkyboxEnabled = v
        if v and SkyboxSelected ~= "None" then
            ApplySkybox(SkyboxSelected)
        else
            ApplySkybox("None")
        end
    end,
})

SkyboxGroup:AddDropdown("SkyboxSelected", {
    Values = {"None", "Blue Sky", "Vaporwave", "Redshift", "Blaze", "Dark Night", "Bright Pink", "Purple Sky", "Galaxy", "Pinky Sky"},
    Default = "None",
    Text = "Skybox",
    Callback = function(v)
        SkyboxSelected = v
        if SkyboxEnabled then
            ApplySkybox(v)
        end
    end,
})

local AntiSuppresionEnabled = false
local AntiDefeaningEnabled = false
local AntiShockEnabled = false

RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    local characterValues = character and character:FindFirstChild("CharacterValues")
    if not characterValues then return end
    if AntiSuppresionEnabled then
        local value = characterValues:FindFirstChild("Suppression")
        if value then value.Value = 0 end
    end
    if AntiDefeaningEnabled then
        local value = characterValues:FindFirstChild("Deafening")
        if value then value.Value = 0 end
    end
    if AntiShockEnabled then
        local value = characterValues:FindFirstChild("Shock")
        if value then value.Value = 0 end
    end
end)

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Character")

MiscGroup:AddToggle("AntiSuppresionEnabled", {
    Text = "Anti Suppression",
    Default = false,
    Callback = function(v) AntiSuppresionEnabled = v end,
})

MiscGroup:AddToggle("AntiDefeaningEnabled", {
    Text = "Anti Deafen",
    Default = false,
    Callback = function(v) AntiDefeaningEnabled = v end,
})

MiscGroup:AddToggle("AntiShockEnabled", {
    Text = "Anti Shock",
    Default = false,
    Callback = function(v) AntiShockEnabled = v end,
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

local function UnloadAll()
    local toggleNames = {
        "SilentAimEnabled", "TeamCheck", "WallCheck", "Prediction", "BulletDropCompensation",
        "ShowFieldOfView", "ShowTracer", "BulletTracerEnabled", "NoRecoilEnabled", "NoSpreadEnabled",
        "InstantEquipEnabled", "HitsoundsEnabled", "EspEnabled", "EspBox",
        "EspName", "EspDistance", "EspSkeleton", "EspTeamCheck", "EspVisibleCheck",
        "SkyboxEnabled",
        "AmbienceEnabled", "NoFogEnabled", "NoFoliageEnabled", "NoGrassEnabled",
        "AntiSuppresionEnabled", "AntiDefeaningEnabled", "AntiShockEnabled",
    }
    for _, name in ipairs(toggleNames) do
        local opt = Options[name]
        if opt then
            pcall(function() if opt.Set then opt:Set(false) end end)
            pcall(function() opt.Value = false end)
        end
    end

    SilentAimEnabled = false
    BulletTracerEnabled = false
    ClearBulletTracers()
    if BulletTracerFolder and BulletTracerFolder.Parent then
        pcall(function() BulletTracerFolder:Destroy() end)
    end

    NoRecoilEnabled = false
    RemoveNoRecoil()

    NoSpreadEnabled = false
    RemoveNoSpread()

    InstantEquipEnabled = false
    RemoveInstantEquip()
    table.clear(EquipSwapped)

    HitsoundsEnabled = false
    if HitsoundInstance and HitsoundInstance.Parent then
        pcall(function() HitsoundInstance:Destroy() end)
    end

    Esp.Enabled = false
    for player in pairs(PlayerDrawings) do RemoveEspForPlayer(player) end
    table.clear(PlayerDrawings)

    SkyboxEnabled = false
    ApplySkybox("None")

    pcall(function() FOVCircle:Remove() end)
    pcall(function() SnapLine:Remove() end)

    AmbienceEnabled = false RestoreAmbience()
    NoFogEnabled = false RestoreFog()
    NoFoliageEnabled = false UnwatchFoliage() ShowFoliage()
    NoGrassEnabled = false RestoreGrass()

    AntiSuppresionEnabled = false
    AntiDefeaningEnabled = false
    AntiShockEnabled = false

    task.wait(0.1)
    pcall(function() Library:Unload() end)
end

MenuGroup:AddButton("Unload", UnloadAll)

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("AstralSolutions")
SaveManager:SetFolder("AstralSolutions")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
