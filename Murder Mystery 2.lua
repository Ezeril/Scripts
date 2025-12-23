local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- --- CHARGEMENT DE LA LIBRAIRIE RAYFIELD (Celle-ci fonctionne 100%) ---
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 | Lunaris (Fixed)",
   LoadingTitle = "Lunaris Interface",
   LoadingSubtitle = "by OpenAI",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "LunarisConfig"
   },
   KeySystem = false,
})

-- --- VARIABLES GLOBALES ---
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 16,
    SearchRadius = 300,
    FarmSpeed = 0 -- 0 = Instantané, >0 = Tween
}

local touchedCoins = {}
local coinContainer = nil

-- --- FONCTIONS UTILITAIRES ---

local function IsAlive(model)
    return model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0
end

local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    local potentialNames = {"CoinContainer", "ConfettiContainer", "Drops", "CandyContainer"}
    for _, name in pairs(potentialNames) do
        local found = Workspace:FindFirstChild(name, true)
        if found then
            coinContainer = found
            return found
        end
    end
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "Normal" and v:FindFirstChild("Coin") then
            return v
        end
    end
    return nil
end

-- --- FONCTION ANTI-CRASH (BAG FULL) ---
local function IsBagFull()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return false end

    -- Gestion Majuscule/Minuscule pour MainGUI
    local gui = playerGui:FindFirstChild("MainGUI") or playerGui:FindFirstChild("MainGui")
    if not gui then return false end

    local bagFull = false
    
    local success, _ = pcall(function()
        -- Recherche sécurisée du conteneur de pièces
        local gameFrame = gui:FindFirstChild("Game")
        if gameFrame then
            local container = gameFrame.CoinBags.Container
            for _, currencyFrame in pairs(container:GetChildren()) do
                if currencyFrame:IsA("Frame") and currencyFrame:FindFirstChild("CurrencyFrame") then
                    local textLabel = currencyFrame.CurrencyFrame.Icon.Coins
                    local currentAmt = tonumber(textLabel.Text) or 0
                    local maxAmt = LocalPlayer:GetAttribute("Elite") and 50 or 40
                    
                    if currentAmt >= maxAmt then
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
        if firetouchinterest then
            firetouchinterest(hrp, part, 0)
            task.wait()
            firetouchinterest(hrp, part, 1)
        else
            local oldPos = hrp.CFrame
            hrp.CFrame = part.CFrame
            task.wait(0.1)
            hrp.CFrame = oldPos
        end
    end
end

-- --- CRÉATION DES ONGLETS ---

local MainTab = Window:CreateTab("Auto Farm", 4483362458) -- Icone Farm
local MiscTab = Window:CreateTab("Divers", 4483362458)

-- --- SECTION FARM ---

MainTab:CreateToggle({
   Name = "Auto Farm Candy/Coins",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
        Settings.AutoFarm = Value
        
        if Value then
            task.spawn(function()
                while Settings.AutoFarm do
                    task.wait()
                    local character = LocalPlayer.Character
                    if not IsAlive(character) then 
                        task.wait(1)
                        continue 
                    end

                    -- Vérification du sac plein
                    if IsBagFull() then
                        Rayfield:Notify({
                           Title = "Sac Plein",
                           Content = "Réinitialisation du personnage...",
                           Duration = 3,
                           Image = 4483362458,
                        })
                        character:BreakJoints()
                        
                        local respawnStart = tick()
                        repeat task.wait(1) until IsAlive(LocalPlayer.Character) or tick() - respawnStart > 10
                        task.wait(1.5)
                        table.clear(touchedCoins)
                        continue
                    end

                    -- Recherche des pièces
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

                    -- Mouvement
                    if nearest then
                        local coinPos = nearest.Position
                        
                        if Settings.WalkSpeed > 0 then
                            -- Tween
                            local time = (hrp.Position - coinPos).Magnitude / math.max(16, Settings.WalkSpeed)
                            local ti = TweenInfo.new(math.max(time, 0.05), Enum.EasingStyle.Linear)
                            local tween = TweenService:Create(hrp, ti, {CFrame = CFrame.new(coinPos)})
                            tween:Play()
                            
                            local t0 = tick()
                            local reached = false
                            while tick() - t0 < time do
                                if not Settings.AutoFarm or not nearest.Parent then 
                                    tween:Cancel()
                                    break 
                                end
                                if (hrp.Position - coinPos).Magnitude < 3 then
                                    reached = true
                                    break
                                end
                                RunService.Heartbeat:Wait()
                            end
                        else
                            hrp.CFrame = CFrame.new(coinPos)
                        end

                        FireTouch(nearest)
                        touchedCoins[nearest] = true
                        task.wait(0.15)
                    end
                end
            end)
        else
            -- Annuler les tweens si on désactive
            for _, t in pairs(TweenService:GetTweens()) do t:Cancel() end
        end
   end,
})

MainTab:CreateSlider({
   Name = "Vitesse de Farm",
   Range = {16, 300},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 25,
   Flag = "SpeedSlider",
   Callback = function(Value)
        Settings.WalkSpeed = Value
   end,
})

MainTab:CreateSlider({
   Name = "Rayon de recherche",
   Range = {50, 2000},
   Increment = 50,
   Suffix = "Studs",
   CurrentValue = 300,
   Flag = "RadiusSlider",
   Callback = function(Value)
        Settings.SearchRadius = Value
   end,
})

-- --- SECTION DIVERS ---

MiscTab:CreateButton({
   Name = "Activer Anti-AFK",
   Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Rayfield:Notify({
           Title = "Succès",
           Content = "Anti-AFK activé !",
           Duration = 3,
           Image = 4483362458,
        })
   end,
})

MiscTab:CreateButton({
   Name = "Copier lien YouTube",
   Callback = function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
   end,
})
