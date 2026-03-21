
local Window = Rayfield:CreateWindow({
   Name = "murder mystery 2 Telakayhub",
   LoadingTitle = "TelaKayHub",
   LoadingSubtitle = "by kay",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "TelaKayHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },
   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local MainTab = Window:CreateTab("Main", nil) -- Title, Image
local MainSection = MainTab:CreateSection("Main")

Rayfield:Notify({
   Title = "You excuted TelaKayHub",
   Content = "TelaKay Hub",
   Duration = 5,
   Image = nil,
   Actions = { -- Notification Buttons
      Ignore = {
         Name = "Okay!",
         Callback = function()
         print("The user tapped Okay!")
      end
   },
},
})

local Button = MainTab:CreateButton({
   Name = "infinitejump",
   Callback = function()
       local infjmp = true
game:GetService("UserInputService").jumpRequest:Connect(function()
    if infjmp then
        game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass"Humanoid":ChangeState("Jumping")
    end
end)

   end,
})

local Slider = MainTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {0, 300},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
          game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = (Value)
   end,
})

local mm2Tab = Window:CreateTab("mm2", nil) -- Title, Image

local Button = mm2Tab:CreateButton({
   Name = "esp",
   Callback = function()
        local uis = game:GetService("UserInputService")
local sg = game:GetService("StarterGui")
local wp = game:GetService("Workspace")
local cmr = wp.Camera
local rs =  game:GetService("ReplicatedStorage")
local lgt = game:GetService("Lighting")
local plrs = game:GetService("Players")
local lplr = plrs.LocalPlayer
local mouse = lplr:GetMouse()
 
local faces = {"Back","Bottom","Front","Left","Right","Top"}
local speed = 20
local nameMap = ""
 
function SendChat(String) -- Send a chat to the game chat
   game.StarterGui:SetCore("ChatMakeSystemMessage", {
   Text = '[OUTPUT]: ' .. String
})
end
 
function enableESPCode()
    for _, o in pairs(plrs:GetPlayers()) do
       if o.Name ~= lplr.Name then
            o.CharacterAdded:Connect(function(characterModel)
                wait(2)
                local bgui = Instance.new("BillboardGui",o.Character.Head)
                bgui.Name = ("EGUI")
                bgui.AlwaysOnTop = true
                bgui.ExtentsOffset = Vector3.new(0,3,0)
                bgui.Size = UDim2.new(0,200,0,50)
                local nam = Instance.new("TextLabel",bgui)
                nam.Text = o.Name
                nam.BackgroundTransparency = 1
                nam.TextSize = 14
                nam.Font = ("Arial")
                nam.TextColor3 = Color3.fromRGB(75, 151, 75)
                nam.Size = UDim2.new(0,200,0,50)
                for _, p in pairs(o.Character:GetChildren()) do
                    if p.Name == ("Head") then 
                        for _, f in pairs(faces) do
                            local m = Instance.new("SurfaceGui",p)
                            m.Name = ("EGUI")
                            m.Face = f
                            m.Active      = true
                            m.AlwaysOnTop = true
                            local mf = Instance.new("Frame",m)
                            mf.Size = UDim2.new(1,0,1,0)
                            mf.BorderSizePixel = 0
                            mf.BackgroundTransparency = 0.5
                            mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)
 
                            o.Backpack.ChildAdded:connect(function(b)
                                if b.Name == "Gun" or b.Name == "Revolver" then
                                    mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                                elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                                    mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                                end
                            end)
            
                            o.Character.ChildAdded:connect(function(c)
                                if c.Name == "Gun" or c.Name == "Revolver" then
                                    mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                                elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                                    mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                                end
                            end)
                        end
                    end
                end
    
                o.Backpack.ChildAdded:connect(function(b)
                    if b.Name == "Gun" or b.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                    elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                    end
                end)
    
                o.Character.ChildAdded:connect(function(c)
                    if c.Name == "Gun" or c.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                    elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                    end
                end)
 
            end)
        end
    end
 
    plrs.PlayerAdded:Connect(function(newPlayer)
        if newPlayer.Name ~= lplr.Name then
            newPlayer.CharacterAdded:Connect(function(characterModel)
                wait(2)
                local bgui = Instance.new("BillboardGui",newPlayer.Character.Head)
                bgui.Name = ("EGUI")
                bgui.AlwaysOnTop = true
                bgui.ExtentsOffset = Vector3.new(0,3,0)
                bgui.Size = UDim2.new(0,200,0,50)
                local nam = Instance.new("TextLabel",bgui)
                nam.Text = newPlayer.Name
                nam.BackgroundTransparency = 1
                nam.TextSize = 14
                nam.Font = ("Arial")
                nam.TextColor3 = Color3.fromRGB(75, 151, 75)
                nam.Size = UDim2.new(0,200,0,50)
                for _, p in pairs(newPlayer.Character:GetChildren()) do
                    if p.Name == ("Head") then 
                        for _, f in pairs(faces) do
                            local m = Instance.new("SurfaceGui",p)
                            m.Name = ("EGUI")
                            m.Face = f
                            m.Active      = true
                            m.AlwaysOnTop = true
                            local mf = Instance.new("Frame",m)
                            mf.Size = UDim2.new(1,0,1,0)
                            mf.BorderSizePixel = 0
                            mf.BackgroundTransparency = 0.5
                            mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)
 
                            newPlayer.Backpack.ChildAdded:connect(function(b)
                                if b.Name == "Gun" or b.Name == "Revolver" then
                                    mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                                elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                                    mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                                end
                            end)
            
                            newPlayer.Character.ChildAdded:connect(function(c)
                                if c.Name == "Gun" or c.Name == "Revolver" then
                                    mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                                elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                                    mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                                end
                            end)
                        end
                    end
                end
    
                newPlayer.Backpack.ChildAdded:connect(function(b)
                    if b.Name == "Gun" or b.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                    elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                    end
                end)
    
                newPlayer.Character.ChildAdded:connect(function(c)
                    if c.Name == "Gun" or c.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                    elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                    end
                end)
            end)
        end
    end)
 
    lplr.Character.Humanoid.WalkSpeed = speed
 
    lplr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):connect(function()
       if lplr.Character.Humanoid.WalkSpeed ~= speed then
           lplr.Character.Humanoid.WalkSpeed = speed
       end
    end)
    
    lplr.CharacterAdded:Connect(function(characterModel)
       wait(0.5)
       characterModel.Humanoid.WalkSpeed = speed
       characterModel.Humanoid:GetPropertyChangedSignal("WalkSpeed"):connect(function()
           if characterModel.Humanoid.WalkSpeed ~= speed then
               characterModel.Humanoid.WalkSpeed = speed
           end
       end)
    end)
    
    
    wp.ChildAdded:connect(function(m)
        if tostring(m) == "Bank" or tostring(m) == "Bank2" or tostring(m) == "BioLab" or tostring(m) == "Factory" then
            nameMap = m.Name
            print(nameMap)
        elseif tostring(m) == "House2" or tostring(m) == "Office3" or tostring(m) == "Office2" then
            nameMap = m.Name
            print(nameMap)
        elseif tostring(m) == "Workplace" or tostring(m) == "Mineshaft" or tostring(m) == "Hotel" then
            nameMap = m.Name
            print(nameMap)
        elseif tostring(m) == "MilBase" or tostring(m) == "PoliceStation" then
            nameMap = m.Name
            print(nameMap)
        elseif tostring(m) == "Hospital2" or tostring(m) == "Mansion2" or tostring(m) == "Lab2" then
            nameMap = m.Name
            print(nameMap)
        end
 
        if tostring(m) == "GunDrop" then
            local bgui = Instance.new("BillboardGui",m)
            bgui.Name = ("EGUI")
            bgui.AlwaysOnTop = true
            bgui.ExtentsOffset = Vector3.new(0,0,0)
            bgui.Size = UDim2.new(1,0,1,0)
            local nam = Instance.new("TextLabel",bgui)
            nam.Text = "Gun Drop"
            nam.BackgroundTransparency = 1
            nam.TextSize = 10
            nam.Font = ("Arial")
            nam.TextColor3 = Color3.fromRGB(245, 205, 48)
            nam.Size = UDim2.new(1,0,1,0)
        end
    end)
end
 
enableESPCode()
 
function espFirst()
    for _, o in pairs(plrs:GetPlayers()) do
       if o.Name ~= lplr.Name then
            local bgui = Instance.new("BillboardGui",o.Character.Head)
            bgui.Name = ("EGUI")
            bgui.AlwaysOnTop = true
            bgui.ExtentsOffset = Vector3.new(0,3,0)
            bgui.Size = UDim2.new(0,200,0,50)
            local nam = Instance.new("TextLabel",bgui)
            nam.Text = o.Name
            nam.BackgroundTransparency = 1
            nam.TextSize = 14
            nam.Font = ("Arial")
            nam.TextColor3 = Color3.fromRGB(75, 151, 75)
            nam.Size = UDim2.new(0,200,0,50)
            for _, p in pairs(o.Character:GetChildren()) do
                if p.Name == ("Head") then 
                    for _, f in pairs(faces) do
                        local m = Instance.new("SurfaceGui",p)
                        m.Name = ("EGUI")
                        m.Face = f
                        m.Active      = true
                        m.AlwaysOnTop = true
                        local mf = Instance.new("Frame",m)
                        mf.Size = UDim2.new(1,0,1,0)
                        mf.BorderSizePixel = 0
                        mf.BackgroundTransparency = 0.5
                        mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)
 
                        o.Backpack.ChildAdded:connect(function(b)
                            if b.Name == "Gun" or b.Name == "Revolver" then
                                mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                            elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                                mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                            end
                        end)
        
                        o.Character.ChildAdded:connect(function(c)
                            if c.Name == "Gun" or c.Name == "Revolver" then
                                mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                            elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                                mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                            end
                        end)
 
                        if o.Backpack:FindFirstChild("Gun") or o.Backpack:FindFirstChild("Revolver") or o.Character:FindFirstChild("Gun") or o.Character:FindFirstChild("Revolver") then
                            mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                        elseif o.Backpack:FindFirstChild("Knife") or o.Backpack:FindFirstChild("Blade") or o.Backpack:FindFirstChild("Battleaxe") or o.Character:FindFirstChild("Knife") or o.Character:FindFirstChild("Blade") or o.Character:FindFirstChild("Battleaxe") then
                            mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                        end
                    end
                end
            end
 
            o.Backpack.ChildAdded:connect(function(b)
                if b.Name == "Gun" or b.Name == "Revolver" then
                    nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                    nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                end
            end)
 
            o.Character.ChildAdded:connect(function(c)
                if c.Name == "Gun" or c.Name == "Revolver" then
                    nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                    nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                end
            end)
 
            if o.Backpack:FindFirstChild("Gun") or o.Backpack:FindFirstChild("Revolver") or o.Character:FindFirstChild("Gun") or o.Character:FindFirstChild("Revolver") then
                nam.TextColor3 = Color3.fromRGB(13, 105, 172)
            elseif o.Backpack:FindFirstChild("Knife") or o.Backpack:FindFirstChild("Blade") or o.Backpack:FindFirstChild("Battleaxe") or o.Character:FindFirstChild("Knife") or o.Character:FindFirstChild("Blade") or o.Character:FindFirstChild("Battleaxe") then
                nam.TextColor3 = Color3.fromRGB(196, 40, 28)
            end
        end
    end
 
    for _, v in pairs(wp:GetChildren()) do
        if tostring(v) == "Bank" or tostring(v) == "Bank2" or tostring(v) == "BioLab" or tostring(v) == "Factory" then
            nameMap = v.Name
            print(nameMap)
        elseif tostring(v) == "House2" or tostring(v) == "Office3" or tostring(v) == "Office2" then
            nameMap = v.Name
            print(nameMap)
        elseif tostring(v) == "Workplace" or tostring(v) == "Mineshaft" or tostring(v) == "Hotel" then
            nameMap = v.Name
            print(nameMap)
        elseif tostring(v) == "MilBase" or tostring(v) == "PoliceStation" then
            nameMap = m.Name
            print(nameMap)
        elseif tostring(v) == "Hospital2" or tostring(v) == "Mansion2" or tostring(v) == "Lab2" then
            nameMap = v.Name
            print(nameMap)
        end
 
        if tostring(m) == "GunDrop" then
            local bgui = Instance.new("BillboardGui",m)
            bgui.Name = ("EGUI")
            bgui.AlwaysOnTop = true
            bgui.ExtentsOffset = Vector3.new(0,0,0)
            bgui.Size = UDim2.new(1,0,1,0)
            local nam = Instance.new("TextLabel",bgui)
            nam.Text = "Gun Drop"
            nam.BackgroundTransparency = 1
            nam.TextSize = 10
            nam.Font = ("Arial")
            nam.TextColor3 = Color3.fromRGB(245, 205, 48)
            nam.Size = UDim2.new(1,0,1,0)
        end
    end
end
 
function tpCoin()
    if nameMap ~= "" and wp[nameMap] ~= nil then
        if lplr.PlayerGui.MainGUI.Game.CashBag:FindFirstChild("Elite") then
            if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) ~= "10" then
                for i = 10, 1, -1 do
                    local s = wp[nameMap]:FindFirstChild("CoinContainer")
                    local e = lplr.Character:FindFirstChild("LowerTorso")
                    if e and s then
                        for i,c in pairs(s:GetChildren()) do
                            c.Transparency = 0.5
                            c.CFrame = lplr.Character.LowerTorso.CFrame
                        end
                    end
                    if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) == "10" then
                        break
                    end
                    wait(0.7)
                end
            end
        elseif lplr.PlayerGui.MainGUI.Game.CashBag:FindFirstChild("Coins") then
            if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) ~= "15" then
                for i = 15, 1, -1 do
                    local s = wp[nameMap]:FindFirstChild("CoinContainer")
                    local e = lplr.Character:FindFirstChild("LowerTorso")
                    if e and s then
                        for i,c in pairs(s:GetChildren()) do
                            c.Transparency = 0.5
                            c.CFrame = lplr.Character.LowerTorso.CFrame
                        end
                    end
                    if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) == "15" then
                        break
                    end
                    wait(0.7)
                end
            end
        end
    end
end
 
function bringGun()
    if wp:FindFirstChild("GunDrop") then
        wp.GunDrop.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
    end
end
 
function changeWS(typeWS)
    if typeWS == 0 then
       speed = speed + 5
       lplr.Character.Humanoid.WalkSpeed = speed
   elseif typeWS == 1 then
       if speed >= 0 then
           speed = speed - 5
           lplr.Character.Humanoid.WalkSpeed = speed
       end
       if speed < 0 then
           speed = 0
           lplr.Character.Humanoid.WalkSpeed = speed
       end
    end
end
 
mouse.KeyDown:connect(function(keyDown)
    
    if keyDown == "l" then
        tpCoin()
    end
    
    if keyDown == "k" then
        bringGun()
    end
    
    if keyDown == "c" then
        changeWS(0)
        SendChat("Walk Speed :" .. lplr.Character.Humanoid.WalkSpeed)
    end
    
    if keyDown == "v" then
        changeWS(1)
        SendChat("Walk Speed :" .. lplr.Character.Humanoid.WalkSpeed)
    end
end)
 
espFirst()

   end,
})

local Button = mm2Tab:CreateButton({
   Name = "aimbot",
   Callback = function()
        getgenv().Prediction =  (  .18  )   -- [ PREDICTION: Lower Prediction: Lower Ping | Higher Prediction: Higher Ping  ]
 
getgenv().FOV =  (  60  )   -- [ FOV RADIUS: Increases Or Decreases FOV Radius ]
 
getgenv().AimKey =  (  "c"  )  -- [ TOGGLE KEY: Toggles Silent Aim On And Off ]
 
getgenv().DontShootThesePeople = {  -- [ WHITELIST: List Of Who NOT To Shoot, edit like this. "Contain quotations with their name and then a semi-colon afterwards for each line" ; ]
 
	"AimLockPsycho";
	"JakeTheMiddleMan";
 
}
 
--[[
		Do Not Edit Anything Beyond This Point. 
]]
 
local SilentAim = true
local LocalPlayer = game:GetService("Players").LocalPlayer
local Players = game:GetService("Players")
local Mouse = LocalPlayer:GetMouse()
local Camera = game:GetService("Workspace").CurrentCamera
local connections = getconnections(game:GetService("LogService").MessageOut)
for _, v in ipairs(connections) do
	v:Disable()
end
 
getrawmetatable = getrawmetatable
setreadonly = setreadonly
getconnections = getconnections
hookmetamethod = hookmetamethod
getgenv = getgenv
Drawing = Drawing
 
local FOV_CIRCLE = Drawing.new("Circle")
FOV_CIRCLE.Visible = true
FOV_CIRCLE.Filled = false
FOV_CIRCLE.Thickness = 1
FOV_CIRCLE.Transparency = 1
FOV_CIRCLE.Color = Color3.new(0, 1, 0)
FOV_CIRCLE.Radius = getgenv().FOV
FOV_CIRCLE.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
 
Options = {
	Torso = "HumanoidRootPart";
	Head = "Head";
}
 
local function MoveFovCircle()
	pcall(function()
		local DoIt = true
		spawn(function()
			while DoIt do task.wait()
				FOV_CIRCLE.Position = Vector2.new(Mouse.X, (Mouse.Y + 36))
			end
		end)
	end)
end coroutine.wrap(MoveFovCircle)()
 
Mouse.KeyDown:Connect(function(KeyPressed)
	if KeyPressed == (getgenv().AimKey:lower()) then
		if SilentAim == false then
			FOV_CIRCLE.Color = Color3.new(0, 1, 0)
			SilentAim = true
		elseif SilentAim == true then
			FOV_CIRCLE.Color = Color3.new(1, 0, 0)
			SilentAim = false
		end
	end
end)
Mouse.KeyDown:Connect(function(Rejoin)
	if Rejoin == "=" then
		local LocalPlayer = game:GetService("Players").LocalPlayer
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end
end)
 
 
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", function(self, Index, Screw)
	local Screw = oldIndex(self, Index)
	local kalk = Mouse
	local cc = "hit"
	local gboost = cc
	if self == kalk and (Index:lower() == gboost) then
		local Distance = 9e9
		local Target = nil
		local Players = game:GetService("Players")
		local LocalPlayer = game:GetService("Players").LocalPlayer
		local Camera = game:GetService("Workspace").CurrentCamera
		for _, v in pairs(Players:GetPlayers()) do 
			if not table.find(getgenv().DontShootThesePeople, v.Name) then
				if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("Humanoid").Health > 0 then
					local Enemy = v.Character	
					local CastingFrom = CFrame.new(Camera.CFrame.Position, Enemy[Options.Torso].CFrame.Position) * CFrame.new(0, 0, -4)
					local RayCast = Ray.new(CastingFrom.Position, CastingFrom.LookVector * 9000)
					local World, ToSpace = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(RayCast, {LocalPlayer.Character:FindFirstChild("Head")})
					local RootWorld = (Enemy[Options.Torso].CFrame.Position - ToSpace).magnitude
					if RootWorld < 4 then		
						local RootPartPosition, Visible = Camera:WorldToScreenPoint(Enemy[Options.Torso].Position)
						if Visible then
							local Real_Magnitude = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(RootPartPosition.X, RootPartPosition.Y)).Magnitude
							if Real_Magnitude < Distance and Real_Magnitude < FOV_CIRCLE.Radius then
								Distance = Real_Magnitude
								Target = Enemy
							end
						end
					end
				end
			end
		end
 
		if Target ~= nil and Target[Options.Torso] and Target:FindFirstChild("Humanoid") and Target:FindFirstChild("Humanoid").Health > 0 then
			local Madox = Target[Options.Torso]
			local Formulate = Madox.CFrame + (Madox.AssemblyLinearVelocity * getgenv().Prediction + Vector3.new(0,-1,0))	
			return (Index:lower() == gboost and Formulate)
		end
		return Screw
	end
	return oldIndex(self, Index, Screw)
end)
   end,
})

local Button = mm2Tab:CreateButton({
   Name = "grab gun",
   Callback = function()
        local script = Instance.new('LocalScript')
 
 
		local currentX = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.X
		local currentY = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Y
		local currentZ = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Z	
 
		if workspace:FindFirstChild("GunDrop") ~= nil then
 
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace:FindFirstChild("GunDrop").CFrame	
		wait(.25)	
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(currentX, currentY, currentZ)
 
		else
 
game:GetService("StarterGui"):SetCore("SendNotification",{
Title = "Error!",
Text = "Failed To Get the gun , Be faster next time retard",
Duration = 7,
Button1 = "OK",
Callback = cb
})
 
 
		wait(3)
 
 
		end
   end,
})

local Button = Tab:CreateButton({
   Name = "Button Example",
   Callback = function()
   -- The function that takes place when the button is pressed
   end,
})

local Slider = MainTab:CreateSlider({
   Name = "jump",
   Range = {0, 300},
   Increment = 1,
   Suffix = "jump",
   CurrentValue = 16,
   Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
          game:GetService('Players').LocalPlayer.Character.Humanoid.JumpPower = (value)
   end,
})
