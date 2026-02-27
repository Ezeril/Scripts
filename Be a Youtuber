-- SPEED ESCAPE FOR BRAINROTS - COMPACT VERSION [2026-02-15]
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local Footer = Instance.new("TextLabel")
local Container = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

-- ============================
-- CLEAN MODERN UI SETUP
-- ============================

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeBtn = Instance.new("TextButton")
local Footer = Instance.new("TextLabel")
local Container = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Parent = game.CoreGui

-- MAIN FRAME
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.1, 0, 0.35, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true

local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

-- DROP SHADOW
local shadow = Instance.new("ImageLabel", MainFrame)
shadow.ZIndex = -1
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)

-- TITLE BAR
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "LarpySahurSkid"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17

local titleCorner = Instance.new("UICorner", Title)
titleCorner.CornerRadius = UDim.new(0, 14)

-- MINIMIZE BUTTON
MinimizeBtn.Parent = MainFrame
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "▼"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20

-- FOOTER
Footer.Parent = MainFrame
Footer.Size = UDim2.new(1, 0, 0, 26)
Footer.Position = UDim2.new(0, 0, 1, -26)
Footer.BackgroundTransparency = 1
Footer.Text = "Credits to Scriptyyz"
Footer.TextColor3 = Color3.fromRGB(180, 180, 180)
Footer.Font = Enum.Font.GothamSemibold
Footer.TextSize = 12

-- BUTTON CONTAINER
Container.Parent = MainFrame
Container.Position = UDim2.new(0, 10, 0, 50)
Container.Size = UDim2.new(1, -20, 1, -85)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 0
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y

UIListLayout.Parent = Container
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createButton(txt, order, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)

    return btn
end

-- VARIABLES
_G.AutoCollect = false
_G.AutoUpload = false
_G.AutoClaim = false
_G.AutoRebirth = false
_G.AutoUpgrades = false
_G.AutoBuy = false
_G.SelectedYoutuber = ""

local player = game.Players.LocalPlayer
local events = game:GetService("ReplicatedStorage"):WaitForChild("events")

-- ================================
--  EGG ANIMATION REMOVAL (DELAYED)
-- ================================

task.spawn(function()
    -- Wait for the game to finish connecting its animation handlers
    task.wait(3)

    local events = game:GetService("ReplicatedStorage"):WaitForChild("events")

    local animationEvents = {
        "hatchExclusiveEgg",
        "hatchEventEgg",
        "hatchPet",
        "showEgg",
        "eggAnimation"
    }

    for _, name in ipairs(animationEvents) do
        local ev = events:FindFirstChild(name)
        if ev and ev.OnClientEvent then
            for _, conn in pairs(getconnections(ev.OnClientEvent)) do
                conn:Disconnect()
            end
            print("[EggAnim] Disconnected:", name)
        end
    end

    print("Egg animations disabled (delayed mode).")
end)

-- FEATURES IN ORDER

_G.AutoFloorCycle = false

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local floorPositions = {
    Vector3.new(-477.35833740234375, 11.39998722076416, -1931.170654296875),
    Vector3.new(-475.4379577636719, 38.24997329711914, -1936.069091796875),
    Vector3.new(-476.86102294921875, 65.5998764038086, -1931.540283203125),
    Vector3.new(-473.6367492675781, 92.69976806640625, -1937.2435302734375),
    Vector3.new(-475.9712219238281, 118.70933532714844, -1931.321044921875),
    Vector3.new(-476.06878662109375, 145.29953002929688, -1934.2862548828125)
}

createButton("Auto Floor Cycle: OFF", 50, function(btn)
    _G.AutoFloorCycle = not _G.AutoFloorCycle
    btn.Text = _G.AutoFloorCycle and "Auto Floor Cycle: ON" or "Auto Floor Cycle: OFF"

    if _G.AutoFloorCycle then
        task.spawn(function()
            while _G.AutoFloorCycle do
                for i = 1, #floorPositions do
                    if not _G.AutoFloorCycle then break end

                    -- Move HRP gently to the floor center
                    pcall(function()
                        hrp.CFrame = CFrame.new(floorPositions[i])
                    end)

                    task.wait(10) -- your required load time
                end
            end
        end)
    end
end)


createButton("Auto Collect: OFF", 1, function(btn) 
    _G.AutoCollect = not _G.AutoCollect 
    btn.Text = _G.AutoCollect and "Auto Collect: ON" or "Auto Collect: OFF" 
    if _G.AutoCollect then task.spawn(function() while _G.AutoCollect do for _, p in pairs(workspace.Plots:GetChildren()) do local builds = p:FindFirstChild("Builds") if builds then for _, item in pairs(builds:GetDescendants()) do if _G.AutoCollect and item:IsA("TouchTransmitter") then local part = item.Parent if part and part:IsA("BasePart") then firetouchinterest(player.Character.HumanoidRootPart, part, 0) task.wait(0.05) firetouchinterest(player.Character.HumanoidRootPart, part, 1) end end end end end task.wait(0.8) end end) end 
end)

createButton("Auto Upload: OFF", 2, function(btn) 
    _G.AutoUpload = not _G.AutoUpload 
    btn.Text = _G.AutoUpload and "Auto Upload: ON" or "Auto Upload: OFF" 
    if _G.AutoUpload then task.spawn(function() while _G.AutoUpload do pcall(function() events.uploadAll:FireServer() end) task.wait(3) end end) end 
end)

createButton("Auto Claim: OFF", 3, function(btn) 
    _G.AutoClaim = not _G.AutoClaim 
    btn.Text = _G.AutoClaim and "Auto Claim: ON" or "Auto Claim: OFF" 
    if _G.AutoClaim then task.spawn(function() while _G.AutoClaim do pcall(function() events.claimAll:FireServer() end) task.wait(3) end end) end 
end)

_G.SmartAutoRebirth = false

local rebirthMenu = player.PlayerGui.ScreenGui.menus.rebirthMenu
local container = rebirthMenu.container

local function getButtonData(btn)
    local amountText = btn.rebirths.Text -- "+5 Rebirths"
    local amount = tonumber(amountText:match("%+(%d+)"))
    if not amount then return end

    local costText = btn.cost.Text -- "Costs: $12345"
    local cost = tonumber(costText:match("%$(%d+)"))
    if not cost then return end

    return amount, cost
end

local function getHighestAffordable()
    local cash = player.leaderstats.Cash.Value

    local bestAmount = 0
    local bestButton = nil

    for _, btn in pairs(container:GetChildren()) do
        if btn:IsA("TextButton") then
            local amount, cost = getButtonData(btn)
            if amount and cost then
                if cash >= cost and amount > bestAmount then
                    bestAmount = amount
                    bestButton = btn
                end
            end
        end
    end

    return bestButton, bestAmount
end

createButton("Smart Auto Rebirth: OFF", 9, function(btn)
    _G.SmartAutoRebirth = not _G.SmartAutoRebirth
    btn.Text = _G.SmartAutoRebirth and "Smart Auto Rebirth: ON" or "Smart Auto Rebirth: OFF"

    if _G.SmartAutoRebirth then
        task.spawn(function()
            while _G.SmartAutoRebirth do

                local bestButton, amount = getHighestAffordable()

                if bestButton then
                    print("[Smart Rebirth] Rebirthing with +" .. amount)
                    events.rebirth:FireServer(amount)
                end

                task.wait(1)
            end
        end)
    end
end)

local upgradeList = {"views", "luck", "viralChance", "rebirthButtons", "uploadTime"}
createButton("Auto Upgrades: OFF", 5, function(btn) 
    _G.AutoUpgrades = not _G.AutoUpgrades 
    btn.Text = _G.AutoUpgrades and "Auto Upgrades: ON" or "Auto Upgrades: OFF" 
    if _G.AutoUpgrades then task.spawn(function() while _G.AutoUpgrades do for _, upg in pairs(upgradeList) do if not _G.AutoUpgrades then break end pcall(function() events.buyUpgrade:FireServer(upg) end) task.wait(1) end task.wait(5) end end) end 
end)

createButton("Auto Buy: OFF", 6, function(btn)
    _G.AutoBuy = not _G.AutoBuy
    btn.Text = _G.AutoBuy and "Auto Buy: ON" or "Auto Buy: OFF"
    if _G.AutoBuy then task.spawn(function() while _G.AutoBuy do if _G.SelectedYoutuber ~= "" then pcall(function() events.buyYoutuber:FireServer(_G.SelectedYoutuber) end) end task.wait(2) end end) end
end)

_G.AutoSubmit = false

createButton("Auto Submit: OFF", 8, function(btn)
    _G.AutoSubmit = not _G.AutoSubmit
    btn.Text = _G.AutoSubmit and "Auto Submit: ON" or "Auto Submit: OFF"

    if _G.AutoSubmit then
        task.spawn(function()
            while _G.AutoSubmit do
                pcall(function()
                    events.submitAll:FireServer()
                end)
                task.wait(3)
            end
        end)
    end
end)

-- AUTO BULK HATCH (FINAL)

_G.AutoBulkHatch = false
local BATCH = 10000

local player = game.Players.LocalPlayer

local cratesLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ScreenGui")
    :WaitForChild("menus")
    :WaitForChild("eventMenu")
    :WaitForChild("balance")
    :WaitForChild("crates")  -- lowercase c

local openEventEgg = game:GetService("ReplicatedStorage")
    :WaitForChild("events")
    :WaitForChild("openEventEgg")

local function getCrates()
    local text = cratesLabel.Text
    if not text then return 0 end

    local num = tonumber(text:match("%d+"))
    return num or 0
end

createButton("Auto Bulk Hatch: OFF", 10, function(btn)
    _G.AutoBulkHatch = not _G.AutoBulkHatch
    btn.Text = _G.AutoBulkHatch and "Auto Bulk Hatch: ON" or "Auto Bulk Hatch: OFF"

    if _G.AutoBulkHatch then
        task.spawn(function()
            while _G.AutoBulkHatch do
                local crates = getCrates()

                if crates > 0 then
                    local toOpen = math.min(crates, BATCH)
                    print("[Bulk Hatch] Opening", toOpen, "eggs")
                    openEventEgg:FireServer(toOpen)
                end

                task.wait(1)
            end
        end)
    end
end)

-- ================================
-- SELL ALL BUTTON
-- ================================

local events = game:GetService("ReplicatedStorage"):WaitForChild("events")

createButton("Sell All Youtubers", 999, function(btn)
    print("[SellAll] Selling everything...")
    events.sellAll:FireServer()
end)

-- INPUT BOX (DIRECTLY BELOW AUTO BUY)
local Input = Instance.new("TextBox", Container)
Input.LayoutOrder = 7
Input.Size = UDim2.new(1, 0, 0, 32)
Input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Input.PlaceholderText = "Enter Youtuber ID..."
Input.Text = ""
Input.TextColor3 = Color3.fromRGB(255, 255, 255)
Input.Font = Enum.Font.GothamBold
Input.TextSize = 13
Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 8)

Input.Changed:Connect(function()
    _G.SelectedYoutuber = Input.Text
end)

-- MINIMIZE
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame:TweenSize(minimized and UDim2.new(0, 250, 0, 40) or UDim2.new(0, 250, 0, 360), "Out", "Quart", 0.3, true)
    Container.Visible = not minimized
    Footer.Visible = not minimized
    MinimizeBtn.Text = minimized and "▲" or "▼"
end)
