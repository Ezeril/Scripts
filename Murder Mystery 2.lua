-- =============================================
--   MM2 Auto Collect | EsohaSL Fix - v6.0
--   Fix : structure réelle CoinVisual > DecalPart
--          + détection dynamique toutes maps MM2
-- =============================================

local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    LerpSpeed         = 0.18,
    CollectDistance   = 5,
}

local CachedContainer = nil

-- =============================================
--   Scan dynamique : trouve CoinContainer
--   peu importe la map (Hotel, House2, Factory...)
-- =============================================
local function GetCoinContainer()
    if CachedContainer and CachedContainer.Parent then
        return CachedContainer
    end

    -- Invalide le cache si la map a changé
    CachedContainer = nil

    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            CachedContainer = v
            print("[MM2] CoinContainer trouvé dans :", v:GetFullName())
            return v
        end
    end

    return nil
end

-- =============================================
--   Structure réelle :
--   Coin_Server (Part, Transparency=1)
--     └── CoinVisual
--           └── DecalPart (BasePart)
--   Si DecalPart absent = pièce déjà collectée
-- =============================================
local function IsItemValid(item)
    if not item or not item.Parent then return false end
    if not item:IsA("BasePart") then return false end

    local visual = item:FindFirstChild("CoinVisual")
    if not visual then return false end

    local decal = visual:FindFirstChild("DecalPart")
    if not decal then return false end

    -- DecalPart disparaît ou devient transparent quand collecté
    if decal:IsA("BasePart") and decal.Transparency >= 0.9 then return false end

    return true
end

local function GetNearestItem()
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end

    local Nearest     = nil
    local MinDistance = math.huge

    for _, item in pairs(Container:GetChildren()) do
        if item.Name == "Coin_Server" and IsItemValid(item) then
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
--   Glissement lerp
-- =============================================
local function GlideTo(target)
    local timeout = tick() + 5

    while tick() < timeout do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")

        if not Root then break end
        if not IsItemValid(target) then break end

        local distance = (target.Position - Root.Position).Magnitude
        if distance <= getgenv().Settings.CollectDistance then break end

        Root.CFrame = Root.CFrame:Lerp(
            CFrame.new(target.Position),
            getgenv().Settings.LerpSpeed
        )

        task.wait()
    end
end

-- =============================================
--   Reset du cache quand la map change
--   (le CoinContainer change à chaque round)
-- =============================================
Workspace.DescendantRemoving:Connect(function(removed)
    if removed == CachedContainer then
        CachedContainer = nil
        print("[MM2] Map changée, cache CoinContainer resetté")
    end
end)

-- =============================================
--   UI
-- =============================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true
))()

local Window = Library:CreateWindow("MM2 | EsohaSL Fix")
Window:Section("esohasl.net")

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
                        GlideTo(Target)
                        task.wait(0.1)
                    else
                        -- Aucune pièce dispo ou entre deux rounds
                        task.wait(0.5)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    end
end)

Window:Button("YouTube: EsohaSL", function()
    if setclipboard then
        setclipboard("https://youtube.com/@esohasl")
    end
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

print("✅ Script MM2 v6.0 chargé !")
