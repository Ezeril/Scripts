-- ══════════════════════════════════════════════════════════════
--  MM2 AUTOFARM v3 — Script standalone complet
--  Fusionne original + Christmas update
--  Fonctionne SANS GuiLibrary externe (tout intégré)
-- ══════════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end
if _G.AutoFarmMM2IsLoaded then return end
_G.AutoFarmMM2IsLoaded = true

-- ─── Services ────────────────────────────────────────────────
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui     = game:GetService("CoreGui")
local Player      = Players.LocalPlayer

-- ─── Config depuis _G ────────────────────────────────────────
local Settings = _G.AutofarmSettings or {
    AntiAfk          = true,
    ResetWhenFullBag = false,
    DelayFarm        = 0.0001,
    StartAutofarm    = false,
    ImproveFPS       = false,
    CoinType         = "Coin", -- "SnowToken", "Coin", "Candy", "BeachBall"
}

-- ─── Remotes MM2 ─────────────────────────────────────────────
local Remotes      = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
local CoinCollectedEvent = Remotes:WaitForChild("CoinCollected")
local RoundStartEvent   = Remotes:WaitForChild("RoundStart")
local RoundEndEvent     = Remotes:WaitForChild("RoundEndFade")

-- ─── États ───────────────────────────────────────────────────
local AutofarmStarted   = false
local AutofarmIN        = false  -- false par défaut : pas de farm hors round
local InActiveRound     = false  -- true uniquement entre RoundStart et RoundEnd
local AntiAfkState      = false
local ImproveFPSenabled = false
local ResetWhenFullBag  = Settings.ResetWhenFullBag or false
local CurrentCoinType   = Settings.CoinType or "SnowToken"
local autofarmstopevent = Instance.new("BindableEvent")

-- ══════════════════════════════════════════════════════════════
--  GUI (sans dépendance externe)
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2AutofarmGUI_" .. tostring(math.random(1000,9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Bordure
local Border = Instance.new("Frame", ScreenGui)
Border.AnchorPoint = Vector2.new(.5, .5)
Border.BackgroundColor3 = Color3.fromRGB(0,0,0)
Border.Position = UDim2.new(.5, 0, .5, 0)
Border.Size = UDim2.new(0.152, 0, 0.357, 0)
Border.ZIndex = 1
Border.Active = true
Border.Draggable = true
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 10)

-- Frame principale
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.AnchorPoint = Vector2.new(.5, .5)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 250, 255)
MainFrame.Position = UDim2.new(.5, 0, .5, 0)
MainFrame.Size = UDim2.new(0.146, 0, 0.347, 0)
MainFrame.ZIndex = 2
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Sync bordure/frame au drag
MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    Border.Position = MainFrame.Position
end)

-- Titre
local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(0.82, 0, 0.18, 0)
Title.Font = Enum.Font.Kalam
Title.Text = "🎄 MM2 Autofarm v3"
Title.TextColor3 = Color3.fromRGB(0,0,0)
Title.TextScaled = true
Title.ZIndex = 3

-- Bouton fermer
local BtnClose = Instance.new("TextButton", MainFrame)
BtnClose.BackgroundTransparency = 1
BtnClose.Position = UDim2.new(0.82, 0, 0, 0)
BtnClose.Size = UDim2.new(0.18, 0, 0.18, 0)
BtnClose.Font = Enum.Font.Kalam
BtnClose.Text = "X"
BtnClose.TextColor3 = Color3.fromRGB(255,0,0)
BtnClose.TextScaled = true
BtnClose.ZIndex = 3

-- Bouton "Ouvrir" (quand GUI cachée)
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

local function makeBtn(text, posY)
    local btn = Instance.new("TextButton", MainFrame)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.BorderColor3 = Color3.fromRGB(0,0,0)
    btn.BorderSizePixel = 2
    btn.Position = UDim2.new(0.029, 0, posY, 0)
    btn.Size = UDim2.new(0.446, 0, 0.18, 0)
    btn.Font = Enum.Font.Kalam
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.TextScaled = true
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end
local function makeBtnR(text, posY) -- colonne droite
    local btn = makeBtn(text, posY)
    btn.Position = UDim2.new(0.525, 0, posY, 0)
    return btn
end

local BtnStart   = makeBtn("▶ START",    0.22)
local BtnRAFB    = makeBtnR("Reset bag plein", 0.22)
local BtnFPS     = makeBtn("Improve FPS", 0.44)
local BtnAntiAfk = makeBtnR("Anti AFK",  0.44)
local BtnCoin    = makeBtn("🪙 " .. CurrentCoinType, 0.66)
BtnCoin.Size = UDim2.new(0.942, 0, 0.18, 0) -- pleine largeur

-- ─── Toggle couleur helper ────────────────────────────────────
local function setActive(btn, state)
    btn.TextColor3 = state and Color3.fromRGB(0,220,0) or Color3.fromRGB(0,0,0)
end

-- ─── Toggle GUI ───────────────────────────────────────────────
local function toggleGUI()
    local visible = not MainFrame.Visible
    MainFrame.Visible = visible
    Border.Visible = visible
    BtnOpen.Visible = not visible
end
BtnClose.MouseButton1Click:Connect(toggleGUI)
BtnOpen.MouseButton1Click:Connect(toggleGUI)

-- ══════════════════════════════════════════════════════════════
--  FONCTIONS CORE
-- ══════════════════════════════════════════════════════════════

-- ─── Anti-AFK ────────────────────────────────────────────────
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

-- ─── Improve FPS (supprime accessoires de tous les persos) ────
local function applyFPS(char)
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("Accessory") or part.Name == "Radio" then
            part:Destroy()
        end
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
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if ImproveFPSenabled then applyFPS(char) end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if ImproveFPSenabled then applyFPS(char) end
    end)
end

-- ─── Reset bag plein ─────────────────────────────────────────
BtnRAFB.MouseButton1Click:Connect(function()
    ResetWhenFullBag = not ResetWhenFullBag
    setActive(BtnRAFB, ResetWhenFullBag)
end)

-- ─── Cycle type de pièce ─────────────────────────────────────
local CoinTypes = {"SnowToken", "Coin", "Candy", "BeachBall"}
local coinIdx = 1
BtnCoin.MouseButton1Click:Connect(function()
    coinIdx = (coinIdx % #CoinTypes) + 1
    CurrentCoinType = CoinTypes[coinIdx]
    BtnCoin.Text = "🪙 " .. CurrentCoinType
end)

-- ─── Start / Stop ─────────────────────────────────────────────
BtnStart.MouseButton1Click:Connect(function()
    AutofarmStarted = not AutofarmStarted
    if AutofarmStarted then
        -- Active seulement si on est dans un round ET vivant
        local char = Player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        AutofarmIN = InActiveRound and hum ~= nil and hum.Health > 0
        BtnStart.Text = "⏹ STOP"
        setActive(BtnStart, true)
    else
        AutofarmIN = false
        BtnStart.Text = "▶ START"
        setActive(BtnStart, false)
        autofarmstopevent:Fire()
    end
end)

-- ══════════════════════════════════════════════════════════════
--  GESTION MORT
-- ══════════════════════════════════════════════════════════════

local function watchDeath(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.Died:Connect(function()
        -- Mort pendant le farm → on coupe immédiatement, pas de TP post-mort
        AutofarmIN = false
        autofarmstopevent:Fire()
    end)
end

-- Après un respawn on est à l'accueil/spectateur → farm coupé
Player.CharacterAdded:Connect(function(char)
    AutofarmIN = false
    watchDeath(char)
end)

if Player.Character then
    watchDeath(Player.Character)
end

-- ══════════════════════════════════════════════════════════════
--  LOGIQUE AUTOFARM
-- ══════════════════════════════════════════════════════════════

-- Trouve le CoinContainer dans le workspace
local function getCoinContainer()
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
            return v:FindFirstChild("CoinContainer")
        end
    end
    return nil
end

-- Téléportation sécurisée (Y du perso préservé, pas d'enfoncement)
local function pcallTP(targetPos)
    local char = Player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        end
    end
end

-- Trouve la pièce la plus proche du type courant
local function findNearestCoin(container)
    local nearest, minDist = nil, math.huge
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    for _, v in ipairs(container:GetChildren()) do
        if v:GetAttribute("CoinID") == CurrentCoinType and v:FindFirstChild("TouchInterest") then
            local dist = (hrp.Position - v.Position).Magnitude
            if dist < minDist then
                nearest = v
                minDist = dist
            end
        end
    end
    return nearest, minDist
end

-- ─── Event : pièce collectée ─────────────────────────────────
CoinCollectedEvent.OnClientEvent:Connect(function(cointype, current, max)
    -- Remet AutofarmIN en route seulement si on est dans un round ET vivant
    if AutofarmStarted and InActiveRound then
        local char = Player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            AutofarmIN = true
        end
    end
    if cointype == CurrentCoinType and tonumber(current) == tonumber(max) then
        AutofarmIN = false
        if ResetWhenFullBag and Player.Character then
            local hum = Player.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end)

RoundStartEvent.OnClientEvent:Connect(function()
    InActiveRound = true
    -- Active le farm seulement si START activé ET participant vivant (pas spectateur)
    if AutofarmStarted then
        local char = Player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            AutofarmIN = true
        end
    end
end)

RoundEndEvent.OnClientEvent:Connect(function()
    InActiveRound = false
    AutofarmIN = false
    autofarmstopevent:Fire()
end)

-- ─── Boucle principale ───────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.0001)

        if not AutofarmStarted or not AutofarmIN then
            task.wait(0.3)
            continue
        end

        local char = Player.Character
        if not char then task.wait(0.3); continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(0.3); continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then task.wait(0.3); continue end

        local container = getCoinContainer()
        if not container then task.wait(0.3); continue end

        local coin, dist = findNearestCoin(container)
        if not coin then task.wait(0.5); continue end

        if dist > 150 then
            -- Trop loin → téléport direct (Y préservé)
            pcallTP(coin.Position)
        else
            -- Distance raisonnable → Tween fluide
            -- Y verrouillé sur celui du perso → jamais d'enfoncement dans le sol
            local lockedY = hrp.Position.Y

            -- Désactive la physique → plus de saccades/résistance pendant le Tween
            hum.PlatformStand = true

            local tween = TweenService:Create(
                hrp,
                TweenInfo.new(dist / 20, Enum.EasingStyle.Linear),
                { CFrame = CFrame.new(coin.Position.X, lockedY, coin.Position.Z) }
            )
            tween:Play()

            -- Stop si l'utilisateur appuie sur STOP
            local stopConn
            stopConn = autofarmstopevent.Event:Connect(function()
                tween:Cancel()
                stopConn:Disconnect()
            end)

            -- Attend que la pièce disparaisse (collectée), timeout, mort ou STOP
            local timeout = tick() + 5
            while coin.Parent
                  and coin:FindFirstChild("TouchInterest")
                  and tick() < timeout
                  and AutofarmIN do
                task.wait()
            end
            tween:Cancel()
            stopConn:Disconnect()

            -- Réactive la physique seulement si le perso est encore vivant
            if hum and hum.Health > 0 then
                hum.PlatformStand = false
            end
        end
    end
end)

-- ─── Application des configs _G ──────────────────────────────
if Settings.AntiAfk       then AntiAfkState = true; AntiAFK(); setActive(BtnAntiAfk, true) end
if Settings.StartAutofarm then
    AutofarmStarted = true
    -- AutofarmIN reste false, s'activera au prochain RoundStart
    BtnStart.Text = "⏹ STOP"; setActive(BtnStart, true)
end
if Settings.ImproveFPS    then ImproveFPSenabled = true; setActive(BtnFPS, true) end
if Settings.ResetWhenFullBag then
    ResetWhenFullBag = true; setActive(BtnRAFB, true)
end
for i, v in ipairs(CoinTypes) do
    if v == Settings.CoinType then
        coinIdx = i; CurrentCoinType = v
        BtnCoin.Text = "🪙 " .. v
        break
    end
end

print("[MM2 AUTOFARM v3] ✅ Chargé — CoinType: " .. CurrentCoinType)
