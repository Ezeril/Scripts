local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    CollectRange      = 3,   -- Distance pour considérer l'item collecté (studs)
    GlideSpeed        = 60,  -- Studs par seconde
    StepSize          = 0.5, -- Taille de chaque pas
    MoveTimeout       = 10,  -- Timeout max en secondes par item
    BlacklistDuration = 5,   -- Secondes avant de réessayer un item raté
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

-- ─── Collisions du personnage ────────────────────────────────────────────────

local function SetCharacterCollision(enabled)
    local Character = LocalPlayer.Character
    if not Character then return end
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = enabled
        end
    end
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

-- ─── Glisse pas à pas (traverse les murs, déclenche les Touched) ─────────────

local function GlideTo(targetPos)
    local Settings = getgenv().Settings
    local deadline = tick() + Settings.MoveTimeout

    -- Désactiver les collisions AVANT de glisser
    SetCharacterCollision(false)

    while tick() < deadline and getgenv().Settings.AutoBallonEnabled do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then
            SetCharacterCollision(true)
            return false
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.AutoRotate = false
            Humanoid.PlatformStand = true -- Empêche l'animation de lutter contre le mouvement
        end

        local currentPos = Root.Position
        local direction = targetPos - currentPos
        local distance = direction.Magnitude

        -- Arrivé à portée → succès
        if distance <= Settings.CollectRange then
            SetCharacterCollision(true)
            if Humanoid then
                Humanoid.AutoRotate = true
                Humanoid.PlatformStand = false
            end
            return true
        end

        -- Prochain pas vers la cible
        local stepDist = math.min(Settings.StepSize, distance)
        local nextPos = currentPos + direction.Unit * stepDist

        Root.CFrame = CFrame.new(nextPos) * (Root.CFrame - Root.CFrame.Position)

        task.wait(Settings.StepSize / Settings.GlideSpeed)
    end

    -- Réactiver dans tous les cas (timeout, désactivation)
    SetCharacterCollision(true)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid.AutoRotate = true
        Humanoid.PlatformStand = false
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
            -- Nettoyer la blacklist des items disparus
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

-- Réactiver les collisions si le personnage respawn
LocalPlayer.CharacterAdded:Connect(function()
    getgenv().Settings.AutoBallonEnabled = false
    SetCharacterCollision(true)
end)

print("Script MM2 chargé avec succès !")
