local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- --- CHARGEMENT UI ---
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 | Lunaris Unstuck",
   LoadingTitle = "Version Anti-Blocage",
   LoadingSubtitle = "Auto Farm Fix",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

-- --- CONFIGURATION ---
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 22,
    SearchRadius = 3000,
}

local CoinContainer = nil
local CurrentTween = nil
local NoclipConnection = nil

-- --- FONCTIONS ---

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

local function ToggleFloat(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state then
        local bv = hrp:FindFirstChild("FarmVelocity") or Instance.new("BodyVelocity")
        bv.Name = "FarmVelocity"
        bv.Parent = hrp
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    else
        local bv = hrp:FindFirstChild("FarmVelocity")
        if bv then bv:Destroy() end
    end
end

local function GetContainer()
    if CoinContainer and CoinContainer.Parent then return CoinContainer end
    local names = {"CoinContainer", "ConfettiContainer", "Drops", "CandyContainer", "TokenContainer"}
    for _, name in pairs(names) do
        local target = Workspace:FindFirstChild(name, true)
        if target then CoinContainer = target return target end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "SnowToken" or obj.Name == "Coin") and obj:IsA("BasePart") then
            CoinContainer = obj.Parent
            return CoinContainer
        end
    end
    return nil
end

local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI") or LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    if not gui then return false end
    local full = false
    pcall(function()
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

-- --- LOGIQUE FARM ---
local function FarmStep()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then return end
    local hrp = char.HumanoidRootPart

    -- 1. Reset si sac plein
    if IsBagFull() then
        if CurrentTween then CurrentTween:Cancel() end
        ToggleFloat(false)
        char:BreakJoints()
        task.wait(4) -- Attente simple
        return
    end

    -- 2. Trouver pièce
    local container = GetContainer()
    if not container then return end

    local nearestCoin = nil
    local minDst = Settings.SearchRadius

    for _, coin in ipairs(container:GetChildren()) do
        if (coin.Name == "SnowToken" or coin.Name == "Coin" or coin.Name == "Candy") then
            -- Vérif distance
            local coinPos = coin:IsA("Model") and coin:GetPivot().Position or coin.Position
            
            -- Ignorer les pièces trop loin ou invisibles
            local dst = (hrp.Position - coinPos).Magnitude
            local visible = true
            if coin:IsA("BasePart") and coin.Transparency == 1 then visible = false end
            
            if dst < minDst and visible then
                minDst = dst
                nearestCoin = coin
            end
        end
    end

    -- 3. Go !
    if nearestCoin then
        local targetPos = nearestCoin:IsA("Model") and nearestCoin:GetPivot().Position or nearestCoin.Position
        
        -- Calcul vitesse
        local speed = math.max(20, Settings.WalkSpeed)
        local time = (hrp.Position - targetPos).Magnitude / speed
        if time < 0.1 then time = 0.1 end

        EnableNoclip()
        ToggleFloat(true)

        local tInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
        CurrentTween = TweenService:Create(hrp, tInfo, {CFrame = CFrame.new(targetPos)})
        CurrentTween:Play()

        -- Attente arrivée (avec sécurité)
        local tStart = tick()
        while tick() - tStart < time + 0.1 do
            if not Settings.AutoFarm or not nearestCoin.Parent then CurrentTween:Cancel() break end
            RunService.Heartbeat:Wait()
        end

        -- 4. COLLECTE AVEC TIMEOUT (C'est ça qui corrige le bug)
        if nearestCoin.Parent then
            hrp.CFrame = CFrame.new(targetPos) -- TP Final
            
            local touchPart = nearestCoin
            if nearestCoin:IsA("Model") then
                touchPart = nearestCoin.PrimaryPart or nearestCoin:FindFirstChildWhichIsA("BasePart")
            end

            if touchPart then
                -- On essaie de collecter pendant MAX 0.8 secondes
                local timeout = tick()
                while nearestCoin.Parent and tick() - timeout < 0.8 do
                    if firetouchinterest then
                        firetouchinterest(hrp, touchPart, 0)
                        firetouchinterest(hrp, touchPart, 1)
                    end
                    -- Petite danse pour forcer la collision
                    hrp.CFrame = CFrame.new(targetPos) * CFrame.new(0, 0.5, 0)
                    RunService.Heartbeat:Wait()
                    hrp.CFrame = CFrame.new(targetPos)
                end
                -- Si après 0.8s la pièce est toujours là, ON L'ABANDONNE et on passe à la suite
            end
        end
    end
end

-- --- UI ---
local MainTab = Window:CreateTab("Farm", 4483362458)

MainTab:CreateToggle({
   Name = "Activer Auto Farm",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
        Settings.AutoFarm = Value
        if Value then
            task.spawn(function()
                while Settings.AutoFarm do
                    local s, e = pcall(FarmStep)
                    if not s then 
                        warn(e) 
                        task.wait(1) -- Pause en cas d'erreur
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            if CurrentTween then CurrentTween:Cancel() end
            ToggleFloat(false)
            if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("HumanoidRootPart") then c.HumanoidRootPart.Velocity = Vector3.new(0,0,0) end
        end
   end,
})

MainTab:CreateSlider({
   Name = "Vitesse",
   Range = {16, 100},
   Increment = 1,
   CurrentValue = 25,
   Callback = function(Value) Settings.WalkSpeed = Value end,
})
