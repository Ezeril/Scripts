local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    CollectRange = 4,       -- Distance (studs) pour considérer l'item collecté
    MoveTimeout = 8,        -- Timeout max en secondes pour atteindre un item
    BlacklistDuration = 5,  -- Secondes avant de réessayer un item raté
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
    return item and item.Parent and GetItemPosition(item) ~= nil
end

-- ─── Sélection de la cible la plus proche (avec blacklist) ──────────────────

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
            -- Ignorer si dans la blacklist et délai pas encore expiré
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

-- ─── Déplacement naturel via Humanoid:MoveTo() (glisse, pas TP) ─────────────

local function WalkTo(targetPos)
    local Character = LocalPlayer.Character
    if not Character then return false end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root     = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not Root then return false end

    Humanoid:MoveTo(targetPos)

    local deadline = tick() + getgenv().Settings.MoveTimeout
    while tick() < deadline do
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - targetPos).Magnitude
        if dist <= getgenv().Settings.CollectRange then
            return true   -- On est arrivé à portée
        end
        task.wait(0.1)
    end

    return false  -- Timeout → on blackliste cet item temporairement
end

-- ─── Boucle principale ──────────────────────────────────────────────────────

local function StartAutoCollect()
    local blacklist = {}  -- [item] = tick() d'expiration

    while getgenv().Settings.AutoBallonEnabled do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")

        if Root then
            -- Nettoyer la blacklist des items qui ont disparu
            for item in pairs(blacklist) do
                if not IsItemValid(item) then
                    blacklist[item] = nil
                end
            end

            local Target = GetNearestItem(blacklist)

            if Target then
                local startPos = GetItemPosition(Target)
                if startPos then
                    local reached = WalkTo(startPos)

                    if not reached then
                        -- Timeout : on blackliste temporairement cet item
                        blacklist[Target] = tick() + getgenv().Settings.BlacklistDuration
                    end
                    -- Si l'item a disparu tout seul (collecté), pas besoin d'action
                end
            else
                -- Aucun item dispo → on vide la blacklist et on attend
                blacklist = {}
                task.wait(1)
            end
        end

        task.wait(0.15)
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

print("Script MM2 chargé avec succès !")
