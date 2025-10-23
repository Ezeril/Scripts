local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoFarm = false,
    WalkSpeed = 20, -- Vitesse ajustable pour le mouvement
    SearchRadius = 120, -- Rayon de recherche des jetons
    TpBackToStart = true, -- Retourner à la position initiale après l'autofarm
}

local touchedCoins = {} -- Table pour suivre les jetons collectés
local startPosition = nil -- Position initiale du joueur
local coinContainer = nil -- Conteneur des jetons

-- Helpers sûrs
local function IsInstanceAlive(inst)
    return (inst ~= nil) and (inst.Parent ~= nil)
end -- [web:24][web:40]

local function SafeGetPivotPosition(modelOrPart)
    if not IsInstanceAlive(modelOrPart) then return nil end
    if modelOrPart:IsA("BasePart") then
        return modelOrPart.Position
    end
    if modelOrPart:IsA("Model") then
        local ok, cf = pcall(function() return modelOrPart:GetPivot() end)
        if ok and cf then
            return cf.Position
        else
            -- fallback PrimaryPart
            local pp = modelOrPart.PrimaryPart or modelOrPart:FindFirstChildWhichIsA("BasePart")
            return (pp and pp.Position) or nil
        end
    end
    return nil
end -- [web:26][web:38]

local function GetCandyTouchPart(inst)
    if not IsInstanceAlive(inst) then return nil end
    if inst:IsA("BasePart") then
        return inst
    elseif inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end -- [web:36]

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

-- Trouver le jeton le plus proche non collecté et encore valide
local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local nearestCandy = nil
    local currentDistance = Settings.SearchRadius

    for _, v in ipairs(container:GetChildren()) do
        if touchedCoins[v] then
            continue
        end
        if not IsInstanceAlive(v) then
            continue
        end
        -- S'assurer qu'il y a un part/pivot exploitable
        local pos = SafeGetPivotPosition(v)
        if not pos then
            continue
        end
        local distance
        local ok, res = pcall(function()
            return LocalPlayer:DistanceFromCharacter(pos)
        end)
        distance = ok and res or math.huge
        if distance < currentDistance then
            currentDistance = distance
            nearestCandy = v
        end
    end

    return nearestCandy
end -- [web:26][web:24]

-- Simuler l'interaction avec un jeton
local function FireTouchTransmitter(touchParent)
    local character = LocalPlayer.Character
    local part = character and character:FindFirstChildOfClass("Part")
    if part and touchParent and IsInstanceAlive(touchParent) then
        -- Protéger l'appel car firetouchinterest peut ne pas exister selon l’environnement
        if typeof(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(touchParent, part, 0)
                task.wait(0.1) -- Petit délai pour garantir l'interaction
                firetouchinterest(touchParent, part, 1)
            end)
        end
    end
end -- [web:25][web:29]

-- Déplacer le joueur vers une position progressivement
local function MoveToPositionSlowly(targetPosition, duration)
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local startPositionLocal = humanoidRootPart.Position
    local startTime = tick()

    while tick() - startTime < duration do
        -- Si le personnage meurt ou HRP disparaît, on stoppe
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            return
        end
        local alpha = math.min((tick() - startTime) / duration, 1)
        humanoidRootPart.CFrame = CFrame.new(startPositionLocal:Lerp(targetPosition, alpha))
        task.wait()
    end
    humanoidRootPart.CFrame = CFrame.new(targetPosition) -- S'assurer d'atteindre la position exacte
end -- [web:24]

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
        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = startPosition
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
                -- Revalider à chaque étape que la pièce existe encore et qu'on a une position utilisable
                if not IsInstanceAlive(candy) then
                    -- ignorée, ne pas marquer touchée; on relancera la boucle
                    task.wait(0.15)
                    continue
                end

                local pos = SafeGetPivotPosition(candy)
                if not pos then
                    -- pas de position exploitable (pivot/part manquant) => ignorer
                    task.wait(0.15)
                    continue
                end

                local okDist, distance = pcall(function()
                    return LocalPlayer:DistanceFromCharacter(pos)
                end)
                distance = (okDist and distance) or 0
                local duration = math.max(0.05, distance / math.max(1, Settings.WalkSpeed))

                -- Bouge seulement si la pièce est toujours là juste avant de partir
                if not IsInstanceAlive(candy) then
                    task.wait(0.1)
                    continue
                end

                MoveToPositionSlowly(pos, duration)

                -- Juste avant de toucher, revérifier: la pièce peut avoir disparu pendant le déplacement
                if not IsInstanceAlive(candy) then
                    task.wait(0.05)
                    continue
                end

                local touchPart = GetCandyTouchPart(candy)
                if touchPart and IsInstanceAlive(touchPart) then
                    FireTouchTransmitter(touchPart)
                    -- Si la pièce disparaît suite au contact, on la marquera prise; sinon, on checke son état
                    task.wait(0.15)
                    if not IsInstanceAlive(candy) then
                        touchedCoins[candy] = true
                    else
                        -- Si elle existe toujours, on la marque quand même pour éviter d'y retourner immédiatement,
                        -- et la prochaine passe la revalidera si elle est encore réellement collectable
                        touchedCoins[candy] = true
                    end
                else
                    -- pas de part touchable => ignorer sans marquer définitivement
                    task.wait(0.1)
                end
            else
                task.wait(1) -- Attendre si aucun jeton n'est trouvé
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
-- AutoFarm() n’existe pas dans ce script; le toggle contrôle la boucle



