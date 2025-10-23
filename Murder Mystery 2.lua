local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 25,
    SearchRadius = 120,
    TpBackToStart = true,
}

local touchedCoins = {}
local startPosition = nil
local coinContainer = nil

-- helpers sûrs
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

-- Trouver le conteneur des jetons
local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            coinContainer = v
            return v
        end
    end
    return nil
end

-- Trouver le jeton le plus proche non collecté et encore présent
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
        local ok, dist = pcall(function()
            return LocalPlayer:DistanceFromCharacter(pos)
        end)
        if ok and dist < currentDistance then
            currentDistance = dist
            nearestCandy = v
        end
    end
    return nearestCandy
end

-- Simuler l'interaction (protégé)
local function FireTouchTransmitter(touchParent)
    local character = LocalPlayer.Character
    local part = character and character:FindFirstChildOfClass("Part")
    if part and touchParent and IsAlive(touchParent) and typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(touchParent, part, 0)
            task.wait(0.06)
            firetouchinterest(touchParent, part, 1)
        end)
    end
end

-- Vérifier si le sac est plein
local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:WaitForChild("MainGUI", 5)
    if not gui then return false end
    local ok, coinFrame = pcall(function()
        return gui:WaitForChild("Game").CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins
    end)
    if not ok or not coinFrame then return false end
    local price = LocalPlayer:GetAttribute("Elite") and "50" or "40"
    return tostring(coinFrame.Text) == price
end

-- Nettoyer les ressources
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

-- Bibliothèque UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | Lunaris")

Window:Section("Bêta")

-- Toggle pour l'autofarm
Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.AutoFarm = state
        if not state then
            AutoFarmCleanup()
            return
        end

        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        startPosition = humanoidRootPart and humanoidRootPart.CFrame or Spawn.CFrame

        while Settings.AutoFarm do
            if not LocalPlayer:GetAttribute("Alive") then
                AutoFarmCleanup()
                break
            end
            
            -- === MODIFICATION POUR LA RÉINITIALISATION ===
            if IsBagFull() then
                print("Sac plein, réinitialisation du personnage.")
                LocalPlayer:LoadCharacter() -- Ajout de cette ligne pour réinitialiser
                task.wait(3) -- Petite pause pour laisser le temps au personnage de réapparaître
                AutoFarmCleanup()
                break
            end
            -- === FIN DE LA MODIFICATION ===

            local candy = GetNearestCandy()

            if candy then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(0.1); continue end

                local targetPos = SafeGetPos(candy)
                if not targetPos then task.wait(0.1); continue end

                local okDist, distance = pcall(function() return (hrp.Position - targetPos).Magnitude end)
                local duration = okDist and math.max(0.04, distance / math.max(1, Settings.WalkSpeed)) or 0.1

                local startPos = hrp.Position
                local t0 = tick()
                local movementCompleted = true

                while true do
                    if not IsAlive(candy) then
                        movementCompleted = false
                        break
                    end

                    local elapsed = tick() - t0
                    local alpha = math.clamp(elapsed / duration, 0, 1)
                    hrp.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))

                    if alpha >= 1 then
                        break
                    end
                    
                    RunService.Heartbeat:Wait()
                end

                if movementCompleted then
                    local tpart = GetTouchPart(candy)
                    if tpart and IsAlive(tpart) then
                        FireTouchTransmitter(tpart)
                        task.wait(0.08)
                    end
                    touchedCoins[candy] = true
                else
                    task.wait(0.01)
                end
            else
                task.wait(0.35)
            end
        end
    end)
end)

-- Bouton YouTube
Window:Button("YouTube: Lunaris", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

GetContainer()
