local library = {count = 0, queue = {}, callbacks = {}, rainbowtable = {}, toggled = true, binds = {}}
local defaults

-- Couleurs futuristes : violet, blanc et accents lumineux
local futuristicTheme = {
    backgroundColor = Color3.fromRGB(30, 30, 30),  -- Fond sombre
    buttonColor = Color3.fromRGB(60, 60, 60),       -- Boutons gris foncé
    textColor = Color3.fromRGB(255, 255, 255),      -- Texte en blanc
    accentColor = Color3.fromRGB(130, 45, 255),     -- Violet
    borderColor = Color3.fromRGB(80, 80, 80),       -- Bordures grises
    shadowColor = Color3.fromRGB(0, 0, 0)           -- Ombres noires
}

do
    local dragger = {}

    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local inputService = game:GetService('UserInputService')
    local heartbeat = game:GetService("RunService").Heartbeat

    function dragger.new(frame)
        local s, event = pcall(function()
            return frame.MouseEnter
        end)

        if s then
            frame.Active = true
            event:connect(function()
                local input = frame.InputBegan:connect(function(key)
                    if key.UserInputType == Enum.UserInputType.MouseButton1 then
                        local objectPosition = Vector2.new(mouse.X - frame.AbsolutePosition.X, mouse.Y - frame.AbsolutePosition.Y)
                        while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            pcall(function()
                                frame:TweenPosition(UDim2.new(0, mouse.X - objectPosition.X, 0, mouse.Y - objectPosition.Y), 'Out', 'Linear', 0.1, true)
                            end)
                        end
                    end
                end)

                local leave
                leave = frame.MouseLeave:connect(function()
                    input:disconnect()
                    leave:disconnect()
                end)
            end)
        end
    end

    game:GetService('UserInputService').InputBegan:connect(function(key, gpe)
        if (not gpe) then
            if key.KeyCode == Enum.KeyCode.RightControl then
                library.toggled = not library.toggled
                for i, data in next, library.queue do
                    local pos = (library.toggled and data.p or UDim2.new(-1, 0, -0.5, 0))
                    data.w:TweenPosition(pos, (library.toggled and 'Out' or 'In'), 'Quad', 0.15, true)
                    wait()
                end
            end
        end
    end)

    local types = {}
    types.__index = types

    function types.window(name, options)
        library.count = library.count + 1
        local newWindow = library:Create('Frame', {
            Name = name,
            Size = UDim2.new(0, 350, 0, 50),  -- Taille augmentée pour plus de confort
            BackgroundColor3 = options.topcolor or futuristicTheme.backgroundColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, (15 + (350 * library.count) - 350), 0, 0),
            ZIndex = 3,
            Parent = library.container
        })

        -- Titre avec ombre et bordures arrondies
        library:Create('TextLabel', {
            Text = name,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = options.titlesize or 20,
            TextColor3 = options.titletextcolor or futuristicTheme.textColor,
            TextStrokeTransparency = 0.5,
            TextStrokeColor3 = futuristicTheme.accentColor,
            ZIndex = 3
        })

        -- Bouton de fermeture avec coins arrondis
        library:Create("TextButton", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -35, 0, 0),
            BackgroundTransparency = 1,
            Text = "-",
            TextSize = options.titlesize or 20,
            Font = Enum.Font.Code,
            TextColor3 = options.titletextcolor or futuristicTheme.textColor,
            TextStrokeTransparency = 0.5,
            TextStrokeColor3 = futuristicTheme.accentColor,
            ZIndex = 3,
            Parent = newWindow
        })

        -- Conteneur de la fenêtre avec coins arrondis
        library:Create('Frame', {
            Name = 'container',
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = options.bgcolor or futuristicTheme.buttonColor,
            ClipsDescendants = false,
            BorderRadius = UDim.new(0, 10),  -- Coins arrondis
            Parent = newWindow
        })

        -- Événement pour la fermeture de la fenêtre
        newWindow:FindFirstChild("window_toggle").MouseButton1Click:connect(function()
            window.toggled = not window.toggled
            newWindow:FindFirstChild("window_toggle").Text = (window.toggled and "+" or "-")
            if (not window.toggled) then
                window.container.ClipsDescendants = true
            end
            wait()
            local y = 0
            for i, v in next, window.container:GetChildren() do
                if (not v:IsA('UIListLayout')) then
                    y = y + v.AbsoluteSize.Y
                end
            end

            local targetSize = window.toggled and UDim2.new(1, 0, 0, y + 5) or UDim2.new(1, 0, 0, 0)
            local targetDirection = window.toggled and "In" or "Out"

            window.container:TweenSize(targetSize, targetDirection, "Quint", .3, true)
            wait(.3)
            if window.toggled then
                window.container.ClipsDescendants = false
            end
        end)

        return window
    end

    -- Fonction pour mettre à jour la taille de la fenêtre
    function types:Resize()
        local y = 0
        for i, v in next, self.container:GetChildren() do
            if (not v:IsA('UIListLayout')) then
                y = y + v.AbsoluteSize.Y
            end
        end
        self.container.Size = UDim2.new(1, 0, 0, y + 5)
    end

    -- Fonction pour obtenir l'ordre des éléments
    function types:GetOrder()
        local c = 0
        for i, v in next, self.container:GetChildren() do
            if (not v:IsA('UIListLayout')) then
                c = c + 1
            end
        end
        return c
    end

    -- Création d'une option de Toggle avec animation moderne
    function types:Toggle(name, options, callback)
        local default = options.default or false
        local location = options.location or self.flags
        local flag = options.flag or ""
        local callback = callback or function() end

        location[flag] = default

        local check = library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = self:GetOrder(),
            library:Create('TextLabel', {
                Name = name,
                Text = "\r" .. name,
                BackgroundTransparency = 1,
                TextColor3 = library.options.textcolor,
                Position = UDim2.new(0, 5, 0, 0),
                Size = UDim2.new(1, -5, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = library.options.font,
                TextSize = library.options.fontsize,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3 = library.options.strokecolor,
                library:Create('TextButton', {
                    Text = (location[flag] and utf8.char(10003) or ""),
                    Font = library.options.font,
                    TextSize = library.options.fontsize,
                    Name = 'Checkmark',
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -25, 0, 4),
                    TextColor3 = library.options.textcolor,
                    BackgroundColor3 = library.options.bgcolor,
                    BorderColor3 = library.options.bordercolor,
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3 = library.options.strokecolor,
                })
            }),
            Parent = self.container
        })

        local function click(t)
            location[flag] = not location[flag]
            callback(location[flag])
            check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or ""
        end

        check:FindFirstChild(name).Checkmark.MouseButton1Click:connect(click)
        library.callbacks[flag] = click

        if location[flag] == true then
            callback(location[flag])
        end

        self:Resize()

        return {
            Set = function(self, b)
                location[flag] = b
                callback(location[flag])
                check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or ""
            end
        }
    end

    -- Création d'un bouton avec animation de "click"
    function types:Button(name, callback)
        callback = callback or function() end

        local check = library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = self:GetOrder(),
            library:Create('TextButton', {
                Name = name,
                Text = name,
                BackgroundColor3 = library.options.btncolor,
                BorderColor3 = library.options.bordercolor,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3 = library.options.strokecolor,
                TextColor3 = library.options.textcolor,
                Position = UDim2.new(0, 5, 0, 5),
                Size = UDim2.new(1, -10, 0, 20),
                Font = library.options.font,
                TextSize = library.options.fontsize,
            }),
            Parent = self.container
        })

        check:FindFirstChild(name).MouseButton1Click:connect(function()
            check:FindFirstChild(name):TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Elastic", 0.2, true)
            wait(0.1)
            check:FindFirstChild(name):TweenSize(UDim2.new(1, -10, 0, 30), "In", "Elastic", 0.2, true)
            callback()
        end)

        self:Resize()

        return {
            Fire = function()
                callback()
            end
        }
    end

    -- Fonction pour créer une fenêtre personnalisée
    function library:CreateWindow(name, options)
        if (not library.container) then
            library.container = self:Create("ScreenGui", {
                self:Create('Frame', {
                    Name = 'Container',
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Active = false
                }),
                Parent = game:GetService("CoreGui")
            }):FindFirstChild('Container')
        end

        if (not library.options) then
            library.options = setmetatable(options or {}, {__index = defaults})
        end

        if (options) then
            library.options = setmetatable(options, {__index = default})
        end

        local window = types.window(name, library.options)
        dragger.new(window.object)
        return window
    end

    library.options = setmetatable({}, {__index = default})

    spawn(function()
        while true do
            for i = 0, 1, 1 / 300 do
                for _, obj in next, library.rainbowtable do
                    obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1)
                end
                wait()
            end
        end
    end)

end

return library

