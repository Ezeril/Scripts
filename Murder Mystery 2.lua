local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoBallonEnabled = false,
}

-- Récupérer le container dans ReplicatedStorage
local function GetContainer()
    local container = game.ReplicatedStorage:FindFirstChild("Coins")
    if container then
        local BeachBallObjets = container:FindFirstChild("BeachBallObjets")
        if BeachBallObjets then
            local beachBall = beachBallObjets:FindFirstChild("BeachBall")
            if beachBall then
                return beachBall
            else
                print("BeachBall introuvable dans BeachBallObjets.")
                return nil
            end
        else
            print("BeachBallObjets introuvable dans Coins.")
            return nil
        end
    else
        print("Coins introuvable dans ReplicatedStorage.")
        return nil
    end
end

-- Obtenir le ballon le plus proche
local function GetNearestBallon(arentEqual)
    local BeachBall = GetContainer()
    if not BeachBall then return nil end

    local NearestBallon = nil
    local MinDistance = math.huge

    -- Vérifier la distance du BeachBall (au lieu de vérifier tous les objets dans le container)
    local Position = BeachBall:IsA("Part") and BeachBall.Position or BeachBall:GetPivot().Position
    local Distance = LocalPlayer:DistanceFromCharacter(Position)

    if Distance < MinDistance then
        MinDistance = Distance
        NearestBallon = BeachBall
    end

    return NearestBallon
end

-- Fonction pour toucher un objet
local function FireTouchTransmitter(touchParent)
    local Character = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Part")
    if Character then
        firetouchinterest(touchParent, Character, 0)
        firetouchinterest(touchParent, Character, 1)
    else
        print("Aucun Character trouvé pour FireTouchTransmitter.")
    end
end

-- Library
print("Chargement de la bibliothèque...")
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
print("Bibliothèque chargée.")

-- Vérification si la fenêtre a été correctement créée
local Window = Library:CreateWindow("MM2 | EsohaSL")
if Window then
    print("Fenêtre créée avec succès.")
else
    print("Erreur dans la création de la fenêtre.")
end

Window:Section("esohasl.net")

-- Auto Ballon Toggle
Window:Toggle("Auto Ballon", {}, function(state)
    Settings.AutoBallonEnabled = state
    if state then
        -- Lancer l'auto ballon en tâche de fond
        task.spawn(function()
            while Settings.AutoBallonEnabled do
                if LocalPlayer:GetAttribute("Alive") then
                    local Ballon = GetNearestBallon()

                    if Ballon then
                        local HumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if HumanoidRootPart then
                            local Tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                                Position = Ballon:GetPivot().Position
                            })
                            Tween:Play()
                            Tween.Completed:Wait()
                        else
                            print("HumanoidRootPart introuvable.")
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)

-- Copier le lien YouTube
Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Gérer l'Idle
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

