-- ============================================================
--  VERTEX.LUA MONITOR — Script d'audit complet
--  À exécuter AVANT le script cible dans ton executor
--  Compatible : Synapse X, KRNL, Fluxus, AWP, etc.
-- ============================================================

local LOG = {}
local logCount = 0

-- ─────────────────────────────────────────
-- Système de logging centralisé avec GUI
-- ─────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MonitorGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 550, 0, 400)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Text = "🔍 SCRIPT MONITOR — vertex.lua"

local ScrollFrame = Instance.new("ScrollingFrame", Frame)
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UILayout = Instance.new("UIListLayout", ScrollFrame)
UILayout.SortOrder = Enum.SortOrder.LayoutOrder
UILayout.Padding = UDim.new(0, 2)

-- Coule la GUI dans CoreGui pour la rendre persistante
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local COLORS = {
    HTTP      = Color3.fromRGB(100, 200, 255),
    REMOTE    = Color3.fromRGB(255, 180, 50),
    INSTANCE  = Color3.fromRGB(100, 255, 100),
    LOADSTR   = Color3.fromRGB(255, 80, 80),
    METATABLE = Color3.fromRGB(200, 100, 255),
    FILE      = Color3.fromRGB(255, 220, 50),
    ENV       = Color3.fromRGB(50, 220, 200),
    HOOK      = Color3.fromRGB(255, 130, 130),
    INFO      = Color3.fromRGB(180, 180, 180),
}

local function log(category, message, color)
    logCount += 1
    local entry = {
        n = logCount,
        cat = category,
        msg = message,
        time = os.clock()
    }
    table.insert(LOG, entry)

    -- Affichage GUI
    local label = Instance.new("TextLabel", ScrollFrame)
    label.Size = UDim2.new(1, -10, 0, 18)
    label.BackgroundTransparency = logCount % 2 == 0 and 0.9 or 1
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.Text = string.format("[%d][%s] %s", logCount, category, message)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.LayoutOrder = logCount

    -- Auto-scroll vers le bas
    ScrollFrame.CanvasPosition = Vector2.new(0, math.huge)

    -- Aussi dans la console
    print(string.format("[MONITOR][%s] %s", category, message))
end

log("INFO", "Monitor actif — en attente du script cible...", COLORS.INFO)

-- ─────────────────────────────────────────
-- 1. HOOK HTTP (HttpGet, HttpService)
-- ─────────────────────────────────────────
local HttpService = game:GetService("HttpService")

-- Hook game:HttpGet
local oldHttpGet = hookfunction(game.HttpGet, newcclosure(function(self, url, ...)
    log("HTTP", "HttpGet → " .. tostring(url), COLORS.HTTP)
    local result = oldHttpGet(self, url, ...)
    log("HTTP", string.format("HttpGet réponse [%d chars] ← %s", #tostring(result or ""), tostring(url)), COLORS.HTTP)
    return result
end))

-- Hook HttpService:GetAsync
local oldGetAsync = hookfunction(HttpService.GetAsync, newcclosure(function(self, url, nocache, headers)
    log("HTTP", "GetAsync → " .. tostring(url), COLORS.HTTP)
    if headers then
        for k, v in pairs(headers) do
            log("HTTP", string.format("  Header: %s = %s", tostring(k), tostring(v)), COLORS.HTTP)
        end
    end
    return oldGetAsync(self, url, nocache, headers)
end))

-- Hook HttpService:PostAsync
local oldPostAsync = hookfunction(HttpService.PostAsync, newcclosure(function(self, url, data, ...)
    log("HTTP", "PostAsync → " .. tostring(url), COLORS.HTTP)
    log("HTTP", "  Body: " .. tostring(data):sub(1, 200), COLORS.HTTP)
    return oldPostAsync(self, url, data, ...)
end))

-- Hook request() (API executor)
if request then
    local oldRequest = hookfunction(request, newcclosure(function(opts)
        log("HTTP", string.format("request() → [%s] %s", tostring(opts.Method or "GET"), tostring(opts.Url)), COLORS.HTTP)
        if opts.Body then
            log("HTTP", "  Body: " .. tostring(opts.Body):sub(1, 200), COLORS.HTTP)
        end
        if opts.Headers then
            for k, v in pairs(opts.Headers) do
                log("HTTP", string.format("  Header: %s = %s", tostring(k), tostring(v)), COLORS.HTTP)
            end
        end
        return oldRequest(opts)
    end))
end

-- ─────────────────────────────────────────
-- 2. HOOK LOADSTRING
-- ─────────────────────────────────────────
local oldLoadstring = hookfunction(loadstring, newcclosure(function(src, chunkname)
    log("LOADSTR", string.format("loadstring() appelé [%d chars]", #tostring(src or "")), COLORS.LOADSTR)
    -- Affiche les 300 premiers chars du code injecté
    local preview = tostring(src or ""):sub(1, 300):gsub("\n", "↵"):gsub("\t", "→")
    log("LOADSTR", "  Preview: " .. preview, COLORS.LOADSTR)
    return oldLoadstring(src, chunkname)
end))

-- ─────────────────────────────────────────
-- 3. HOOK __NAMECALL (RemoteEvents, méthodes)
-- ─────────────────────────────────────────
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Intercepter les Remotes (FireServer, InvokeServer, FireClient...)
    if method == "FireServer" or method == "InvokeServer" or
       method == "FireClient" or method == "FireAllClients" then
        local remoteName = pcall(function() return self.Name end) and self.Name or "?"
        local remotePath = pcall(function() return self:GetFullName() end) and self:GetFullName() or remoteName
        local argStr = ""
        for i, v in ipairs(args) do
            argStr = argStr .. string.format("[%d]=%s ", i, tostring(v):sub(1, 50))
        end
        log("REMOTE", string.format("%s:%s(%s)", remotePath, method, argStr), COLORS.REMOTE)

    -- Intercepter Kick
    elseif method == "Kick" then
        log("HOOK", "⚠️ Tentative de Kick → " .. tostring(args[1] or ""), COLORS.HOOK)

    -- Intercepter HttpGet via namecall
    elseif method == "HttpGet" or method == "GetAsync" or method == "PostAsync" then
        log("HTTP", string.format("__namecall:%s → %s", method, tostring(args[1] or "")), COLORS.HTTP)
    end

    return oldNamecall(self, ...)
end))

-- ─────────────────────────────────────────
-- 4. HOOK __INDEX (lectures de propriétés)
-- ─────────────────────────────────────────
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    -- Logguer seulement les accès sensibles
    local sensitiveKeys = {
        "Players", "Workspace", "ReplicatedStorage", "ServerStorage",
        "HttpService", "TeleportService", "MarketplaceService",
        "DataStoreService", "LocalPlayer", "Character"
    }
    for _, k in ipairs(sensitiveKeys) do
        if key == k then
            log("METATABLE", string.format("__index → game.%s", key), COLORS.METATABLE)
            break
        end
    end
    return oldIndex(self, key)
end))

-- ─────────────────────────────────────────
-- 5. HOOK __NEWINDEX (modifications de propriétés)
-- ─────────────────────────────────────────
local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
    local path = pcall(function() return self:GetFullName() end) and self:GetFullName() or tostring(self)
    log("METATABLE", string.format("__newindex → %s.%s = %s", path, tostring(key), tostring(value):sub(1,80)), COLORS.METATABLE)
    return oldNewIndex(self, key, value)
end))

-- ─────────────────────────────────────────
-- 6. HOOK INSTANCE.NEW
-- ─────────────────────────────────────────
local oldInstanceNew = hookfunction(Instance.new, newcclosure(function(className, parent)
    local parentName = parent and pcall(function() return parent:GetFullName() end) and parent:GetFullName() or "nil"
    log("INSTANCE", string.format("Instance.new('%s') → parent: %s", tostring(className), parentName), COLORS.INSTANCE)
    return oldInstanceNew(className, parent)
end))

-- ─────────────────────────────────────────
-- 7. HOOK FILESYSTEM (writefile, readfile, etc.)
-- ─────────────────────────────────────────
if writefile then
    local oldWritefile = hookfunction(writefile, newcclosure(function(path, content)
        log("FILE", string.format("writefile('%s') [%d chars]", tostring(path), #tostring(content or "")), COLORS.FILE)
        return oldWritefile(path, content)
    end))
end

if readfile then
    local oldReadfile = hookfunction(readfile, newcclosure(function(path)
        log("FILE", "readfile('" .. tostring(path) .. "')", COLORS.FILE)
        return oldReadfile(path)
    end))
end

if appendfile then
    local oldAppendfile = hookfunction(appendfile, newcclosure(function(path, content)
        log("FILE", string.format("appendfile('%s') [%d chars]", tostring(path), #tostring(content or "")), COLORS.FILE)
        return oldAppendfile(path, content)
    end))
end

if delfile then
    local oldDelfile = hookfunction(delfile, newcclosure(function(path)
        log("FILE", "⚠️ delfile('" .. tostring(path) .. "')", COLORS.FILE)
        return oldDelfile(path)
    end))
end

-- ─────────────────────────────────────────
-- 8. HOOK GETFENV / SETFENV (accès aux envs)
-- ─────────────────────────────────────────
if setfenv then
    local oldSetfenv = hookfunction(setfenv, newcclosure(function(f, env)
        log("ENV", "setfenv() — injection d'environnement détectée", COLORS.ENV)
        return oldSetfenv(f, env)
    end))
end

-- ─────────────────────────────────────────
-- 9. HOOK REQUIRE
-- ─────────────────────────────────────────
local oldRequire = hookfunction(require, newcclosure(function(module)
    local modName = pcall(function() return module.Name end) and module.Name or tostring(module)
    local modPath = pcall(function() return module:GetFullName() end) and module:GetFullName() or modName
    log("ENV", "require('" .. modPath .. "')", COLORS.ENV)
    return oldRequire(module)
end))

-- ─────────────────────────────────────────
-- 10. WATCHER : surveille les nouveaux scripts créés
-- ─────────────────────────────────────────
task.spawn(function()
    local function watchForScripts(parent)
        parent.DescendantAdded:Connect(function(obj)
            if obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                log("INSTANCE", string.format("⚠️ Nouveau script créé: %s (%s)", obj:GetFullName(), obj.ClassName), COLORS.HOOK)
                -- Affiche le source si accessible
                if obj.Source and #obj.Source > 0 then
                    log("INSTANCE", "  Source: " .. obj.Source:sub(1, 200):gsub("\n","↵"), COLORS.HOOK)
                end
            end
        end)
    end
    watchForScripts(game)
end)

-- ─────────────────────────────────────────
-- 11. WATCHER : surveille les RemoteEvents existants
-- ─────────────────────────────────────────
task.spawn(function()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                local argStr = ""
                for i, v in ipairs(args) do
                    argStr = argStr .. string.format("[%d]=%s ", i, tostring(v):sub(1, 50))
                end
                log("REMOTE", string.format("OnClientEvent ← %s (%s)", obj:GetFullName(), argStr), COLORS.REMOTE)
            end)
        end
    end
    game.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            task.wait(0.1)
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                local argStr = ""
                for i, v in ipairs(args) do
                    argStr = argStr .. string.format("[%d]=%s ", i, tostring(v):sub(1, 50))
                end
                log("REMOTE", string.format("OnClientEvent ← %s (%s)", obj:GetFullName(), argStr), COLORS.REMOTE)
            end)
        end
    end)
end)

-- ─────────────────────────────────────────
-- 12. EXPORT LOG vers fichier (si supporté)
-- ─────────────────────────────────────────
task.spawn(function()
    task.wait(30) -- Exporte après 30 secondes
    if writefile then
        local output = "=== VERTEX.LUA MONITOR LOG ===\n"
        for _, entry in ipairs(LOG) do
            output = output .. string.format("[%d][%.2fs][%s] %s\n",
                entry.n, entry.time, entry.cat, entry.msg)
        end
        writefile("vertex_monitor_log.txt", output)
        log("FILE", "✅ Log exporté → vertex_monitor_log.txt", COLORS.FILE)
    end
end)

log("INFO", "✅ Tous les hooks sont actifs. Lance maintenant vertex.lua", COLORS.INFO)
log("INFO", string.format("Hooks actifs: HTTP, loadstring, __namecall, __index, __newindex, Instance.new, FS, require"), COLORS.INFO)
