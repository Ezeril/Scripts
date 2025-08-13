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
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") then
            print("Carte trouvée : " .. v.Name)  -- Affiche le nom de la carte
            return v.Name
        end
    end
    print("Aucune carte trouvée !")
    return nil
end

-- Fonction pour obtenir le conteneur des coins pour la carte actuelle
local function GetContainer()
    local mapName = GetCurrentMapName()
    if not mapName then
        print("Pas de carte active !")
        return nil
    end

    local mapFolder = Workspace:FindFirstChild(mapName)
    if mapFolder then
        for _, v in ipairs(mapFolder:GetDescendants()) do
            if v.Name == "CoinContainer" then
                print("CoinContainer trouvé dans : " .. mapFolder.Name)
                return v
            end
        end
    end

    print("CoinContainer non trouvé dans la carte : " .. mapName)
    return nil
end

-- Fonction pour obtenir le coin le plus proche
local function GetNearestCandy(arentEqual)
    local Container = GetContainer()
    if not Container then
        print("Pas de CoinContainer trouvé !")
        return nil
    end

    local Candy = nil
    local CurrentDistance = 9999

    for _, v in ipairs(Container:GetChildren()) do
        print("Enfant trouvé dans CoinContainer : " .. v.Name)  -- Affiche les enfants
        if arentEqual and v == arentEqual then continue end
        if v:IsA("BasePart") then
            local Distance = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)

            if CurrentDistance > Distance then
                CurrentDistance = Distance
                Candy = v
            end
        end
    end

    if Candy then
        print("Coin trouvé : " .. Candy.Name)
    else
        print("Aucun coin trouvé proche.")
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
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)


