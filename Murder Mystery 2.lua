-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Spawns") and Workspace.Lobby.Spawns:FindFirstChild("SpawnLocation")

-- Paramètres
getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 20,
    SearchRadius = 120,
    TpBackToStart = true,
    RetargetCooldown = 0.25,      -- délai avant de retenter la recherche
    MaxCandyAge = 20,             -- en secondes: si un candy existe trop longtemps sans TouchTransmitter, on le blackliste
    RequireTouchInterest = true,  -- ignorer les pièces sans TouchTransmitter visible
}

-- États
local touchedCoins = {}  -- [Instance] = true
local blacklisted = {}   -- [Instance] = { t = os.clock(), reason = "noTouch"/"failedTouch"/"destroyed" }
local startPositionCFrame = nil
local coinContainer = nil
local currentTarget = nil
local lastTargetTime = 0

-- Utils sûrs
local function IsAlive()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return (hum and hum.Health > 0 and hrp) and true or false
end

local function SafeDistance(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end

-- Détection du conteneur et écoute dynamique
local function GetContainer()
    if coinContainer and coinContainer.Parent then return coinContainer end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            coinContainer = v
            -- Réinitialiser caches si conteneur change
            table.clear(touchedCoins)
            table.clear(blacklisted)
            currentTarget = nil
            return v
        end
    end
    return nil
end

-- Vérif qu'un objet "candy" est valide
local function IsValidCandy(inst)
    if not inst or not inst.Parent then return false end
    -- On attend un Model ou BasePart avec un pivot valide
    if not inst:IsA("Model") and not inst:IsA("BasePart") then return false end
    -- Filtrage par TouchTransmitter (si demandé)
    if Settings.RequireTouchInterest then
        local hasTouch = false
        if inst:IsA("BasePart") then
            hasTouch = inst:FindFirstChildOfClass("TouchTransmitter") ~= nil
        elseif inst:IsA("Model") then
            local primary = inst.PrimaryPart or (inst:IsA("Model") and inst:FindFirstChildWhichIsA("BasePart"))
            if primary then
                hasTouch = primary:FindFirstChildOfClass("TouchTransmitter") ~= nil
            end
        end
        if not hasTouch then
            -- marquer blacklist pour éviter retarget
            blacklisted[inst] = { t = os.clock(), reason = "noTouch" }
            return false
        end
    end
    -- pas déjà pris ou blacklist
    if touchedCoins[inst] then return false end
    if blacklisted[inst] then return false end
    return true
end

-- Récupère la position d'un candy (pivot ou PrimaryPart)
local function CandyPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok and cf then
            return cf.Position
        end
        local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position or nil
    end
    return nil
end

-- Trouver le candy le plus proche dans le rayon
local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local best = nil
    local bestDist = Settings.SearchRadius
    local now = os.clock()

    for _, v in ipairs(container:GetChildren()) do
        -- purge blacklists trop anciennes si besoin
        if blacklisted[v] and (now - blacklisted[v].t) > Settings.MaxCandyAge then
            blacklisted[v] = nil
        end
        if IsValidCandy(v) then
            local pos = CandyPosition(v)
            if pos then
                local d = SafeDistance(pos)
                if d < bestDist then
                    bestDist = d
                    best = v
                end
            end
        end
    end
    return best
end

-- Tenter un "touch" (note: firetouchinterest est côté exploit et non API Roblox, non garanti) [web:3][web:4][web:2][web:5]
local function TryTouch(candy)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not candy then return false end

    -- trouver une BasePart touchable
    local touchPart = nil
    if candy:IsA("BasePart") then
        touchPart = candy
    elseif candy:IsA("Model") then
        touchPart = candy.PrimaryPart or candy:FindFirstChildWhichIsA("BasePart")
    end
    if not touchPart then return false end

    -- si pas de TouchTransmitter, éviter de spam [web:3][web:5]
    if Settings.RequireTouchInterest and not touchPart:FindFirstChildOfClass("TouchTransmitter") then
        blacklisted[candy] = { t = os.clock(), reason = "noTouch" }
        return false
    end

    -- Déplacer vraiment sur la position exacte pour laisser la physique déclencher Touched côté jeu
    local targetPos = touchPart.Position + Vector3.new(0, 2, 0)
    hrp.CFrame = CFrame.new(targetPos)

    -- Essai de firetouchinterest si dispo dans l’exécuteur (peut ne pas exister selon l’environnement) [web:4][web:2]
    local ok = false
    local part = char:FindFirstChildOfClass("Part") or hrp
    if typeof(firetouchinterest) == "function" and part then
        pcall(function()
            firetouchinterest(touchPart, part, 0)
            task.wait(0.1)
            firetouchinterest(touchPart, part, 1)
        end)
        ok = true
    else
        -- fallback: attendre un petit délai pour laisser Touched se produire si le jeu le gère
        task.wait(0.15)
        ok = true
    end

    -- si la pièce a disparu, considérer comme prise
    if not candy.Parent then
        touchedCoins[candy] = true
        return true
    end

    -- si TouchTransmitter a disparu après contact, considérer comme prise [web:2][web:3]
    if not touchPart:FindFirstChildOfClass("TouchTransmitter") then
        touchedCoins[candy] = true
        return true
    end

    return ok
end

-- Mouvement linéaire simple (gardé)
local function MoveToPositionSlowly(targetPosition, duration)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position
    local startTime = tick()
    while tick() - startTime < duration do
        if not IsAlive() then return end
        local alpha = math.min((tick() - startTime) / duration, 1)
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPosition, alpha))
        task.wait()
    end
    hrp.CFrame = CFrame.new(targetPosition)
end

-- Vérifier sac plein (adapte selon ton GUI)
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

-- Cleanup
local function AutoFarmCleanup()
    Settings.AutoFarm = false
    currentTarget = nil
    if Settings.TpBackToStart and startPositionCFrame then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = startPositionCFrame
        end
    end
end

-- UI (ton lib actuel)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")
Window:Section("esohasl.net")

-- Boucle principale
local function AutoFarmLoop()
    while Settings.AutoFarm do
        if not IsAlive() then
            AutoFarmCleanup()
            break
        end

        if IsBagFull() then
            AutoFarmCleanup()
            break
        end

        -- Retarget si pas de cible ou cible invalide
        if (not currentTarget) or (not IsValidCandy(currentTarget)) then
            currentTarget = GetNearestCandy()
            lastTargetTime = os.clock()
            if not currentTarget then
                task.wait(Settings.RetargetCooldown)
                continue
            end
        end

        -- Aller vers la cible
        local pos = CandyPosition(currentTarget)
        if not pos then
            blacklisted[currentTarget] = { t = os.clock(), reason = "noPivot" }
            currentTarget = nil
            task.wait(Settings.RetargetCooldown)
            continue
        end

        local distance = SafeDistance(pos)
        local duration = math.max(0.05, distance / math.max(1, Settings.WalkSpeed))
        MoveToPositionSlowly(pos, duration)

        -- Tentative de collecte
        local touchedOk = TryTouch(currentTarget)

        -- Décision après tentative
        if not currentTarget or not currentTarget.Parent then
            -- disparaît: compté comme pris
            -- touchedCoins marqué par TryTouch si besoin
            currentTarget = nil
        else
            -- Si toujours là mais sans TouchTransmitter, blacklist
            local part = currentTarget:IsA("BasePart") and currentTarget or (currentTarget.PrimaryPart or currentTarget:FindFirstChildWhichIsA("BasePart"))
            if not part or (Settings.RequireTouchInterest and not part:FindFirstChildOfClass("TouchTransmitter")) then
                blacklisted[currentTarget] = { t = os.clock(), reason = "stale" }
                currentTarget = nil
            elseif touchedOk then
                -- Marquer comme collecté pour éviter y retourner
                touchedCoins[currentTarget] = true
                currentTarget = nil
            else
                -- échec: blacklist court terme
                blacklisted[currentTarget] = { t = os.clock(), reason = "failedTouch" }
                currentTarget = nil
            end
        end

        task.wait(Settings.RetargetCooldown)
    end
end

-- Toggle UI
Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.AutoFarm = state
        if not state then
            AutoFarmCleanup()
            return
        end

        -- position initiale
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        startPositionCFrame = (hrp and hrp.CFrame) or (Spawn and Spawn.CFrame) or CFrame.new(0,5,0)

        -- initialiser le conteneur si possible
        GetContainer()

        -- reset états
        table.clear(touchedCoins)
        table.clear(blacklisted)
        currentTarget = nil

        AutoFarmLoop()
    end)
end)

-- Bouton YouTube
Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Anti-AFK (VirtualUser n’est pas fiable dans tous les cas; garde simple) [web:10][web:7][web:13]
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end)

-- Optionnel: repérer automatiquement CoinContainer si recréé
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "CoinContainer" then
        coinContainer = obj
        table.clear(touchedCoins)
        table.clear(blacklisted)
        currentTarget = nil
    end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    if obj == coinContainer then
        coinContainer = nil
    end
end)


