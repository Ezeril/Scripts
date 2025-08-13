local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Spawn = Workspace.Lobby.Spawns.SpawnLocation

getgenv().Settings = {
    AutoBallonEnabled = false,
}

-- Récupérer le container
local function GetContainer()
    return Workspace:FindFirstChild("CoinContainer")
end

-- Obtenir le ballon le plus proche
local function GetNearestBallon(arentEqual)
    local Container = GetContainer()
    if not Container then return nil end

    local NearestBallon = nil
    local MinDistance = math.huge

    for _, v in ipairs(Container:GetChildren()) do
        if arentEqual and v == arentEqual then continue end
        local Distance = LocalPlayer:DistanceFromCharacter(v.Position)

        if Distance < MinDistance then
            MinDistance = Distance
            NearestBallon = v
        end
    end

    return NearestBallon
end

-- Fonction pour toucher un objet
local function FireTouchTransmitter(touchParent)
    local Character = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Part")
    if Character then
        firetouchinterest(touchParent, Character, 0)
        firetouchinterest(touchParent, Character, 1)
    end
end

-- Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wally2", true))()
local Window = Library:CreateWindow("MM2 | EsohaSL")

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
                                Position = Ballon.Position
                            })
                            Tween:Play()
                            Tween.Completed:Wait()
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
