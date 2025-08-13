local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

-- Fonction pour obtenir le nom de la carte actuelle
local function GetCurrentMapName()
    -- On suppose que les modèles des cartes sont dans Workspace et ont des noms uniques
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name ~= "Lobby" then
            return v.Name  -- Retourne le nom du modèle (la carte)
        end
    end
    return nil  -- Retourne nil si aucune carte n'est trouvée
end

-- Fonction pour obtenir le conteneur des coins pour la carte actuelle
local function GetContainer()
    local mapName = GetCurrentMapName()
    if not mapName then return nil end

    -- Recherche dans le dossier de la carte actuelle
    local mapFolder = Workspace:FindFirstChild(mapName)
    if mapFolder then
        for _, v in ipairs(mapFolder:GetDescendants()) do
            if v.Name == "CoinContainer" then
                return v  -- Retourne le CoinContainer trouvé
            end
        end
    end

    return nil
end

-- Fonction pour obtenir le coin le plus proche
local function GetNearestCandy(arentEqual)
    local Container = GetContainer()
    if not Container then return nil end

    local Candy = nil
    local CurrentDistance = 9999

    -- Recherche les enfants du conteneur pour le plus proche Candy
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

-- Fonction pour interagir avec un objet de type "touch" (comme un Candy)
local function FireTouchTransmitter(touchParent)
    local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")

    if Character then
        firetouchinterest(touchParent, Character, 0)
        firetouchinterest(touchParent, Character, 1)
    end
end

-- Interface graphique avec la librairie
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
                local Humanoid = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                if Candy and Humanoid then  
                    local Process = TweenService:Create(Humanoid, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1), {
                        Position = Candy:GetPivot().Position
                    })
    
                    Process:Play()
                    Process.Completed:Wait()
                end
            end

            task.wait(.1)
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

-- Simulation de l'activité du joueur pour éviter l'inactivité
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)

