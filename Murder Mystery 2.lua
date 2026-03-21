local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    CollectRange    = 3,    -- Distance pour considérer l'item collecté (studs)
    GlideSpeed      = 60,   -- Studs par seconde (plus haut = plus rapide)
    StepSize        = 0.5,  -- Taille de chaque pas (plus petit = collecte plus fiable)
    MoveTimeout     = 10,   -- Timeout max en secondes par item
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
    return item and item.Parent ~= nil and GetItemPosition(item) ~= nil
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

    while tick() < deadline and getgenv().Settings.AutoBallonEnabled do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then return false end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        -- Désactiver le PlatformStand pour éviter que le perso tombe
        if Humanoid then
            Humanoid.PlatformStand = false
            -- Empêcher Roblox de corriger la position (anti-correction physique)
            Humanoid.AutoRotate = false
        end

        local currentPos = Root.Position
        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude

        -- Arrivé à portée de collecte → succès
        if distance <= Settings.CollectRange then
            if Humanoid then Humanoid.AutoRotate = true end
            return true
        end

        -- Calculer le prochain pas
        local stepDist = math.min(Settings.StepSize, distance)
        local nextPos  = currentPos + direction.Unit * stepDist

        -- Déplacer via CFrame (traverse les murs, pas de physique)
        -- On conserve l'orientation actuelle du perso
        Root.CFrame = CFrame.new(nextPos) * (Root.CFrame - Root.CFrame.Position)

        -- Délai basé sur la vitesse (StepSize / GlideSpeed = temps par pas)
        task.wait(Settings.StepSize / Settings.GlideSpeed)
    end

    -- Rétablir AutoRotate en cas de timeout
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then Humanoid.AutoRotate = true end

    return false -- Timeout
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
                    -- Snapshot de la position AVANT de glisser
                    -- (au cas où l'item bouge, ex: BeachBall)
                    local reached = GlideTo(targetPos)

                    if not reached then
                        -- Timeout → blacklist temporaire
                        blacklist[Target] = tick() + getgenv().Settings.BlacklistDuration
                    end
                end
            else
                -- Aucun item dispo, on vide la blacklist et on attend
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

print("Script MM2 chargé avec succès !")
