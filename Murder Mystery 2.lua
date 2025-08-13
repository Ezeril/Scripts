local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

-- Fonction pour obtenir le conteneur contenant les ballons (anciennement les bonbons)
local function GetContainer()
  for _, v in ipairs(Workspace:GetDescendants()) do
    if v.Name == "CoinContainer" then  -- "BalloonContainer" au lieu de "CoinContainer"
      return v
    end
  end

  return nil
end

-- Fonction pour obtenir le ballon le plus proche, en excluant un ballon donné si besoin
local function GetNearestBalloon(arentEqual)
  local Container = GetContainer()
  if not Container then return nil end

  local Balloon = nil
  local CurrentDistance = 9999

  for _, v in ipairs(Container:GetChildren()) do
    if arentEqual and v == arentEqual then continue end
    local Distance = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)

    if CurrentDistance > Distance then
        CurrentDistance = Distance
        Balloon = v
    end
  end

  return Balloon
end

-- Fonction pour déclencher un événement de toucher sur un objet
local function FireTouchTransmitter(touchParent)
  local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")

  if Character then
      firetouchinterest(touchParent, Character, 0)
      firetouchinterest(touchParent, Character, 1)
  end
end

-- Bibliothèque (utilisation d'un script externe)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

Window:Section("esohasl.net")

-- Option pour activer/désactiver l'auto-balloon
Window:Toggle("Auto Balloon", {}, function(state)
    task.spawn(function()
        Settings.Default = state
        while true do
            if not Settings.Default then return end

            if LocalPlayer:GetAttribute("Alive") then
              local Balloon = GetNearestBalloon()  -- Chercher un ballon
              local Humanoid = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

              if Balloon and Humanoid then  
                -- Tweener pour se déplacer vers le ballon
                local Process = TweenService:Create(Humanoid, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1), {
                  Position = Balloon:GetPivot().Position
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

-- Événement pour simuler l'inactivité et éviter d'être expulsé
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

