local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 28, -- un peu plus rapide
    SearchRadius = 120, -- Rayon de recherche des jetons
    TpBackToStart = true, -- Retourner à la position initiale après l'autofarm
}

local touchedCoins = {} -- Table pour suivre les jetons collectés (confirmés)
local startPosition = nil -- Position initiale du joueur
local coinContainer = nil -- Conteneur des jetons

-- Helpers
local function IsAlive(inst)
    return inst and inst.Parent ~= nil
end -- [web:31]

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
end -- [web:82][web:88]

local function GetTouchPart(inst)
    if not IsAlive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end -- [web:82]

-- Trouver le conteneur des jetons
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
end -- [web:39]

-- Trouver le jeton le plus proche non collecté et encore présent
local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local nearestCandy = nil
    local currentDistance = Settings.SearchRadius

    for _, v in ipairs(container:GetChildren()) do
        if touchedCoins[v] then continue end -- Ignore les jetons déjà marqués
        if not IsAlive(v) then continue end -- Ignore s'il a disparu
        local pos = SafeGetPos(v)
        if not pos then continue end -- Ignore si pas de position exploitable
        local ok, distance = pcall(function()
            return LocalPlayer:DistanceFromCharacter(pos)
        end)
        if ok and distance < currentDistance then
            currentDistance = distance
            nearestCandy = v
        end
    end

    return nearestCandy
end -- [web:83][web:82]

-- Simuler l'interaction avec un jeton (protégé)
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
end -- [web:78][web:84]

-- Déplacer le joueur vers une position progressivement, annuler si la cible disparaît
-- Retourne true si arrivé, false si annulé (cible disparue)
local function MoveToPositionSlowly(targetInstance, targetPosition, duration)
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    local startPos = humanoidRootPart.Position
    local t0 = tick()

    while true do
        -- annuler si la cible n'existe plus
        if not IsAlive(targetInstance) then
            return false
        end
        -- annuler si le perso n'a plus de HRP
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            return false
        end

        local elapsed = tick() - t0
        local alpha = math.clamp(elapsed / duration, 0, 1)
        humanoidRootPart.CFrame = CFrame.new(startPos:Lerp(targetPosition, alpha))
        if alpha >= 1 then break end
        task.wait() -- pour encore plus de réactivité, on peut passer sur Heartbeat avec deltaTime [web:68][web:67]
    end

    -- recheck juste à l'arrivée
    if not IsAlive(targetInstance) then
        return false
    end

    humanoidRootPart.CFrame = CFrame.new(targetPosition)
    return true
end -- [web:65][web:62]

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
end -- [web:79]

-- Nettoyer les ressources
local function AutoFarmCleanup()
    Settings.AutoFarm = false
    table.clear(touchedCoins)
    if Settings.TpBackToStart and startPosition then
        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = startPosition
        end
    end
end -- [web:79]

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
                -- Revalider dès maintenant
                if not IsAlive(candy) then
                    task.wait(0.03)
                    continue
                end

                local pos = SafeGetPos(candy)
                if not pos then
                    task.wait(0.03)
                    continue
                end

                local okDist, distance = pcall(function()
                    return LocalPlayer:DistanceFromCharacter(pos)
                end)
                local duration = 0.05
                if okDist then
                    duration = math.max(0.035, distance / math.max(1, Settings.WalkSpeed))
                end

                -- Déplacement annulable: stoppe si la cible disparaît pendant l'approche
                local arrived = MoveToPositionSlowly(candy, pos, duration)
                if not arrived then
                    -- la cible a été prise par un autre joueur pendant l'approche: retarget immédiat
                    continue
                end

                -- Revalider juste avant de toucher
                if not IsAlive(candy) then
                    continue
                end

                local touchPart = GetTouchPart(candy)
                if touchPart and IsAlive(touchPart) then
                    FireTouchTransmitter(touchPart)
                    task.wait(0.06)
                    -- marquer collecté uniquement si elle disparaît après contact
                    if not IsAlive(candy) then
                        touchedCoins[candy] = true
                    end
                end
            else
                task.wait(0.25) -- retarget plus fréquent qu'1s
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
-- AutoFarm() non défini; utilise le toggle ci-dessus
