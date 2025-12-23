local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- --- CONFIGURATION DE LA LIBRAIRIE ORION ---
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "MM2 | Lunaris Fixed", 
    HidePremium = false, 
    SaveConfig = false, 
    ConfigFolder = "LunarisMM2",
    IntroEnabled = true,
    IntroText = "Lunaris Script"
})

-- --- VARIABLES GLOBALES ---
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 16,
    SearchRadius = 300,
    FarmSpeed = 0 -- 0 = Instantané (TP), >0 = Tween
}

local touchedCoins = {}
local coinContainer = nil

-- --- FONCTIONS UTILITAIRES ---

local function IsAlive(model)
    return model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0
end

local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    -- Cherche les noms communs des conteneurs de pièces dans MM2
    local potentialNames = {"CoinContainer", "ConfettiContainer", "Drops", "CandyContainer"}
    for _, name in pairs(potentialNames) do
        local found = Workspace:FindFirstChild(name, true) -- Recherche récursive
        if found then
            coinContainer = found
            return found
        end
    end
    -- Fallback : cherche par contenu
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "Normal" and v:FindFirstChild("Coin") then -- Parfois dans Workspace.Normal
            return v
        end
    end
    return nil
end

-- --- CORRECTION DE L'ERREUR "MAINGUI" ---
local function IsBagFull()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return false end

    -- Tente de trouver MainGUI ou MainGui (Règle ton erreur d'image)
    local gui = playerGui:FindFirstChild("MainGUI") or playerGui:FindFirstChild("MainGui")
    if not gui then return false end

    local bagFull = false
    
    -- Utilisation de pcall pour éviter que le script crash si l'UI change
    local success, _ = pcall(function()
        local container = gui.Game.CoinBags.Container
        -- On cherche n'importe quelle monnaie active (SnowToken, Candy, Coins...)
        for _, currencyFrame in pairs(container:GetChildren()) do
            if currencyFrame:IsA("Frame") and currencyFrame:FindFirstChild("CurrencyFrame") then
                local textLabel = currencyFrame.CurrencyFrame.Icon.Coins
                local currentAmt = tonumber(textLabel.Text) or 0
                
                -- Vérifie si Elite (50 max) ou Normal (40 max)
                local maxAmt = LocalPlayer:GetAttribute("Elite") and 50 or 40
                
                if currentAmt >= maxAmt then
                    bagFull = true
                end
            end
        end
    end)

    return bagFull
end

local function FireTouch(part)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp and part then
        -- Méthode 1 : FireTouchInterest (Plus discret)
        if firetouchinterest then
            firetouchinterest(hrp, part, 0)
            task.wait()
            firetouchinterest(hrp, part, 1)
        else
            -- Méthode 2 : Toucher physique (Si l'exécuteur est faible)
            local oldPos = hrp.CFrame
            hrp.CFrame = part.CFrame
            task.wait(0.1)
            hrp.CFrame = oldPos
        end
    end
end

-- --- ONGLET PRINCIPAL ---

local MainTab = Window:MakeTab({
    Name = "Auto Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Auto Farm Candy/Coins",
    Default = false,
    Callback = function(Value)
        Settings.AutoFarm = Value
        
        if Value then
            task.spawn(function()
                while Settings.AutoFarm do
                    task.wait() -- Anti-crash
                    
                    local character = LocalPlayer.Character
                    if not IsAlive(character) then 
                        task.wait(1)
                        continue 
                    end

                    -- 1. Vérifier si le sac est plein
                    if IsBagFull() then
                        OrionLib:MakeNotification({Name = "Sac Plein", Content = "Réinitialisation...", Time = 3})
                        character:BreakJoints() -- Reset rapide
                        
                        -- Attendre le respawn complet
                        local respawnStart = tick()
                        repeat task.wait(1) until IsAlive(LocalPlayer.Character) or tick() - respawnStart > 10
                        task.wait(1) -- Pause de sécurité après respawn
                        table.clear(touchedCoins) -- Oublier les pièces collectées
                        continue
                    end

                    -- 2. Trouver la pièce la plus proche
                    local container = GetContainer()
                    if not container then continue end

                    local hrp = character.HumanoidRootPart
                    local nearest = nil
                    local minDst = Settings.SearchRadius

                    for _, coin in ipairs(container:GetChildren()) do
                        if coin:IsA("BasePart") and coin.Transparency < 1 and not touchedCoins[coin] then
                            local dst = (hrp.Position - coin.Position).Magnitude
                            if dst < minDst then
                                minDst = dst
                                nearest = coin
                            end
                        end
                    end

                    -- 3. Aller vers la pièce
                    if nearest then
                        local coinPos = nearest.Position
                        
                        -- TP ou Tween vers la pièce
                        if Settings.FarmSpeed > 0 then
                            -- Tween (Mouvement fluide)
                            local time = (hrp.Position - coinPos).Magnitude / Settings.WalkSpeed
                            local ti = TweenInfo.new(math.max(time, 0.1), Enum.EasingStyle.Linear)
                            local tween = TweenService:Create(hrp, ti, {CFrame = CFrame.new(coinPos)})
                            tween:Play()
                            tween.Completed:Wait()
                        else
                            -- TP Instantané (Plus rapide mais risqué)
                            hrp.CFrame = CFrame.new(coinPos)
                        end

                        -- 4. Collecter
                        FireTouch(nearest)
                        touchedCoins[nearest] = true
                        task.wait(0.1) -- Délai pour éviter le kick
                    end
                end
            end)
        else
            -- Arrêt
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Annuler les mouvements en cours
                for _, t in pairs(TweenService:GetTweens()) do t:Cancel() end
            end
        end
    end    
})

MainTab:AddSlider({
    Name = "Vitesse de marche (si Tween)",
    Min = 16,
    Max = 100,
    Default = 25,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        Settings.WalkSpeed = Value
    end    
})

MainTab:AddSlider({
    Name = "Rayon de recherche",
    Min = 50,
    Max = 1000,
    Default = 300,
    Color = Color3.fromRGB(255,255,255),
    Increment = 50,
    ValueName = "Studs",
    Callback = function(Value)
        Settings.SearchRadius = Value
    end    
})

-- --- ONGLET MISC ---

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddButton({
    Name = "Activer Anti-AFK",
    Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        OrionLib:MakeNotification({Name = "Anti-AFK", Content = "Activé avec succès", Time = 3})
    end    
})

OrionLib:Init()
