-- =============================================
--   MM2 Auto Collect | EsohaSL Fix - v7.0
--   Fix : check sur MainCoin (seul enfant fiable)
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

local function GetCoinContainer()
    if CachedContainer and CachedContainer.Parent then
        return CachedContainer
    end
    CachedContainer = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            CachedContainer = v
            print("[MM2] Map détectée :", v:GetFullName())
            return v
        end
    end
    return nil
end

-- =============================================
--   ✅ Vérification sur MainCoin uniquement
--   MainCoin Transparency=0 → pièce disponible
--   MainCoin absent ou Transparency=1 → collectée
-- =============================================
local function IsItemValid(item)
    if not item or not item.Parent then return false end
    if not item:IsA("BasePart") then return false end

    local mainCoin = item:FindFirstChild("MainCoin")
    if not mainCoin then return false end
    if mainCoin.Transparency >= 0.9 then return false end

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

-- Reset cache automatique au changement de map
Workspace.DescendantRemoving:Connect(function(removed)
    if removed == CachedContainer then
        CachedContainer = nil
        print("[MM2] Nouvelle map, cache resetté")
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

print("✅ Script MM2 v7.0 chargé !")
