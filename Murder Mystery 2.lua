local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- --- CHARGEMENT UI (Rayfield) ---
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 | Lunaris Elite",
   LoadingTitle = "Optimized Farm",
   LoadingSubtitle = "Anti-Crash & Noclip",
   ConfigurationSaving = {
      Enabled = false,
      FileName = "LunarisElite"
   },
   KeySystem = false,
})

-- --- CONFIGURATION ---
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 20, -- Vitesse modérée pour éviter les kicks
    SearchRadius = 1000,
    TweenSpeed = 0.8, -- Facteur de vitesse du tween (plus bas = plus rapide)
}

-- Variables internes
local CoinContainer = nil
local FarmLoop = nil
local NoclipConnection = nil
local CurrentTween = nil

-- --- FONCTIONS SYSTÈME ---

-- Fonction Noclip (Traverser les murs)
local function EnableNoclip()
    if NoclipConnection then return end
    NoclipConnection = RunService.Stepped:Connect(function()
        if Settings.AutoFarm and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

-- Fonction pour flotter (éviter de tomber sous la map)
local function ToggleFloat(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if state then
        local bv = hrp:FindFirstChild("FarmVelocity") or Instance.new("BodyVelocity")
        bv.Name = "FarmVelocity"
        bv.Parent = hrp
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        hrp.Anchored = false 
    else
        local bv = hrp:FindFirstChild("FarmVelocity")
        if bv then bv:Destroy() end
    end
end

-- Trouver le conteneur (Optimisé : mis en cache)
local function GetContainer()
    if CoinContainer and CoinContainer.Parent then return CoinContainer end
    
    -- Liste des noms possibles pour l'event de Noël et normal
    local names = {"CoinContainer", "ConfettiContainer", "Drops", "CandyContainer", "TokenContainer"}
    
    for _, name in pairs(names) do
        local target = Workspace:FindFirstChild(name, true)
        if target then
            CoinContainer = target
            return target
        end
    end

    -- Recherche profonde si non trouvé (uniquement si nécessaire)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "SnowToken" or obj.Name == "Coin") and obj:IsA("BasePart") then
            CoinContainer = obj.Parent
            return CoinContainer
        end
    end
    return nil
end

-- Vérification Sac Plein (Robuste)
local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI") or LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    if not gui then return false end
    
    local full = false
    local success, _ = pcall(function()
        local container = gui.Game.CoinBags.Container
        for _, folder in pairs(container:GetChildren()) do
            if folder:FindFirstChild("CurrencyFrame") then
                local txt = folder.CurrencyFrame.Icon.Coins.Text
                local count = tonumber(txt) or 0
                local limit = LocalPlayer:GetAttribute("Elite") and 50 or 40
                if count >= limit then full = true end
            end
        end
    end)
    return full
end

-- --- LOGIQUE DE FARM (OPTIMISÉE) ---

local function FarmStep()
    -- 1. Vérifications de base
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
        return
    end
    if char.Humanoid.Health <= 0 then return end

    -- 2. Gestion Sac Plein
    if IsBagFull() then
        -- On arrête le mouvement avant de reset
        if CurrentTween then CurrentTween:Cancel() end
        ToggleFloat(false)
        
        Rayfield:Notify({Title = "Sac Plein", Content = "Reset...", Duration = 2})
        char:BreakJoints()
        
        -- Pause intelligente jusqu'au respawn
        while task.wait(0.5) do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                break
            end
        end
        task.wait(1)
        return
    end

    -- 3. Recherche de la pièce la plus proche
    local container = GetContainer()
    if not container then return end

    local hrp = char.HumanoidRootPart
    local nearestCoin = nil
    local minDst = Settings.SearchRadius

    -- On scanne une seule fois le dossier
    local children = container:GetChildren()
    for i = 1, #children do
        local coin = children[i]
        if coin.Name == "SnowToken" or coin.Name == "Coin" or coin.Name == "Candy" then
            -- Vérifier si c'est un modèle ou une part
            local coinPos = nil
            if coin:IsA("BasePart") then 
                coinPos = coin.Position 
            elseif coin:IsA("Model") then
                coinPos = coin:GetPivot().Position
            end

            if coinPos and coin.Transparency < 1 then
                local dst = (hrp.Position - coinPos).Magnitude
                if dst < minDst then
                    minDst = dst
                    nearestCoin = coin
                end
            end
        end
    end

    -- 4. Déplacement (Tween + Noclip + Float)
    if nearestCoin then
        local targetPos = nearestCoin:IsA("Model") and nearestCoin:GetPivot().Position or nearestCoin.Position
        
        -- Calcul du temps pour une vitesse constante
        local speed = math.max(20, Settings.WalkSpeed)
        local distance = (hrp.Position - targetPos).Magnitude
        local time = distance / speed
        
        -- Sécurité Tween (Minimum 0.1s)
        if time < 0.1 then time = 0.1 end

        -- Création du Tween
        local tInfo = TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        CurrentTween = TweenService:Create(hrp, tInfo, {CFrame = CFrame.new(targetPos)})
        
        EnableNoclip() -- Traverser les murs
        ToggleFloat(true) -- Ne pas tomber

        CurrentTween:Play()
        
        -- On attend la fin du tween ou la disparition de la pièce
        local startTime = tick()
        local arrived = false
        
        while tick() - startTime < time + 0.2 do
            if not Settings.AutoFarm or not nearestCoin.Parent then 
                CurrentTween:Cancel()
                break 
            end
            
            -- Si on est très proche, on simule le toucher
            if (hrp.Position - targetPos).Magnitude < 4 then
                arrived = true
                break
            end
            RunService.Heartbeat:Wait()
        end

        -- Collecte
        if arrived and nearestCoin.Parent then
            local touchPart = nearestCoin:IsA("Model") and (nearestCoin.PrimaryPart or nearestCoin:FindFirstChildWhichIsA("BasePart")) or nearestCoin
            if touchPart then
                -- Double méthode : TP final précis + FireTouch
                hrp.CFrame = touchPart.CFrame
                if firetouchinterest then
                    firetouchinterest(hrp, touchPart, 0)
                    firetouchinterest(hrp, touchPart, 1)
                end
            end
            task.wait(0.05) -- Petit délai technique
        end
    end
end

-- --- INTERFACE ---

local MainTab = Window:CreateTab("Auto Farm", 4483362458)

MainTab:CreateToggle({
   Name = "Activer Auto Farm (Pro)",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
        Settings.AutoFarm = Value
        
        if Value then
            -- Démarrage de la boucle optimisée
            task.spawn(function()
                while Settings.AutoFarm do
                    local success, err = pcall(FarmStep)
                    if not success then
                        warn("Erreur Farm: " .. tostring(err))
                        task.wait(1)
                    end
                    RunService.Heartbeat:Wait() -- Attend la frame suivante (Ultra rapide mais stable)
                end
            end)
        else
            -- Nettoyage complet
            if CurrentTween then CurrentTween:Cancel() end
            DisableNoclip()
            ToggleFloat(false)
            
            -- Remettre le personnage au sol proprement
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            end
        end
   end,
})

MainTab:CreateSlider({
   Name = "Vitesse de déplacement",
   Range = {20, 80},
   Increment = 1,
   CurrentValue = 35,
   Callback = function(Value)
        Settings.WalkSpeed = Value
   end,
})

MainTab:CreateSlider({
   Name = "Rayon de détection",
   Range = {100, 3000},
   Increment = 100,
   CurrentValue = 1000,
   Callback = function(Value)
        Settings.SearchRadius = Value
   end,
})

-- Section Misc
local MiscTab = Window:CreateTab("Options", 4483362458)

MiscTab:CreateButton({
   Name = "Anti-AFK (Sécurité)",
   Callback = function()
        LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        Rayfield:Notify({Title = "Anti-AFK", Content = "Activé", Duration = 3})
   end,
})
