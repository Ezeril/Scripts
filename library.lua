-- ════════════════════════════════════
--  MM2 AUTOFARM — Script standalone
--  Colle directement dans ton executor
-- ════════════════════════════════════

-- Config
local CONFIG = {
    DelayFarm         = 0.05,    -- délai entre téléportations (secondes)
    AntiAfk           = true,    -- empêche le kick AFK
    AutoCollect       = true,    -- téléporte sur les pièces/objets
    CollectNames      = {        -- noms des objets à farmer selon la map
        "Coin", "Candy", "BeachBall", "Pumpkin", "Present", "Egg"
    },
}

local Players     = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local lp          = Players.LocalPlayer

-- ── Anti-AFK ──────────────────────────────────────
if CONFIG.AntiAfk then
    lp.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- ── Récupère tous les collectibles de la map ──────
local function getItems()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") then
            for _, name in ipairs(CONFIG.CollectNames) do
                if obj.Name == name then
                    table.insert(items, obj)
                    break
                end
            end
        end
    end
    return items
end

-- ── Trie par distance croissante ──────────────────
local function sortByDist(items, origin)
    table.sort(items, function(a, b)
        return (a.Position - origin).Magnitude < (b.Position - origin).Magnitude
    end)
    return items
end

-- ── Boucle principale ─────────────────────────────
task.spawn(function()
    while task.wait(CONFIG.DelayFarm) do
        local char = lp.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local items = sortByDist(getItems(), hrp.Position)
        if #items > 0 then
            -- Téléporte directement sur le collectible
            hrp.CFrame = items[1].CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

print("[MM2 AUTOFARM] Actif — " .. #getItems() .. " objets détectés")
