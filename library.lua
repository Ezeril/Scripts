-- ══════════════════════════════════════════════════════════════
--  MM2 AUTOFARM v3.1 — Anti-rollback smooth movement
-- ══════════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end
if _G.AutoFarmMM2IsLoaded then return end
_G.AutoFarmMM2IsLoaded = true

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local Player       = Players.LocalPlayer

local Settings = _G.AutofarmSettings or {
    AntiAfk          = true,
    ResetWhenFullBag = false,
    StartAutofarm    = false,
    ImproveFPS       = false,
    CoinType         = "SnowToken",
}

local Remotes          = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
local CoinCollectedEvent = Remotes:WaitForChild("CoinCollected")
local RoundStartEvent    = Remotes:WaitForChild("RoundStart")
local RoundEndEvent      = Remotes:WaitForChild("RoundEndFade")

local AutofarmStarted   = false
local AutofarmIN        = false
local AntiAfkState      = false
local ImproveFPSenabled = false
local ResetWhenFullBag  = Settings.ResetWhenFullBag or false
local CurrentCoinType   = Settings.CoinType or "SnowToken"
local autofarmstopevent = Instance.new("BindableEvent")
local isStopping        = false

-- ══════════════════════════════════════════════════════════════
--  SMOOTH MOVEMENT — Cœur de l'amélioration
-- ══════════════════════════════════════════════════════════════

-- Vitesse max autorisée sans déclencher l'anti-cheat (studs/s)
-- Walk speed MM2 = 16. On reste raisonnable à 40 max.
local MAX_SPEED   = 40
-- Taille d'un saut intermédiaire pour les longues distances
local HOP_SIZE    = 35

--[[
    moveToSmooth(targetCFrame)
    
    Stratégie anti-rollback :
    1. Si dist < 25  → Humanoid:MoveTo() (le plus légitime, aucun rollback)
    2. Si dist < 100 → Un seul Tween à vitesse limitée (MAX_SPEED studs/s)
    3. Si dist > 100 → Sauts intermédiaires de HOP_SIZE studs + pause entre chaque
                       pour laisser le serveur valider chaque position
]]
local function moveToSmooth(targetCFrame)
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local origin   = hrp.Position
    local target   = targetCFrame.Position
    local dist     = (origin - target).Magnitude

    if isStopping then return end

    -- ── Cas 1 : Très proche → MoveTo natif (0 rollback) ─────
    if dist <= 25 then
        hum:MoveTo(target)
        hum.MoveToFinished:Wait()
        return
    end

    -- ── Cas 2 : Distance moyenne → Tween vitesse contrôlée ──
    if dist <= 100 then
        local duration = dist / MAX_SPEED -- secondes
        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {CFrame = CFrame.new(target + Vector3.new(0, 3, 0))}
        )
        tween:Play()

        local stopConn
        stopConn = autofarmstopevent.Event:Connect(function()
            tween:Cancel()
            if stopConn then stopConn:Disconnect() end
        end)

        tween.Completed:Wait()
        if stopConn then stopConn:Disconnect() end
        return
    end

    -- ── Cas 3 : Longue distance → Sauts intermédiaires ──────
    -- Calcule une série de points entre origin et target
    local direction = (target - origin).Unit
    local steps     = math.ceil(dist / HOP_SIZE)

    for i = 1, steps do
        if isStopping then break end

        local stepTarget
        if i == steps then
            -- Dernier saut → position finale exacte
            stepTarget = CFrame.new(target + Vector3.new(0, 3, 0))
        else
            local pos = origin + direction * (HOP_SIZE * i)
            stepTarget = CFrame.new(pos + Vector3.new(0, 3, 0))
        end

        -- Tween pour ce segment (smooth entre chaque hop)
        local segDist    = HOP_SIZE
        local segDuration = segDist / MAX_SPEED
        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(segDuration, Enum.EasingStyle.Linear),
            {CFrame = stepTarget}
        )
        tween:Play()
        tween.Completed:Wait()

        -- ⭐ Pause critique : laisse le serveur valider la position
        -- Sans ça = rollback garanti sur longue distance
        task.wait(0.08)
    end
end

-- ══════════════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2AF_" .. tostring(math.random(1000,9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Border = Instance.new("Frame", ScreenGui)
Border.AnchorPoint = Vector2.new(.5, .5)
Border.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Border.Position = UDim2.new(.5, 0, .5, 0)
Border.Size = UDim2.new(0.152, 0, 0.357, 0)
Border.ZIndex = 1
Border.Active = true
Border.Draggable = true
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 10)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.AnchorPoint = Vector2.new(.5, .5)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 250, 255)
MainFrame.Position = UDim2.new(.5, 0, .5, 0)
MainFrame.Size = UDim2.new(0.146, 0, 0.347, 0)
MainFrame.ZIndex = 2
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    Border.Position = MainFrame.Position
end)

local function makeLbl(text)
    local l = Instance.new("TextLabel", MainFrame)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 0, 0, 0)
    l.Size = UDim2.new(0.82, 0, 0.18, 0)
    l.Font = Enum.Font.Kalam
    l.Text = text
    l.TextColor3 = Color3.fromRGB(0,0,0)
    l.TextScaled = true
    l.ZIndex = 3
    return l
end
local Title = makeLbl("🎄 MM2 Autofarm v3.1")

local BtnClose = Instance.new("TextButton", MainFrame)
BtnClose.BackgroundTransparency = 1
BtnClose.Position = UDim2.new(0.82, 0, 0, 0)
BtnClose.Size = UDim2.new(0.18, 0, 0.18, 0)
BtnClose.Font = Enum.Font.Kalam
BtnClose.Text = "X"
BtnClose.TextColor3 = Color3.fromRGB(255,0,0)
BtnClose.TextScaled = true
BtnClose.ZIndex = 3

local BtnOpen = Instance.new("TextButton", ScreenGui)
BtnOpen.AnchorPoint = Vector2.new(.5,.5)
BtnOpen.BackgroundColor3 = Color3.fromRGB(0,200,200)
BtnOpen.Position = UDim2.new(0.5, 0, 0.03, 0)
BtnOpen.Size = UDim2.new(0.1, 0, 0.045, 0)
BtnOpen.Font = Enum.Font.Kalam
BtnOpen.Text = "Ouvrir Autofarm"
BtnOpen.TextColor3 = Color3.fromRGB(0,0,0)
BtnOpen.TextScaled = true
BtnOpen.ZIndex = 5
BtnOpen.Visible = false
Instance.new("UICorner", BtnOpen).CornerRadius = UDim.new(0, 8)

local function makeBtn(text, posX, posY)
    local btn = Instance.new("TextButton", MainFrame)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BorderColor3 = Color3.fromRGB(0,0,0)
    btn.BorderSizePixel = 2
    btn.Position = UDim2.new(posX, 0, posY, 0)
    btn.Size = UDim2.new(0.446, 0, 0.18, 0)
    btn.Font = Enum.Font.Kalam
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.TextScaled = true
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local BtnStart   = makeBtn("▶ START",         0.029, 0.22)
local BtnRAFB    = makeBtn("Reset bag plein",  0.525, 0.22)
local BtnFPS     = makeBtn("Improve FPS",      0.029, 0.44)
local BtnAntiAfk = makeBtn("Anti AFK",         0.525, 0.44)

-- Bouton coin pleine largeur
local BtnCoin = Instance.new("TextButton", MainFrame)
BtnCoin.BackgroundColor3 = Color3.fromRGB(255,255,255)
BtnCoin.BorderColor3 = Color3.fromRGB(0,0,0)
BtnCoin.BorderSizePixel = 2
BtnCoin.Position = UDim2.new(0.029, 0, 0.66, 0)
BtnCoin.Size = UDim2.new(0.942, 0, 0.18, 0)
BtnCoin.Font = Enum.Font.Kalam
BtnCoin.Text = "🪙 " .. CurrentCoinType
BtnCoin.TextColor3 = Color3.fromRGB(0,0,0)
BtnCoin.TextScaled = true
BtnCoin.ZIndex = 3
Instance.new("UICorner", BtnCoin).CornerRadius = UDim.new(0, 8)

-- Indicateur de vitesse (affiché dans le titre quand actif)
local function setActive(btn, state)
    btn.TextColor3 = state and Color3.fromRGB(0,220,0) or Color3.fromRGB(0,0,0)
end

local function toggleGUI()
    local v = not MainFrame.Visible
    MainFrame.Visible = v
    Border.Visible = v
    BtnOpen.Visible = not v
end
BtnClose.MouseButton1Click:Connect(toggleGUI)
BtnOpen.MouseButton1Click:Connect(toggleGUI)

-- ══════════════════════════════════════════════════════════════
--  LOGIQUE
-- ══════════════════════════════════════════════════════════════
local function AntiAFK()
    local GC = getconnections or get_signal_cons
    if GC then
        for _, v in pairs(GC(Player.Idled)) do
            if v.Disable then v:Disable()
            elseif v.Disconnect then v:Disconnect() end
        end
    else
        local VU = cloneref(game:GetService("VirtualUser"))
        Player.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
end
BtnAntiAfk.MouseButton1Click:Connect(function()
    AntiAfkState = not AntiAfkState
    setActive(BtnAntiAfk, AntiAfkState)
    if AntiAfkState then AntiAFK() end
end)

local function applyFPS(char)
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("Accessory") or p.Name == "Radio" then p:Destroy() end
    end
end
BtnFPS.MouseButton1Click:Connect(function()
    ImproveFPSenabled = not ImproveFPSenabled
    setActive(BtnFPS, ImproveFPSenabled)
    if ImproveFPSenabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then applyFPS(p.Character) end
        end
    end
end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) task.wait(0.5); if ImproveFPSenabled then applyFPS(c) end end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(c) task.wait(0.5); if ImproveFPSenabled then applyFPS(c) end end)
end

BtnRAFB.MouseButton1Click:Connect(function()
    ResetWhenFullBag = not ResetWhenFullBag
    setActive(BtnRAFB, ResetWhenFullBag)
end)

local CoinTypes = {"SnowToken", "Coin", "Candy", "BeachBall"}
local coinIdx = 1
BtnCoin.MouseButton1Click:Connect(function()
    coinIdx = (coinIdx % #CoinTypes) + 1
    CurrentCoinType = CoinTypes[coinIdx]
    BtnCoin.Text = "🪙 " .. CurrentCoinType
end)

BtnStart.MouseButton1Click:Connect(function()
    AutofarmStarted = not AutofarmStarted
    isStopping = not AutofarmStarted
    if AutofarmStarted then
        isStopping = false
        AutofarmIN = true
        BtnStart.Text = "⏹ STOP"
        setActive(BtnStart, true)
    else
        BtnStart.Text = "▶ START"
        setActive(BtnStart, false)
        autofarmstopevent:Fire()
    end
end)

local function getCoinContainer()
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
            return v.CoinContainer
        end
    end
end

local function findNearestCoin(container)
    local nearest, minDist = nil, math.huge
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, v in ipairs(container:GetChildren()) do
        if v:GetAttribute("CoinID") == CurrentCoinType and v:FindFirstChild("TouchInterest") then
            local d = (hrp.Position - v.Position).Magnitude
            if d < minDist then nearest, minDist = v, d end
        end
    end
    return nearest
end

CoinCollectedEvent.OnClientEvent:Connect(function(cointype, current, max)
    AutofarmIN = true
    if cointype == CurrentCoinType and tonumber(current) == tonumber(max) then
        AutofarmIN = false
        if ResetWhenFullBag and Player.Character then
            local hum = Player.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end)

RoundStartEvent.OnClientEvent:Connect(function() AutofarmIN = true end)
RoundEndEvent.OnClientEvent:Connect(function() AutofarmIN = false end)

-- ─── Boucle principale ────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.0001)
        if not AutofarmStarted or not AutofarmIN then task.wait(0.3); continue end

        local container = getCoinContainer()
        if not container then task.wait(0.5); continue end

        local coin = findNearestCoin(container)
        if not coin then task.wait(0.5); continue end

        -- Déplacement smooth anti-rollback
        moveToSmooth(coin.CFrame)

        -- Attend que la pièce soit collectée ou disparaisse (timeout 4s)
        local t = tick()
        while coin:FindFirstChild("TouchInterest") and (tick() - t) < 4 do
            task.wait(0.05)
        end
    end
end)

-- ─── Configs _G ──────────────────────────────────────────────
if Settings.AntiAfk       then AntiAfkState = true; AntiAFK(); setActive(BtnAntiAfk, true) end
if Settings.ImproveFPS    then ImproveFPSenabled = true; setActive(BtnFPS, true) end
if Settings.ResetWhenFullBag then ResetWhenFullBag = true; setActive(BtnRAFB, true) end
if Settings.StartAutofarm then
    AutofarmStarted = true; AutofarmIN = true
    BtnStart.Text = "⏹ STOP"; setActive(BtnStart, true)
end
for i, v in ipairs(CoinTypes) do
    if v == Settings.CoinType then coinIdx = i; CurrentCoinType = v; BtnCoin.Text = "🪙 " .. v; break end
end

print("[MM2 AF v3.1] ✅ Smooth movement actif | MAX_SPEED=" .. MAX_SPEED .. " | HOP_SIZE=" .. HOP_SIZE)
