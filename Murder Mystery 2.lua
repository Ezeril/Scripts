local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Spawns") and Workspace.Lobby.Spawns:FindFirstChild("SpawnLocation")

-- Configuration par défaut
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 25,
    SearchRadius = 250, -- Augmenté pour mieux trouver les bonbons
    TpBackToStart = true,
}

local touchedCoins = {}
local startPosition = nil
local coinContainer = nil

-- --- CHARGEMENT DE LA LIBRAIRIE ORION ---
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "MM2 | Lunaris (Fixed)", 
    HidePremium = false, 
    SaveConfig = false, 
    ConfigFolder = "LunarisMM2",
    IntroEnabled = true,
    IntroText = "Lunaris"
})

-- --- FONCTIONS UTILITAIRES ---

local function IsAlive(inst)
    return inst and inst.Parent ~= nil
end

local function SafeGetPos(inst)
    if not IsAlive(inst) then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok and cf then
            return cf.Position
        else
            local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            return pp and pp.Position or nil
        end
    end
    return nil
end

local function GetTouchPart(inst)
    if not IsAlive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- Trouver le conteneur des jetons (SnowToken, Candy, etc.)
local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    -- Cherche n'importe quel conteneur de monnaie (souvent "CoinContainer" ou "ConfettiContainer")
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" or v.Name == "ConfettiContainer" then
            coinContainer = v
            return v
        end
    end
    return nil
end

-- Trouver le jeton le plus proche
local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local nearestCandy = nil
    local currentDistance = Settings.SearchRadius
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    for _, v in ipairs(container:GetChildren()) do
        if touchedCoins[v] then continue end
        if not IsAlive(v) then continue end
        if v.Transparency == 1 then continue end -- Ignorer les pièces invisibles

        local pos = SafeGetPos(v)
        if not pos then continue end

        local dist = (hrp.Position - pos).Magnitude
        
        if dist < currentDistance then
            currentDistance = dist
            nearestCandy = v
        end
    end
    return nearestCandy
end

-- Simuler l'interaction (firetouchinterest)
local function FireTouchTransmitter(touchParent)
    local character = LocalPlayer.Character
    local part = character and character:FindFirstChild("HumanoidRootPart") -- Utiliser HRP c'est plus stable
    
    if part and touchParent and IsAlive(touchParent) then
        if typeof(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(touchParent, part, 0)
                task.wait()
                firetouchinterest(touchParent, part, 1)
            end)
        else
            -- Fallback si l'exécuteur ne supporte pas firetouchinterest (téléportation simple)
            local prevCF = part.CFrame
            part.CFrame = touchParent.CFrame
            task.wait(0.1)
            part.CFrame = prevCF
        end
    end
end

-- Vérifier si le sac est plein
local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
    if not gui then return false end
    
    -- Chemin général pour MM2, peut varier selon les événements
    local ok, coinLabel = pcall(function()
        local gameFrame = gui:WaitForChild("Game", 5)
        if not gameFrame then return nil end
        -- Recherche récursive rapide pour trouver le texte des pièces
        local bags = gameFrame:FindFirstChild("CoinBags")
        if bags and bags:FindFirstChild("Container") then
             -- Adapte ceci selon l'event actuel (SnowToken, Candy, etc.)
            for _, c in pairs(bags.Container:GetChildren()) do
                if c:FindFirstChild("CurrencyFrame") then
                    return c.CurrencyFrame.Icon.Coins
                end
            end
        end
        return nil
    end)

    if ok and coinLabel and coinLabel:IsA("TextLabel") then
        local currentText = coinLabel.Text
        local price = LocalPlayer:GetAttribute("Elite") and "50" or "40"
        return tostring(currentText) == price
    end
    
    return false
end

local function AutoFarmCleanup()
    Settings.AutoFarm = false
    table.clear(touchedCoins)
    OrionLib:MakeNotification({
        Name = "Arrêt",
        Content = "AutoFarm désactivé ou sac plein.",
        Image = "rbxassetid://4483345998",
        Time = 5
    })
end

-- --- CRÉATION DE L'INTERFACE (TABS) ---

local MainTab = Window:MakeTab({
    Name = "Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- --- LOGIQUE AUTOFARM ---

MainTab:AddToggle({
    Name = "Auto Candy / Coins",
    Default = false,
    Callback = function(Value)
        Settings.AutoFarm = Value
        
        if not Value then
            AutoFarmCleanup()
            return
        end

        task.spawn(function()
            local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                startPosition = humanoidRootPart.CFrame
            elseif Spawn then
                startPosition = Spawn.CFrame
            end

            while Settings.AutoFarm do
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
                    -- Si mort, on attend le respawn
                    task.wait(1)
                    continue
                end
                
                -- Vérification sac plein
                if IsBagFull() then
                    print("Sac plein ! Reset...")
                    -- Utilisation de BreakJoints pour un reset plus propre que LoadCharacter
                    LocalPlayer.Character:BreakJoints()
                    task.wait(5) -- Attendre le respawn
                    
                    -- Réinitialiser la table des pièces touchées
                    table.clear(touchedCoins)
                    
                    -- Si on veut arrêter après un sac plein, décommenter ci-dessous:
                    -- AutoFarmCleanup() 
                    -- break
                end

                local candy = GetNearestCandy()

                if candy then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then task.wait(0.1); continue end

                    local targetPos = SafeGetPos(candy)
                    if not targetPos then task.wait(0.1); continue end

                    local distance = (hrp.Position - targetPos).Magnitude
                    
                    -- Calcul de vitesse (Tween)
                    local speed = math.max(10, Settings.WalkSpeed)
                    local time = distance / speed
                    
                    if time < 0.05 then time = 0.05 end

                    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
                    
                    tween:Play()
                    
                    -- Attendre la fin du tween ou la disparition de la pièce
                    local t0 = tick()
                    while tick() - t0 < time do
                        if not IsAlive(candy) or not Settings.AutoFarm then 
                            tween:Cancel()
                            break 
                        end
                        RunService.Heartbeat:Wait()
                    end

                    -- Collecte
                    if IsAlive(candy) then
                        local tpart = GetTouchPart(candy)
                        FireTouchTransmitter(tpart)
                        touchedCoins[candy] = true
                        task.wait(0.05) -- Petit délai pour éviter le crash
                    end
                else
                    -- Pas de bonbon trouvé, on attend un peu
                    task.wait(0.5)
                end
            end
        end)
    end    
})

MainTab:AddSlider({
    Name = "Vitesse de Farm (WalkSpeed)",
    Min = 16,
    Max = 100,
    Default = 25,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "S",
    Callback = function(Value)
        Settings.WalkSpeed = Value
    end    
})

MainTab:AddSlider({
    Name = "Rayon de recherche",
    Min = 50,
    Max = 500,
    Default = 120,
    Color = Color3.fromRGB(255,255,255),
    Increment = 10,
    ValueName = "Studs",
    Callback = function(Value)
        Settings.SearchRadius = Value
    end    
})

-- --- MISC ---

MiscTab:AddButton({
    Name = "Anti-AFK",
    Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            OrionLib:MakeNotification({Name = "Anti-AFK", Content = "AFK évité !", Time = 3})
        end)
        OrionLib:MakeNotification({Name = "Succès", Content = "Anti-AFK activé.", Time = 5})
    end    
})

MiscTab:AddButton({
    Name = "Copier lien YouTube",
    Callback = function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
            OrionLib:MakeNotification({Name = "YouTube", Content = "Lien copié dans le presse-papier.", Time = 5})
        end
    end    
})

OrionLib:Init()
