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

-- Trouver le conteneur des jetons
local function GetContainer()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then
            coinContainer = v
            return v
        end
    end
    return nil
end

-- Trouver le jeton le plus proche non collecté
local function GetNearestCandy()
    local container = GetContainer()
    if not container then return nil end

    local nearestCandy = nil
    local currentDistance = Settings.SearchRadius

    for _, v in ipairs(container:GetChildren()) do
        if touchedCoins[v] then continue end -- Ignore les jetons déjà collectés
        local distance = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)
        if distance < currentDistance then
            currentDistance = distance
            nearestCandy = v
        end
    end

    return nearestCandy
end

-- Simuler l'interaction avec un jeton
local function FireTouchTransmitter(touchParent)
    local character = LocalPlayer.Character
    local part = character and character:FindFirstChildOfClass("Part")
    if part and touchParent then
        firetouchinterest(touchParent, part, 0)
        task.wait(0.1) -- Petit délai pour garantir l'interaction
        firetouchinterest(touchParent, part, 1)
    end
end

-- Déplacer le joueur vers une position progressivement
local function MoveToPositionSlowly(targetPosition, duration)
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local startPosition = humanoidRootPart.Position
    local startTime = tick()

    while tick() - startTime < duration do
        local alpha = math.min((tick() - startTime) / duration, 1)
        humanoidRootPart.CFrame = CFrame.new(startPosition:Lerp(targetPosition, alpha))
        task.wait()
    end
    humanoidRootPart.CFrame = CFrame.new(targetPosition) -- S'assurer d'atteindre la position exacte
end

-- Vérifier si le sac est plein
local function IsBagFull()
    local gui = LocalPlayer.PlayerGui:WaitForChild("MainGUI", 5)
    if not gui then return false end
    local coinFrame = gui:WaitForChild("Game").CoinBags.Container.SnowToken.CurrencyFrame.Icon.Coins
    local price = LocalPlayer:GetAttribute("Elite") and "50" or "40"
    return coinFrame.Text == price
end

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
end

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
                local distance = LocalPlayer:DistanceFromCharacter(candy:GetPivot().Position)
                local duration = distance / Settings.WalkSpeed -- Ajuster la durée selon la distance
                MoveToPositionSlowly(candy:GetPivot().Position, duration)
                FireTouchTransmitter(candy)
                touchedCoins[candy] = true -- Marquer le jeton comme collecté
                task.wait(0.2) -- Attendre pour garantir l'interaction
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
AutoFarm()

