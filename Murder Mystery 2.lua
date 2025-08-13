local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

-- Table pour stocker les objets collectés
local touchedCoins = {}
local positionChangeConnections = {}

local function GetContainer()
  for _, v in ipairs(Workspace:GetDescendants()) do
    if v.Name == "CoinContainer" then return v end
  end
  return nil
end

-- Fonction pour obtenir la pièce la plus proche
local function GetNearestCandy(arentEqual)
  local Container = GetContainer()
  if not Container then return nil end

  local Candy = nil
  local CurrentDistance = 9999

  for _, v in ipairs(Container:GetChildren()) do
    if arentEqual and v == arentEqual then continue end
    local Distance = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)

    if CurrentDistance > Distance then
        CurrentDistance = Distance
        Candy = v
    end
  end

  return Candy
end

-- Fonction pour simuler le toucher d'une pièce
local function FireTouchTransmitter(touchParent)
  local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")

  if Character then
      firetouchinterest(touchParent, Character, 0)
      firetouchinterest(touchParent, Character, 1)
  end
end

-- Marque une pièce comme touchée
local function isCoinTouched(coin)
    return touchedCoins[coin]
end

-- Marque une pièce comme touchée et retire le node de l'octree
local function markCoinAsTouched(coin)
    if not LocalPlayer then return end
    touchedCoins[coin] = true
    local node = rt.octree:FindFirstNode(coin)
    if node then
        rt.octree:RemoveNode(node)
    end
end

-- Suivi de la position des pièces
local function setupPositionTracking(coin, LastPositionY)
    local connection
    connection = coin:GetPropertyChangedSignal("Position"):Connect(function()
        local currentY = coin.Position.Y
        if LastPositionY and LastPositionY ~= currentY then
            markCoinAsTouched(coin)
            rt.Disconnect(connection)
            coin:Destroy()
            return
        end
    end)
    positionChangeConnections[coin] = connection
end

-- Remplir l'octree avec des pièces
local function populateOctree()
    rt.octree:ClearAllNodes()

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if not isCoinTouched(parentCoin) then
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupPositionTracking(parentCoin, parentCoin.Position.Y)
            end
        end
    end

    rt.Added = rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if not isCoinTouched(parentCoin) then
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupPositionTracking(parentCoin, parentCoin.Position.Y)
            end
        end
    end)

    rt.Removing = rt.coinContainer.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if isCoinTouched(parentCoin) then
                markCoinAsTouched(parentCoin)
            end
        end
    end)
end

-- Déplacement vers une pièce
local function moveToPositionSlowly(targetPosition, duration)
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    local startPosition = humanoidRootPart.Position
    local startTime = tick()

    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)
        LocalPlayer.Character:PivotTo(CFrame.new(startPosition:Lerp(targetPosition, alpha)))

        if alpha >= 1 then
            task.wait(0.2)
            break
        end

        task.wait() -- Small delay to make the movement smoother
    end
end

-- Fonction pour collecter les pièces automatiquement
local function collectCoins()
    rt.coinContainer = GetContainer()
    local check = LocalPlayer:WaitForChild("MainGUI").CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins
    local price = "40"
    if rt:IsElite() then price = "50" end

    populateOctree()

    while Settings.Default do
        if check.Text == price then
            Notif:Notify("Full Bag", 2, "success")
            break
        end

        -- Trouver la pièce la plus proche
        local nearestNode = rt.octree:GetNearest(LocalPlayer.Character.PrimaryPart.Position, rt.radius, 1)[1]

        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local closestCoinPosition = closestCoin.Position
                local distance = (LocalPlayer.Character.PrimaryPart.Position - closestCoinPosition).Magnitude
                local duration = distance / rt.walkspeed -- Vitesse de marche par défaut

                -- Déplacer vers la pièce
                moveToPositionSlowly(closestCoinPosition, duration)

                -- Marquer la pièce comme touchée
                markCoinAsTouched(closestCoin)
                task.wait(0.2) -- Assurer que le toucher est bien enregistré
            end
        else
            task.wait(1) -- Pas de pièces, réessayer après un délai
        end
    end

    AutoFarmCleanUp() -- Nettoyer après la collecte
end

-- Library (chargement de la bibliothèque GUI)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

-- Fenêtre du GUI
Window:Section("esohasl.net")

-- Case à cocher pour activer/désactiver l'autofarm
Window:Checkbox("Auto Candy", false, function(state)
    Settings.Default = state
    if state then
        collectCoins()  -- Démarrer la collecte des pièces si activé
    end
end)

-- Bouton pour copier le lien YouTube
Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Simulation d'un bouton pour éviter l'inactivité du joueur
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame);
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame);
end)

