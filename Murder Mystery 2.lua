local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    Default = false,
}

-- Modification ici: recherche le modèle Coin_Server
local function GetContainer()
  for _,v in ipairs(Workspace:GetDescendants()) do
    if v.Name == "Coin_Server" then return v end  -- Changer CoinContainer en Coin_Server
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
    local Distance = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)

    if CurrentDistance > Distance then
        CurrentDistance = Distance
        Candy = v
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

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame);
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame);
end)



