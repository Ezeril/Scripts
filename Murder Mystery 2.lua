local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 28, -- un peu plus rapide par défaut
    SearchRadius = 120,
    TpBackToStart = true,
}

local touchedCoins = {} -- jetons marqués pris (confirmés)
local startPosition = nil
local coinContainer = nil

-- helpers sûrs
local function IsAlive(inst)
    return inst and inst.Parent ~= nil
end -- [web:24]

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
end -- [web:26]

local function GetTouchPart(inst)
    if not IsAlive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end -- [web:36]

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
end -- [web:39]

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
end -- [web:24][web:26]

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
end -- [web:29]

-- Déplacer le joueur rapidement avec pas adaptatif
local function MoveToPositionSlowly(targetPosition, duration)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position
    local t0 = tick()
    while true do
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end
        local elapsed = tick() - t0
        local alpha = math.clamp(elapsed / duration, 0, 1)
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPosition, alpha))
        if alpha >= 1 then break end
        task.wait() -- court wait; si tu veux encore plus rapide, remplace par RunService.Heartbeat connect pattern
    end
    hrp.CFrame = CFrame.new(targetPosition)
end -- [web:50][web:43]

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
end -- [web:29]

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
end -- [web:24]

-- Bibliothèque UI (inchangée)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

Window:Section("esohasl.net")

-- Toggle pour l'autofarm
Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.AutoFarm = state
        if not state then
            AutoFarmCleanup()
            return
        end

        -- Stocker la position initiale
        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        startPosition = humanoidRootPart and humanoidRootPart.CFrame or Spawn.CFrame

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
                -- revalider avant de calculer
                if not IsAlive(candy) then
                    task.wait(0.05)
                    continue
                end

                local pos = SafeGetPos(candy)
                if not pos then
                    task.wait(0.05)
                    continue
                end

                local okDist, distance = pcall(function()
                    return LocalPlayer:DistanceFromCharacter(pos)
                end)
                local duration = 0.05
                if okDist then
                    duration = math.max(0.04, distance / math.max(1, Settings.WalkSpeed))
                end

                -- revalider juste avant de bouger
                if not IsAlive(candy) then
                    task.wait(0.05)
                    continue
                end

                MoveToPositionSlowly(pos, duration)

                -- revalider juste avant de toucher
                if not IsAlive(candy) then
                    task.wait(0.02)
                    continue
                end

                local tpart = GetTouchPart(candy)
                if tpart and IsAlive(tpart) then
                    FireTouchTransmitter(tpart)
                    task.wait(0.08)
                    -- considérer collecté si l’objet a disparu
                    if not IsAlive(candy) then
                        touchedCoins[candy] = true
                    else
                        -- pour éviter d’y retourner tout de suite si le serveur a un léger délai,
                        -- marque-le temporairement; il sera filtré au prochain scan s’il a disparu
                        touchedCoins[candy] = true
                    end
                else
                    -- pas de part touchable, on ignore sans marquer définitivement
                    task.wait(0.05)
                end
            else
                task.wait(0.35) -- réduit l’attente pour retarget plus souvent
            end
        end
    end)
end)

-- Bouton YouTube (inchangé)
Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Anti-AFK (inchangé)
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

-- Initialisation du système d'autofarm
GetContainer()
-- AutoFarm() non requis; le toggle lance/arrête la boucle
