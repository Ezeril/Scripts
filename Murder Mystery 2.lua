local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- --- CHARGEMENT DE LA LIBRAIRIE RAYFIELD ---
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 | Winter Event Farm",
   LoadingTitle = "Lunaris Updated",
   LoadingSubtitle = "Auto Farm Tokens",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "LunarisWinter"
   },
   KeySystem = false,
})

-- --- VARIABLES ---
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 16,
    SearchRadius = 500,
    FarmSpeed = 0
}

local touchedCoins = {}
local coinContainer = nil

-- --- FONCTIONS ---

local function IsAlive(model)
    return model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0
end

-- Fonction améliorée pour trouver le conteneur, peu importe le nom (CoinContainer, Drops, etc.)
local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    
    -- 1. Chercher par nom standard
    local potentialNames = {"CoinContainer", "ConfettiContainer", "Drops", "CandyContainer", "TokenContainer"}
    for _, name in pairs(potentialNames) do
        local found = Workspace:FindFirstChild(name, true)
        if found then
            coinContainer = found
            return found
        end
    end

    -- 2. Chercher dynamiquement un dossier qui contient des "SnowToken"
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") then
            if child:FindFirstChild("SnowToken") or child:FindFirstChild("Coin") then
                coinContainer = child
                return child
            end
        end
    end
    
    return nil
end

-- Fonction universelle pour lire le sac (Candy, Token, Coins...)
local function IsBagFull()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return false end

    local gui = playerGui:FindFirstChild("MainGUI") or playerGui:FindFirstChild("MainGui")
    if not gui then return false end

    local bagFull = false
    
    pcall(function()
        -- On scanne tous les dossiers dans CoinBags (SnowToken, Candy, etc.)
        local container = gui.Game.CoinBags.Container
        for _, currencyFolder in pairs(container:GetChildren()) do
            if currencyFolder:FindFirstChild("CurrencyFrame") then
                local label = currencyFolder.CurrencyFrame.Icon.Coins
                if label then
                    local current = tonumber(label.Text) or 0
                    local max = LocalPlayer:GetAttribute("Elite") and 50 or 40
                    if current >= max then
                        bagFull = true
                    end
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
        -- On essaie de toucher le PrimaryPart si c'est un modèle
        local target = part
        if part:IsA("Model") then
            target = part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart")
        end

        if target then
            if firetouchinterest then
                firetouchinterest(hrp, target, 0)
                task.wait()
                firetouchinterest(hrp, target, 1)
            else
                local oldPos = hrp.CFrame
                hrp.CFrame = target.CFrame
                task.wait(0.1)
                hrp.CFrame = oldPos
            end
        end
    end
end

-- --- INTERFACE ---

local MainTab = Window:CreateTab("Farm", 4483362458)

MainTab:CreateToggle({
   Name = "Auto Farm Snow Tokens",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
        Settings.AutoFarm = Value
        
        if Value then
            task.spawn(function()
                while Settings.AutoFarm do
                    task.wait()
                    local character = LocalPlayer.Character
                    if not IsAlive(character) then task.wait(1) continue end

                    -- 1. Sac Plein ?
                    if IsBagFull() then
                        Rayfield:Notify({Title = "Sac Plein", Content = "Reset...", Duration = 3})
                        character:BreakJoints()
                        
                        -- Attente respawn
                        local t = tick()
                        repeat task.wait(1) until IsAlive(LocalPlayer.Character) or tick() - t > 10
                        task.wait(2)
                        table.clear(touchedCoins)
                        continue
                    end

                    -- 2. Recherche
                    local container = GetContainer()
                    if not container then continue end

                    local hrp = character.HumanoidRootPart
                    local nearest = nil
                    local minDst = Settings.SearchRadius

                    for _, item in ipairs(container:GetChildren()) do
                        -- On accepte tout (Model ou Part) tant que c'est pas déjà touché
                        if not touchedCoins[item] and (item:IsA("BasePart") or item:IsA("Model")) then
                            
                            -- Récupérer la position centrale de l'item
                            local itemPos = nil
                            if item:IsA("BasePart") then itemPos = item.Position
                            elseif item:IsA("Model") then itemPos = item:GetPivot().Position end

                            if itemPos then
                                local dst = (hrp.Position - itemPos).Magnitude
                                if dst < minDst then
                                    minDst = dst
                                    nearest = item
                                end
                            end
                        end
                    end

                    -- 3. Mouvement
                    if nearest then
                        local targetPos = nearest:IsA("Model") and nearest:GetPivot().Position or nearest.Position
                        
                        -- Tween rapide
                        local speed = math.max(16, Settings.WalkSpeed)
                        local time = (hrp.Position - targetPos).Magnitude / speed
                        local ti = TweenInfo.new(math.max(time, 0.05), Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, ti, {CFrame = CFrame.new(targetPos)})
                        
                        tween:Play()
                        local startT = tick()
                        while tick() - startT < time do
                            if not Settings.AutoFarm or not nearest.Parent then tween:Cancel() break end
                            RunService.Heartbeat:Wait()
                        end

                        FireTouch(nearest)
                        touchedCoins[nearest] = true
                        task.wait(0.1)
                    end
                end
            end)
        else
            -- Stop tween
            for _, t in pairs(TweenService:GetTweens()) do t:Cancel() end
        end
   end,
})

MainTab:CreateSlider({
   Name = "Vitesse (WalkSpeed)",
   Range = {16, 100},
   Increment = 1,
   CurrentValue = 25,
   Callback = function(Value) Settings.WalkSpeed = Value end,
})

MainTab:CreateSlider({
   Name = "Rayon de recherche",
   Range = {100, 2000},
   Increment = 50,
   CurrentValue = 500,
   Callback = function(Value) Settings.SearchRadius = Value end,
})
