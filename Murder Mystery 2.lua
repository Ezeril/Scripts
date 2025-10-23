local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 28, -- Rapide par défaut
    SearchRadius = 120,
    TpBackToStart = true,
}

local touchedCoins = {} -- Pièces marquées collectées
local startPosition = nil
local coinContainer = nil

local function IsAlive(inst)
    return inst and inst.Parent ~= nil
end

local function SafeGetPos(inst)
    if not inst or not IsAlive(inst) then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok and cf and typeof(cf) == "CFrame" then
            return cf.Position
        else
            local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            return (pp and pp.Position) or nil
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

local function GetContainer()
    if coinContainer and coinContainer.Parent then
        return coinContainer
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            coinContainer = v
            return v
        end
    end
    return nil
end

local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local nearestCandy = nil
    local currentDistance = Settings.SearchRadius

    for _, v in ipairs(container:GetChildren()) do
        if touchedCoins[v] then continue end
        if not IsAlive(v) then continue end
        local pos = SafeGetPos(v)
        if not pos then continue end
        local ok, distance = pcall(function()
            return LocalPlayer:DistanceFromCharacter(pos)
        end)
        if ok and type(distance) == "number" and distance < currentDistance then
            currentDistance = distance
            nearestCandy = v
        end
    end
    return nearestCandy
end

local function FireTouchTransmitter(touchParent)
    local character = LocalPlayer.Character
    local part = character and character:FindFirstChildOfClass("Part")
    if part and touchParent and IsAlive(touchParent) and typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(touchParent, part, 0)
            task.wait(0.04)
            firetouchinterest(touchParent, part, 1)
        end)
    end
end

-- Move, annuler si cible disparue
local function MoveToPositionSafely(targetInstance, targetPosition, duration)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local startPos = hrp.Position
    local t0 = tick()

    while true do
        if not IsAlive(targetInstance) then
            return false
        end
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            return false
        end

        local elapsed = tick() - t0
        local alpha = math.clamp(elapsed / duration, 0, 1)
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPosition, alpha))
        if alpha >= 1 then break end
        task.wait()
    end

    if not IsAlive(targetInstance) then
        return false
    end

    hrp.CFrame = CFrame.new(targetPosition)
    return true
end

local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
    if not gui then return false end
    local ok, coinFrame = pcall(function()
        return gui.Game.CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins
    end)
    if not ok or not coinFrame then return false end
    local price = LocalPlayer:GetAttribute("Elite") and "50" or "40"
    return tostring(coinFrame.Text) == price
end

local function AutoFarmCleanup()
    Settings.AutoFarm = false
    table.clear(touchedCoins)
    if Settings.TpBackToStart and startPosition then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = startPosition
        end
    end
end

-- UI identique
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

Window:Section("esohasl.net")

Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.AutoFarm = state
        if not state then
            AutoFarmCleanup()
            return
        end

        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        startPosition = humanoidRootPart and humanoidRootPart.CFrame or (Spawn and Spawn.CFrame) or CFrame.new(0,5,0)

        while Settings.AutoFarm do
            if not LocalPlayer:GetAttribute("Alive") then
                AutoFarmCleanup()
                break
            end

            if IsBagFull() then
                print("Sac plein, arrêt de l'autofarm")
                AutoFarmCleanup()
                break
            end

            local candy = GetNearestCandy()
            if candy then
                if not IsAlive(candy) then
                    task.wait(0.03) continue end
                local pos = SafeGetPos(candy)
                if not pos then
                    task.wait(0.03) continue end

                local okDist, distance = pcall(function()
                    return LocalPlayer:DistanceFromCharacter(pos) end)
                if not okDist or type(distance)~="number" then
                    task.wait(0.03) continue end
                local duration = math.max(0.03, distance / math.max(1, Settings.WalkSpeed))

                local arrived = MoveToPositionSafely(candy, pos, duration)
                if not arrived then continue end

                if not IsAlive(candy) then continue end

                local touchPart = GetTouchPart(candy)
                if touchPart and IsAlive(touchPart) then
                    FireTouchTransmitter(touchPart)
                    task.wait(0.04)
                    if not IsAlive(candy) then
                        touchedCoins[candy] = true
                    end
                end
            else
                task.wait(0.18)
            end
        end
    end)
end)

Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
end)

GetContainer()
-- Le toggle lance tout, n’ajoute pas "AutoFarm()" ailleurs !
