local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

-- Recherche du modèle Coin_Server dans le Workspace
local function GetContainer()
  -- Recherche continue dans le Workspace
  while true do
    for _, v in ipairs(Workspace:GetDescendants()) do
      if v.Name == "Coin_Server" then 
        return v  -- Trouvé le modèle Coin_Server
      end
    end
    task.wait(1)  -- Attendre avant de réessayer
  end
end

-- Fonction pour obtenir le bonbon le plus proche
local function GetNearestCandy(arentEqual)
  local Container = GetContainer()
  if not Container then return nil end

  local Candy = nil
  local CurrentDistance = 9999

  -- Parcours des enfants du modèle Coin_Server pour trouver le bonbon le plus proche
  for _, v in ipairs(Container:GetChildren()) do
    if arentEqual and v == arentEqual then continue end
    -- Utilisation de v.CFrame.Position pour obtenir la position du bonbon
    local Distance = LocalPlayer:DistanceFromCharacter(v.CFrame.Position)

    if CurrentDistance > Distance then
        CurrentDistance = Distance
        Candy = v
    end
  end

  return Candy
end

-- Fonction pour activer un événement de contact
local function FireTouchTransmitter(touchParent)
  local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")

  if Character then
      firetouchinterest(touchParent, Character, 0)
      firetouchinterest(touchParent, Character, 1)
  end
end

-- Chargement de la bibliothèque pour l'interface
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

Window:Section("esohasl.net")

-- Toggle pour activer/désactiver l'auto-candy
Window:Toggle("Auto Candy", {}, function(state)
    task.spawn(function()
        Settings.Default = state
        while true do
            if not Settings.Default then return end

            if LocalPlayer:GetAttribute("Alive") then
              local Candy = GetNearestCandy()
              local Humanoid = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

              if Candy and Humanoid then  
                -- Création d'une animation pour se déplacer vers le bonbon
                local Process = TweenService:Create(Humanoid, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1), {
                  Position = Candy.CFrame.Position  -- Utilisation de CFrame.Position pour le déplacement
                })
  
                Process:Play()
                Process.Completed:Wait()
              end
            end

            task.wait(.1)  -- Attendre un petit moment avant de réessayer
        end
    end)
end)

-- Bouton pour copier le lien YouTube dans le presse-papiers
Window:Button("YouTube: EsohaSL", function()
    task.spawn(function()
        if setclipboard then
            setclipboard("https://youtube.com/@esohasl")
        end
    end)
end)

-- Empêcher l'inactivité du joueur
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)



