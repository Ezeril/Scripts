-- Configuration des services nécessaires
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- Variables globales
local LocalPlayer = Players.LocalPlayer
local CoinContainer = nil
local Settings = {
    Default = false,
    AutoFarmOn = false,
    Uninterrupted = false,
    TpBackToStart = true,
    radius = 120,
    walkspeed = 20
}

local touchedCoins = {}
local positionChangeConnections = setmetatable({}, { __mode = "v" })
local start = nil
local waypoint = nil

-- Fonction pour obtenir le conteneur des coins
local function GetContainer()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then return v end
    end
    return nil
end

-- Fonction pour récupérer le bon coin à collecter
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

-- Fonction pour toucher un coin
local function FireTouchTransmitter(touchParent)
    local Character = LocalPlayer.Character:FindFirstChildOfClass("Part")
    if Character then
        firetouchinterest(touchParent, Character, 0)
        firetouchinterest(touchParent, Character, 1)
    end
end

-- Fonction de déplacement vers un coin
local function MoveToCoin(coin)
    local Humanoid = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if coin and Humanoid then  
        local Process = TweenService:Create(Humanoid, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1), {
            Position = coin:GetPivot().Position
        })
        Process:Play()
        Process.Completed:Wait()
    end
end

-- Fonction pour activer l'autofarm
local function AutoFarm()
    while Settings.AutoFarmOn do
        if LocalPlayer:GetAttribute("Alive") then
            local Candy = GetNearestCandy()
            if Candy then
                MoveToCoin(Candy)
                FireTouchTransmitter(Candy)
                touchedCoins[Candy] = true
                task.wait(0.2)
            end
        end
        task.wait(0.1)
    end
end

-- Fonction pour démarrer l'autofarm
local function ToggleAutoFarm(state)
    Settings.AutoFarmOn = state
    if state then
        start = coroutine.create(AutoFarm)
        coroutine.resume(start)
    else
        Settings.AutoFarmOn = false
        if start then
            coroutine.yield(start)
        end
    end
end

-- Gestion de l'interface utilisateur (UI)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezeril/Scripts/refs/heads/main/library.lua", true))()
local Window = Library:CreateWindow("MM2 | Autofarm")

Window:Section("AutoFarm Settings")

-- Toggle pour l'auto-farm
Window:Toggle("Activate AutoFarm", {}, function(state)
    ToggleAutoFarm(state)
end)

Window:Toggle("Uninterrupted Mode", Settings.Uninterrupted, function(state)
    Settings.Uninterrupted = state
end)

Window:Slider("Farm Radius", {min = 50, max = 200, default = Settings.radius}, function(value)
    Settings.radius = value
end)

Window:Slider("Tween Speed", {min = 16, max = 50, default = Settings.walkspeed}, function(value)
    Settings.walkspeed = value
end)

-- Fonction pour réinitialiser l'autofarm si un coin est touché
local function ResetAutoFarm()
    touchedCoins = {}
    positionChangeConnections = setmetatable({}, { __mode = "v" })
    AutoFarm()
end

-- Déclenchement des événements lors de la mort du joueur
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait()
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Initialisation du système d'autofarm
GetContainer()
AutoFarm()

