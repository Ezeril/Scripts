-- =============================================
--   MM2 Auto Collect | EsohaSL Fix - v2.0
--   Corrigé par : analyse complète des bugs
-- =============================================

local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")
local VirtualUser   = game:GetService("VirtualUser")

local LocalPlayer   = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
}

-- =============================================
--   Cache du Container (évite un scan complet
--   du Workspace à chaque itération de loop)
-- =============================================
local CachedContainer = nil

local function GetCoinContainer()
    -- Si le cache est encore valide, on le réutilise directement
    if CachedContainer and CachedContainer.Parent then
        return CachedContainer
    end
    -- Sinon on scanne une seule fois et on cache le résultat
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" or v.Name == "CoinAreas" then
            CachedContainer = v
            return v
        end
    end
    return nil
end

-- =============================================
--   Trouver l'objet le plus proche
--   GetDescendants() pour les objets imbriqués
-- =============================================
local function GetNearestItem()
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Nearest    = nil
    local MinDistance = math.huge

    for _, item in pairs(Container:GetDescendants()) do
        if item.Name == "Coin_Server" or item.Name == "BeachBall" or item.Name == "CoinArea" then
            if item:IsA("BasePart") then
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
--   UI Library
-- =============================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true
))()

local Window = Library:CreateWindow("MM2 | EsohaSL Fix")
Window:Section("esohasl.net")

-- =============================================
--   Toggle : Auto Collect Coins / Ball
-- =============================================
Window:Toggle("Auto Collect Coins/Ball", {}, function(state)
    getgenv().Settings.AutoBallonEnabled = state

    if state then
        task.spawn(function()
            while getgenv().Settings.AutoBallonEnabled do

                -- Récupération sécurisée du personnage à chaque cycle
                local Character = LocalPlayer.Character
                local Root = Character and Character:FindFirstChild("HumanoidRootPart")

                if Root then
                    local Target = GetNearestItem()

                    -- Double check : la cible existe encore ? (peut avoir été collectée)
                    if Target and Target.Parent then

                        -- ✅ Téléportation directe : évite le conflit avec le moteur physique
                        -- On utilise uniquement la Position pour ne pas hériter
                        -- de la rotation bizarre de la pièce/ballon
                        Root.CFrame = CFrame.new(Target.Position)

                        task.wait(0.15) -- Délai pour s'assurer de la collecte
                    end
                end

                task.wait(0.2) -- Pause entre chaque cycle de scan
            end
        end)
    end
end)

-- =============================================
--   Bouton : Copier lien YouTube
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

print("✅ Script MM2 mis à jour avec succès !")
