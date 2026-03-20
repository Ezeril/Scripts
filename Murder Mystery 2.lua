-- =============================================
--   MM2 Auto Collect | EsohaSL Fix - v4.0
--   Fix : détection universelle + glissement lerp
-- =============================================

local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    LerpSpeed = 0.2,       -- Vitesse de glissement (0.1 = lent, 0.3 = rapide)
    CollectDistance = 4,   -- Distance (studs) pour considérer la pièce collectée
}

-- =============================================
--   Cache du Container
-- =============================================
local CachedContainer = nil

local function GetCoinContainer()
    if CachedContainer and CachedContainer.Parent then
        return CachedContainer
    end
    -- Scan unique, résultat mis en cache
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            CachedContainer = v
            return v
        end
    end
    return nil
end

-- =============================================
--   Vérifier si une pièce est encore disponible
--   Sans filtre par nom → universel peu importe la map
-- =============================================
local function IsItemValid(item)
    if not item or not item.Parent then return false end
    if not item:IsA("BasePart") then return false end
    if item.Transparency >= 0.9 then return false end  -- Invisible = déjà prise
    return true
end

-- =============================================
--   Trouver la pièce la plus proche et valide
--   GetChildren() : les pièces sont enfants directs
-- =============================================
local function GetNearestItem()
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Nearest     = nil
    local MinDistance = math.huge

    -- ✅ GetChildren() suffit : workspace.Factory.CoinContainer:GetChildren()
    for _, item in pairs(Container:GetChildren()) do
        if IsItemValid(item) then
            local distance = (item.Position - Root.Position).Magnitude
            if distance < MinDistance then
                MinDistance = distance
                Nearest = item
            end
        end
    end

    return Nearest
end

-- =============================================
--   Glissement fluide via lerp CFrame
--   Pas de conflit moteur physique, mouvement visible
-- =============================================
local function GlideTo(target)
    local timeout = tick() + 4  -- Sécurité max 4 secondes par pièce

    while tick() < timeout do
        -- Récupération fraîche à chaque frame
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")

        if not Root then break end

        -- La pièce a disparu ou été collectée → on arrête
        if not IsItemValid(target) then break end

        local TargetPos = target.Position
        local Distance  = (TargetPos - Root.Position).Magnitude

        -- Assez proche → collectée, on passe à la suivante
        if Distance <= getgenv().Settings.CollectDistance then break end

        -- ✅ Lerp fluide vers la cible (glissement progressif)
        Root.CFrame = Root.CFrame:Lerp(
            CFrame.new(TargetPos),
            getgenv().Settings.LerpSpeed
        )

        task.wait() -- RunService.Heartbeat implicite
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
                        GlideTo(Target)  -- Glisse vers la pièce
                        task.wait(0.1)
                    else
                        -- Aucune pièce trouvée → on attend avant de rescanner
                        task.wait(0.5)
                    end
                else
                    task.wait(0.5)
                end
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

print("✅ Script MM2 v4.0 chargé !")
