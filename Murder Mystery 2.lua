-- =============================================
--   MM2 Auto Collect | EsohaSL Fix - v3.0
--   Fix : pièces déjà récupérées + glissement fluide
-- =============================================

local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
}

-- Cache du Container
local CachedContainer = nil

local function GetCoinContainer()
    if CachedContainer and CachedContainer.Parent then
        return CachedContainer
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" or v.Name == "CoinAreas" then
            CachedContainer = v
            return v
        end
    end
    return nil
end

-- =============================================
--   Vérifier si une pièce est encore VALIDE
--   (non récupérée, visible, encore dans le jeu)
-- =============================================
local function IsItemValid(item)
    if not item or not item.Parent then return false end
    if not item:IsA("BasePart") then return false end

    -- Si transparente = déjà récupérée ou en train de disparaître
    if item.Transparency >= 0.9 then return false end

    -- Vérification optionnelle d'un attribut "Active" si MM2 l'utilise
    local active = item:GetAttribute("Active")
    if active ~= nil and active == false then return false end

    return true
end

-- =============================================
--   Trouver l'objet le plus proche ET valide
-- =============================================
local function GetNearestItem()
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Nearest     = nil
    local MinDistance = math.huge

    for _, item in pairs(Container:GetDescendants()) do
        if item.Name == "Coin_Server" or item.Name == "BeachBall" or item.Name == "CoinArea" then
            -- ✅ On ne cible que les pièces encore valides
            if IsItemValid(item) then
                local distance = (item.Position - Root.Position).Magnitude
                if distance < MinDistance then
                    MinDistance = distance
                    Nearest = item
                end
            end
        end
    end

    return Nearest
end

-- =============================================
--   Glissement fluide vers la cible
--   via Humanoid:MoveTo() (marche naturelle)
-- =============================================
local function SmoothMoveTo(target)
    local Character = LocalPlayer.Character
    if not Character then return end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root     = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not Root then return end

    -- On se déplace vers la pièce
    Humanoid:MoveTo(target.Position)

    -- Attente d'arrivée avec timeout de 3 secondes
    -- (évite de rester bloqué si la pièce disparaît en route)
    local arrived  = false
    local timeout  = tick() + 3

    local conn
    conn = Humanoid.MoveToFinished:Connect(function()
        arrived = true
        conn:Disconnect()
    end)

    -- Boucle d'attente : on annule si la pièce disparaît ou timeout
    while not arrived and tick() < timeout do
        if not IsItemValid(target) then
            -- La pièce a été récupérée en route → on annule le mouvement
            Humanoid:MoveTo(Root.Position)
            conn:Disconnect()
            break
        end
        task.wait(0.1)
    end

    if not arrived and conn then
        conn:Disconnect()
    end
end

-- =============================================
--   UI Library
-- =============================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true
))()

local Window = Library:CreateWindow("MM2 | EsohaSL Fix")
Window:Section("esohasl.net")

-- =============================================
--   Toggle : Auto Collect
-- =============================================
Window:Toggle("Auto Collect Coins/Ball", {}, function(state)
    getgenv().Settings.AutoBallonEnabled = state

    if state then
        task.spawn(function()
            while getgenv().Settings.AutoBallonEnabled do
                local Character = LocalPlayer.Character
                local Root = Character and Character:FindFirstChild("HumanoidRootPart")

                if Root then
                    local Target = GetNearestItem()

                    if Target then
                        -- ✅ Glissement fluide, annulé si la pièce disparaît
                        SmoothMoveTo(Target)
                        task.wait(0.1)
                    end
                end

                task.wait(0.2)
            end
        end)
    end
end)

-- =============================================
--   Bouton : Lien YouTube
-- =============================================
Window:Button("YouTube: EsohaSL", function()
    if setclipboard then
        setclipboard("https://youtube.com/@esohasl")
    end
end)

-- =============================================
--   Anti-AFK
-- =============================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

print("✅ Script MM2 v3.0 chargé avec succès !")
