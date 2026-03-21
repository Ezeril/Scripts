local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    CollectRange      = 3,
    GlideSpeed        = 60,
    StepSize          = 0.5,
    MoveTimeout       = 10,
    BlacklistDuration = 5,
}

-- ─── Utilitaires ────────────────────────────────────────────────────────────

local function GetCoinContainer()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" or v.Name == "CoinAreas" then
            return v
        end
    end
    return nil
end

local function GetItemPosition(item)
    if not item or not item.Parent then return nil end
    local ok, pos = pcall(function()
        return item:IsA("BasePart") and item.Position or item:GetPivot().Position
    end)
    return ok and pos or nil
end

local function IsItemValid(item)
    return item and item.Parent ~= nil and GetItemPosition(item) ~= nil
end

-- ─── Noclip Loop (RunService.Stepped = avant le calcul physique) ─────────────

local noclipConnection = nil

local function EnableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not getgenv().Settings.AutoBallonEnabled then
            -- Réactiver les collisions
            local Character = LocalPlayer.Character
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            noclipConnection:Disconnect()
            noclipConnection = nil
            return
        end

        local Character = LocalPlayer.Character
        if not Character then return end

        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- ─── Sélection de la cible la plus proche ───────────────────────────────────

local function GetNearestItem(blacklist)
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Nearest, MinDist = nil, math.huge
    local now = tick()

    for _, item in pairs(Container:GetDescendants()) do
        local validName = item.Name == "Coin_Server"
                       or item.Name == "BeachBall"
                       or item.Name == "CoinArea"

        if validName and IsItemValid(item) then
            local blacklistedUntil = blacklist[item]
            if not blacklistedUntil or now >= blacklistedUntil then
                local pos = GetItemPosition(item)
                local dist = (pos - Root.Position).Magnitude
                if dist < MinDist then
                    MinDist = dist
                    Nearest = item
                end
            end
        end
    end

    return Nearest
end

-- ─── Glisse pas à pas ────────────────────────────────────────────────────────

local function GlideTo(targetPos)
    local Settings = getgenv().Settings
    local deadline = tick() + Settings.MoveTimeout

    while tick() < deadline and getgenv().Settings.AutoBallonEnabled do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then return false end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            -- PlatformStand = true suspend le moteur physique du Humanoid
            -- pour éviter les corrections de position pendant le glide
            Humanoid.PlatformStand = true
            Humanoid.AutoRotate = false
        end

        local currentPos = Root.Position
        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude

        if distance <= Settings.CollectRange then
            if Humanoid then
                Humanoid.PlatformStand = false
                Humanoid.AutoRotate = true
            end
            return true
        end

        local stepDist = math.min(Settings.StepSize, distance)
        local nextPos  = currentPos + direction.Unit * stepDist

        Root.CFrame = CFrame.new(nextPos) * (Root.CFrame - Root.CFrame.Position)

        task.wait(Settings.StepSize / Settings.GlideSpeed)
    end

    -- Timeout : rétablir le Humanoid
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid.PlatformStand = false
        Humanoid.AutoRotate = true
    end

    return false
end

-- ─── Boucle principale ──────────────────────────────────────────────────────

local function StartAutoCollect()
    local blacklist = {}

    while getgenv().Settings.AutoBallonEnabled do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")

        if Root then
            for item in pairs(blacklist) do
                if not IsItemValid(item) then
                    blacklist[item] = nil
                end
            end

            local Target = GetNearestItem(blacklist)

            if Target then
                local targetPos = GetItemPosition(Target)
                if targetPos then
                    local reached = GlideTo(targetPos)
                    if not reached then
                        blacklist[Target] = tick() + getgenv().Settings.BlacklistDuration
                    end
                end
            else
                blacklist = {}
                task.wait(1)
            end
        end

        task.wait(0.1)
    end
end

-- ─── UI ─────────────────────────────────────────────────────────────────────

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true
))()

local Window = Library:CreateWindow("MM2 | EsohaSL Fix")
Window:Section("esohasl.net")

Window:Toggle("Auto Collect Coins/Ball", {}, function(state)
    getgenv().Settings.AutoBallonEnabled = state
    if state then
        EnableNoclip()               -- ← Active le noclip via Stepped
        task.spawn(StartAutoCollect)
    end
end)

Window:Button("YouTube: EsohaSL", function()
    if setclipboard then
        setclipboard("https://youtube.com/@esohasl")
    end
end)

-- ─── Anti-AFK ───────────────────────────────────────────────────────────────

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

print("Script MM2 chargé avec succès !")
