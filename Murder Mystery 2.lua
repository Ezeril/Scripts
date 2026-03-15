local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoBallonEnabled = false,
    TweenSpeed = 1.5 -- Temps pour aller à l'objet (plus bas = plus rapide)
}

-- Fonction dynamique pour trouver le dossier des pièces/ballons sur n'importe quelle map
local function GetCoinContainer()
    -- On cherche un objet nommé "CoinContainer" dans le Workspace (vu dans tes logs F9)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" or v.Name == "CoinAreas" then
            return v
        end
    end
    return nil
end

-- Obtenir l'objet (Pièce ou Ballon) le plus proche
local function GetNearestItem()
    local Container = GetCoinContainer()
    if not Container then return nil end

    local Nearest = nil
    local MinDistance = math.huge
    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")

    if not Root then return nil end

    for _, item in pairs(Container:GetChildren()) do
        -- On cible "Coin_Server" ou "BeachBall" d'après tes scans
        if item.Name == "Coin_Server" or item.Name == "BeachBall" or item.Name == "CoinArea" then
            -- Vérifier si l'objet a une position physique
            local pos = item:IsA("BasePart") and item.Position or item:GetPivot().Position
            local distance = (pos - Root.Position).Magnitude
            
            if distance < MinDistance then
                MinDistance = distance
                Nearest = item
            end
        end
    end

    return Nearest
end

-- Library UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL Fix")

Window:Section("esohasl.net")

-- Toggle Auto Collect
Window:Toggle("Auto Collect Coins/Ball", {}, function(state)
    getgenv().Settings.AutoBallonEnabled = state
    
    if state then
        task.spawn(function()
            while getgenv().Settings.AutoBallonEnabled do
                -- Dans MM2, on vérifie souvent si le joueur est en jeu via son équipe ou un attribut
                local isAlive = LocalPlayer:GetAttribute("Alive") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
                
                if isAlive then
                    local Target = GetNearestItem()

                    if Target then
                        local Root = LocalPlayer.Character.HumanoidRootPart
                        local TargetPos = Target:IsA("BasePart") and Target.CFrame or Target:GetPivot()

                        local Tween = TweenService:Create(Root, TweenInfo.new(getgenv().Settings.TweenSpeed, Enum.EasingStyle.Linear), {
                            CFrame = TargetPos
                        })
                        
                        Tween:Play()
                        Tween.Completed:Wait()
                        task.wait(0.1) -- Petit délai pour être sûr de collecter
                    end
                end
                task.wait(0.2)
            end
        end)
    end
end)

-- Copier le lien YouTube
Window:Button("YouTube: EsohaSL", function()
    if setclipboard then
        setclipboard("https://youtube.com/@esohasl")
    end
end)

-- Anti-AFK (Idle)
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

print("Script MM2 mis à jour avec succès !")
