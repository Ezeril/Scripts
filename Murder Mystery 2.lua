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
    for _,v in ipairs(Workspace:GetDescendants()) do
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
        if v:IsA("BasePart") then  -- Vérifie que l'objet est un BasePart
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
                    local TargetPosition = Candy.Position  -- Position de la confiserie
                    Humanoid:MoveTo(TargetPosition)  -- Déplace le personnage vers la confiserie
                    
                    -- Attendre que le personnage arrive
                    while (LocalPlayer.Character.HumanoidRootPart.Position - TargetPosition).Magnitude > 1 do
                        task.wait(0.1)
                    end
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

