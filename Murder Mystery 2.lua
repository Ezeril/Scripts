local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

local function GetContainer()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then return v end
    end
    return nil
end

local function GetNearestCandy(arentEqual)
    local Container = GetContainer()
    if not Container then return nil end

    local Candy = nil
    local CurrentDistance = 9999

    for _, v in ipairs(Container:GetChildren()) do
        if arentEqual and v == arentEqual then continue end
        if v:IsA("BasePart") then  -- Assure que l'objet est un BasePart
            local Distance = LocalPlayer:DistanceFromCharacter(v.Position)
            if CurrentDistance > Distance then
                CurrentDistance = Distance
                Candy = v
            end
        end
    end

    return Candy
end

local function FireTouchTransmitter(touchParent)
    local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")
    if Character then
        firetouchinterest(touchParent, Character, 0)
        firetouchinterest(touchParent, Character, 1)
    end
end

-- Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

Window:Section("esohasl.net")

Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.Default = state
        while true do
            if not Settings.Default then return end
            if LocalPlayer:GetAttribute("Alive") then
                local Candy = GetNearestCandy()
                local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")

                if Candy and Humanoid then  
                    local TargetPosition = Candy.Position
                    local Duration = (LocalPlayer.Character.HumanoidRootPart.Position - TargetPosition).Magnitude / Humanoid.WalkSpeed
                    Humanoid:MoveTo(TargetPosition)

                    -- Attendre que le personnage arrive à la position cible
                    while (LocalPlayer.Character.HumanoidRootPart.Position - TargetPosition).Magnitude > 2 do
                        task.wait(0.1)
                    end

                    -- Marquer la pièce comme touchée
                    FireTouchTransmitter(Candy)
                    print("Coin touched!")
                end
            end
            task.wait(0.1)
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
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Nettoyage des pièces et des connexions
local function AutoFarmCleanUp()
    -- Vérification de si la table est vide
    if next(rt.positionChangeConnections) == nil then
        rt.AutoFarmOn = false
        print("No items in positionChangeConnections")
        return true
    end

    rt.AutoFarmOn = false
    coroutine.yield(rt.start)
    coroutine.close(rt.start)
    if coroutine.status(rt.start) == "suspended" then
        coroutine.yield(rt.start)
        coroutine.close(rt.start)
    end
    
    -- Déconnexion de toutes les connexions
    for _, connection in pairs(rt.positionChangeConnections) do
        rt.Disconnect(connection)
    end
    rt.Disconnect(rt.Added)
    rt.Disconnect(rt.Removing)

    -- Notification et nettoyage
    Notif:Notify("Removing cached instances for AutoFarm", 1.5, "success")
    table.clear(rt.touchedCoins)
    table.clear(rt.positionChangeConnections)
    
    task.wait(1)
    rt.start = coroutine.create(collectCoins)
    return true
end

-- Fonction pour collecter les pièces
collectCoins = function ()
    -- Assurez-vous que CoinContainer existe
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    rt.waypoint = rt:Character():GetPivot()
    local check = rt:MainGUI():WaitForChild("Game").CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins
    local price = "40"
    if rt:IsElite() then price = "50" end

    -- Peupler l'Octree
    populateOctree()
    
    while rt.AutoFarmOn do
        if check.Text == price then
            Notif:Notify("Full Bag", 2, "success")
            break
        end

        -- Trouver la pièce la plus proche
        local nearestNode = rt.octree:GetNearest(rt:Character().PrimaryPart.Position, rt.radius, 1)[1]

        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local closestCoinPosition = closestCoin.Position
                local distance = (rt:Character().PrimaryPart.Position - closestCoinPosition).Magnitude
                local duration = distance / rt.walkspeed -- Vitesse de marche par défaut de 26 studs/sec

                -- Déplacement vers la pièce
                moveToPositionSlowly(closestCoinPosition, duration)

                -- Marquer la pièce comme touchée et nettoyer
                markCoinAsTouched(closestCoin)
                task.wait(0.2) -- S'assurer que le contact est enregistré
            end
        else
            task.wait(1) -- Pas de pièces disponibles; essayer après un délai
        end
    end

    if rt.TpBackToStart then
        rt:Character():PivotTo(rt.waypoint)
    end
    AutoFarmCleanUp()
end

-- Fonction de déplacement lent vers une position cible
local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    rt.humanoidRootPart = rt:Character().PrimaryPart
    local startPosition = rt.humanoidRootPart.Position
    local startTime = tick()
    
    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)
        rt:Character():PivotTo(CFrame.new(startPosition:Lerp(targetPosition, alpha)))

        if alpha >= 1 then
            task.wait(0.2)
            break
        end

        task.wait() -- Petit délai pour rendre le mouvement plus fluide
    end
end

-- Fonction pour activer ou désactiver l'AutoFarm
local function ToggleAutoFarm(value : boolean)
    if not value then
        return AutoFarmCleanUp()
    end

    if not rt:CheckIfGameInProgress() then Notif:Notify("Map must be loaded to use Autofarm", 2, "error") return false end
    if not rt:CheckIfPlayerWasInARound() then Notif:Notify("You need to be in a round or have played a round to use the autofarm", 5, "error") return false end
    if not rt.Murderer then Notif:Notify("No Murderer found to satisfy: Round in Progress", 4, "information") return false end
    local isAlive = rt:CheckIfPlayerIsInARound()
    local OldState = rt.Uninterrupted
    local IsMurderer = rt.player.Name == rt.Murderer.Name

    -- Si le joueur est le meurtrier et a activé Uninterrupted
    if rt.Uninterrupted and IsMurderer then rt.Uninterrupted = false; IsMurderer = not IsMurderer end

    if rt.Uninterrupted then
        rt:Character():FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
        repeat task.wait() until rt.player.CharacterAdded:Wait()
        task.wait(1)
        TeleportToPlayer(rt.Murderer)
        -- Démarrer l'autofarm
        Notif:Notify("Uninterrupted made it all the way", 4, "alert")
        rt.AutoFarmOn = true
        coroutine.resume(rt.start)

