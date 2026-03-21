-- ✅ Chargement de Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "murder mystery 2 Telakayhub",
   LoadingTitle = "TelaKayHub",
   LoadingSubtitle = "by kay",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "TelaKayHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local MainTab = Window:CreateTab("Main", nil)
local MainSection = MainTab:CreateSection("Main")

Rayfield:Notify({
   Title = "You excuted TelaKayHub",
   Content = "TelaKay Hub",
   Duration = 5,
   Image = nil,
   Actions = {
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
      game:GetService("UserInputService").JumpRequest:Connect(function()
         if infjmp then
            game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
         end
      end)
   end,
})

local WalkSpeedSlider = MainTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {0, 300},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "Slider1",
   Callback = function(Value)
      game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

local JumpSlider = MainTab:CreateSlider({
   Name = "Jump",
   Range = {0, 300},
   Increment = 1,
   Suffix = "jump",
   CurrentValue = 50,
   Flag = "Slider2",
   Callback = function(Value)
      game:GetService("Players").LocalPlayer.Character.Humanoid.JumpPower = Value
   end,
})

local mm2Tab = Window:CreateTab("mm2", nil)

local EspButton = mm2Tab:CreateButton({
   Name = "esp",
   Callback = function()
      local uis = game:GetService("UserInputService")
      local sg = game:GetService("StarterGui")
      local wp = game:GetService("Workspace")
      local cmr = wp.Camera
      local rs = game:GetService("ReplicatedStorage")
      local lgt = game:GetService("Lighting")
      local plrs = game:GetService("Players")
      local lplr = plrs.LocalPlayer
      local mouse = lplr:GetMouse()

      local faces = {"Back","Bottom","Front","Left","Right","Top"}
      local speed = 20
      local nameMap = ""

      function SendChat(String)
         game.StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[OUTPUT]: " .. String
         })
      end

      function enableESPCode()
         for _, o in pairs(plrs:GetPlayers()) do
            if o.Name ~= lplr.Name then
               o.CharacterAdded:Connect(function(characterModel)
                  wait(2)
                  local bgui = Instance.new("BillboardGui", o.Character.Head)
                  bgui.Name = "EGUI"
                  bgui.AlwaysOnTop = true
                  bgui.ExtentsOffset = Vector3.new(0, 3, 0)
                  bgui.Size = UDim2.new(0, 200, 0, 50)
                  local nam = Instance.new("TextLabel", bgui)
                  nam.Text = o.Name
                  nam.BackgroundTransparency = 1
                  nam.TextSize = 14
                  nam.Font = "Arial"
                  nam.TextColor3 = Color3.fromRGB(75, 151, 75)
                  nam.Size = UDim2.new(0, 200, 0, 50)
                  for _, p in pairs(o.Character:GetChildren()) do
                     if p.Name == "Head" then
                        for _, f in pairs(faces) do
                           local m = Instance.new("SurfaceGui", p)
                           m.Name = "EGUI"
                           m.Face = f
                           m.Active = true
                           m.AlwaysOnTop = true
                           local mf = Instance.new("Frame", m)
                           mf.Size = UDim2.new(1, 0, 1, 0)
                           mf.BorderSizePixel = 0
                           mf.BackgroundTransparency = 0.5
                           mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)

                           o.Backpack.ChildAdded:Connect(function(b)
                              if b.Name == "Gun" or b.Name == "Revolver" then
                                 mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                              elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                                 mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                              end
                           end)

                           o.Character.ChildAdded:Connect(function(c)
                              if c.Name == "Gun" or c.Name == "Revolver" then
                                 mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                              elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                                 mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                              end
                           end)
                        end
                     end
                  end

                  o.Backpack.ChildAdded:Connect(function(b)
                     if b.Name == "Gun" or b.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                     elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                     end
                  end)

                  o.Character.ChildAdded:Connect(function(c)
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
                  local bgui = Instance.new("BillboardGui", newPlayer.Character.Head)
                  bgui.Name = "EGUI"
                  bgui.AlwaysOnTop = true
                  bgui.ExtentsOffset = Vector3.new(0, 3, 0)
                  bgui.Size = UDim2.new(0, 200, 0, 50)
                  local nam = Instance.new("TextLabel", bgui)
                  nam.Text = newPlayer.Name
                  nam.BackgroundTransparency = 1
                  nam.TextSize = 14
                  nam.Font = "Arial"
                  nam.TextColor3 = Color3.fromRGB(75, 151, 75)
                  nam.Size = UDim2.new(0, 200, 0, 50)
                  for _, p in pairs(newPlayer.Character:GetChildren()) do
                     if p.Name == "Head" then
                        for _, f in pairs(faces) do
                           local m = Instance.new("SurfaceGui", p)
                           m.Name = "EGUI"
                           m.Face = f
                           m.Active = true
                           m.AlwaysOnTop = true
                           local mf = Instance.new("Frame", m)
                           mf.Size = UDim2.new(1, 0, 1, 0)
                           mf.BorderSizePixel = 0
                           mf.BackgroundTransparency = 0.5
                           mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)

                           newPlayer.Backpack.ChildAdded:Connect(function(b)
                              if b.Name == "Gun" or b.Name == "Revolver" then
                                 mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                              elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                                 mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                              end
                           end)

                           newPlayer.Character.ChildAdded:Connect(function(c)
                              if c.Name == "Gun" or c.Name == "Revolver" then
                                 mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                              elseif c.Name == "Knife" or c.Name == "Blade" or c.Name == "Battleaxe" then
                                 mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                              end
                           end)
                        end
                     end
                  end

                  newPlayer.Backpack.ChildAdded:Connect(function(b)
                     if b.Name == "Gun" or b.Name == "Revolver" then
                        nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                     elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                        nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                     end
                  end)

                  newPlayer.Character.ChildAdded:Connect(function(c)
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

         lplr.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if lplr.Character.Humanoid.WalkSpeed ~= speed then
               lplr.Character.Humanoid.WalkSpeed = speed
            end
         end)

         lplr.CharacterAdded:Connect(function(characterModel)
            wait(0.5)
            characterModel.Humanoid.WalkSpeed = speed
            characterModel.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
               if characterModel.Humanoid.WalkSpeed ~= speed then
                  characterModel.Humanoid.WalkSpeed = speed
               end
            end)
         end)

         wp.ChildAdded:Connect(function(m)
            if tostring(m) == "Bank" or tostring(m) == "Bank2" or tostring(m) == "BioLab" or tostring(m) == "Factory" then
               nameMap = m.Name
            elseif tostring(m) == "House2" or tostring(m) == "Office3" or tostring(m) == "Office2" then
               nameMap = m.Name
            elseif tostring(m) == "Workplace" or tostring(m) == "Mineshaft" or tostring(m) == "Hotel" then
               nameMap = m.Name
            elseif tostring(m) == "MilBase" or tostring(m) == "PoliceStation" then
               nameMap = m.Name
            elseif tostring(m) == "Hospital2" or tostring(m) == "Mansion2" or tostring(m) == "Lab2" then
               nameMap = m.Name
            end

            if tostring(m) == "GunDrop" then
               local bgui = Instance.new("BillboardGui", m)
               bgui.Name = "EGUI"
               bgui.AlwaysOnTop = true
               bgui.ExtentsOffset = Vector3.new(0, 0, 0)
               bgui.Size = UDim2.new(1, 0, 1, 0)
               local nam = Instance.new("TextLabel", bgui)
               nam.Text = "Gun Drop"
               nam.BackgroundTransparency = 1
               nam.TextSize = 10
               nam.Font = "Arial"
               nam.TextColor3 = Color3.fromRGB(245, 205, 48)
               nam.Size = UDim2.new(1, 0, 1, 0)
            end
         end)
      end

      enableESPCode()

      function espFirst()
         for _, o in pairs(plrs:GetPlayers()) do
            if o.Name ~= lplr.Name then
               local bgui = Instance.new("BillboardGui", o.Character.Head)
               bgui.Name = "EGUI"
               bgui.AlwaysOnTop = true
               bgui.ExtentsOffset = Vector3.new(0, 3, 0)
               bgui.Size = UDim2.new(0, 200, 0, 50)
               local nam = Instance.new("TextLabel", bgui)
               nam.Text = o.Name
               nam.BackgroundTransparency = 1
               nam.TextSize = 14
               nam.Font = "Arial"
               nam.TextColor3 = Color3.fromRGB(75, 151, 75)
               nam.Size = UDim2.new(0, 200, 0, 50)
               for _, p in pairs(o.Character:GetChildren()) do
                  if p.Name == "Head" then
                     for _, f in pairs(faces) do
                        local m = Instance.new("SurfaceGui", p)
                        m.Name = "EGUI"
                        m.Face = f
                        m.Active = true
                        m.AlwaysOnTop = true
                        local mf = Instance.new("Frame", m)
                        mf.Size = UDim2.new(1, 0, 1, 0)
                        mf.BorderSizePixel = 0
                        mf.BackgroundTransparency = 0.5
                        mf.BackgroundColor3 = Color3.fromRGB(75, 151, 75)

                        o.Backpack.ChildAdded:Connect(function(b)
                           if b.Name == "Gun" or b.Name == "Revolver" then
                              mf.BackgroundColor3 = Color3.fromRGB(13, 105, 172)
                           elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                              mf.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
                           end
                        end)

                        o.Character.ChildAdded:Connect(function(c)
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

               o.Backpack.ChildAdded:Connect(function(b)
                  if b.Name == "Gun" or b.Name == "Revolver" then
                     nam.TextColor3 = Color3.fromRGB(13, 105, 172)
                  elseif b.Name == "Knife" or b.Name == "Blade" or b.Name == "Battleaxe" then
                     nam.TextColor3 = Color3.fromRGB(196, 40, 28)
                  end
               end)

               o.Character.ChildAdded:Connect(function(c)
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
            elseif tostring(v) == "House2" or tostring(v) == "Office3" or tostring(v) == "Office2" then
               nameMap = v.Name
            elseif tostring(v) == "Workplace" or tostring(v) == "Mineshaft" or tostring(v) == "Hotel" then
               nameMap = v.Name
            elseif tostring(v) == "MilBase" or tostring(v) == "PoliceStation" then
               nameMap = v.Name
            elseif tostring(v) == "Hospital2" or tostring(v) == "Mansion2" or tostring(v) == "Lab2" then
               nameMap = v.Name
            end

            if tostring(v) == "GunDrop" then
               local bgui = Instance.new("BillboardGui", v)
               bgui.Name = "EGUI"
               bgui.AlwaysOnTop = true
               bgui.ExtentsOffset = Vector3.new(0, 0, 0)
               bgui.Size = UDim2.new(1, 0, 1, 0)
               local nam = Instance.new("TextLabel", bgui)
               nam.Text = "Gun Drop"
               nam.BackgroundTransparency = 1
               nam.TextSize = 10
               nam.Font = "Arial"
               nam.TextColor3 = Color3.fromRGB(245, 205, 48)
               nam.Size = UDim2.new(1, 0, 1, 0)
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
                        for i, c in pairs(s:GetChildren()) do
                           c.Transparency = 0.5
                           c.CFrame = lplr.Character.LowerTorso.CFrame
                        end
                     end
                     if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) == "10" then break end
                     wait(0.7)
                  end
               end
            elseif lplr.PlayerGui.MainGUI.Game.CashBag:FindFirstChild("Coins") then
               if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) ~= "15" then
                  for i = 15, 1, -1 do
                     local s = wp[nameMap]:FindFirstChild("CoinContainer")
                     local e = lplr.Character:FindFirstChild("LowerTorso")
                     if e and s then
                        for i, c in pairs(s:GetChildren()) do
                           c.Transparency = 0.5
                           c.CFrame = lplr.Character.LowerTorso.CFrame
                        end
                     end
                     if tostring(lplr.PlayerGui.MainGUI.Game.CashBag.Coins.Text) == "15" then break end
                     wait(0.7)
                  end
               end
            end
         end
      end

      function bringGun()
         if wp:FindFirstChild("GunDrop") then
            wp.GunDrop.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(2, 0, 0)
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

      mouse.KeyDown:Connect(function(keyDown)
         if keyDown == "l" then tpCoin() end
         if keyDown == "k" then bringGun() end
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

local AimbotButton = mm2Tab:CreateButton({
   Name = "aimbot",
   Callback = function()
      getgenv().Prediction = 0.18
      getgenv().FOV = 60
      getgenv().AimKey = "c"
      getgenv().DontShootThesePeople = {
         "AimLockPsycho";
         "JakeTheMiddleMan";
      }

      local SilentAim = true
      local LocalPlayer = game:GetService("Players").LocalPlayer
      local Players = game:GetService("Players")
      local Mouse = LocalPlayer:GetMouse()
      local Camera = game:GetService("Workspace").CurrentCamera
      local connections = getconnections(game:GetService("LogService").MessageOut)
      for _, v in ipairs(connections) do
         v:Disable()
      end

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
               local Formulate = Madox.CFrame + (Madox.AssemblyLinearVelocity * getgenv().Prediction + Vector3.new(0, -1, 0))
               return (Index:lower() == gboost and Formulate)
            end
            return Screw
         end
         return oldIndex(self, Index, Screw)
      end)
   end,
})

local GrabGunButton = mm2Tab:CreateButton({
   Name = "grab gun",
   Callback = function()
      local currentX = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.X
      local currentY = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Y
      local currentZ = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Z

      if workspace:FindFirstChild("GunDrop") ~= nil then
         game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace:FindFirstChild("GunDrop").CFrame
         wait(.25)
         game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(currentX, currentY, currentZ)
      else
         game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error!",
            Text = "Failed To Get the gun, Be faster next time!",
            Duration = 7,
            Button1 = "OK",
         })
         wait(3)
      end
   end,
})

-- ✅ AUTO FARM AJOUTÉ ICI
local autoFarmActive = false

local AutoFarmToggle = mm2Tab:CreateToggle({
   Name = "Auto Farm Coins",
   CurrentValue = false,
   Flag = "AutoFarm1",
   Callback = function(Value)
      autoFarmActive = Value

      if Value then
         Rayfield:Notify({
            Title = "Auto Farm",
            Content = "Auto Farm activé !",
            Duration = 3,
            Image = nil,
         })

         task.spawn(function()
            while autoFarmActive do
               local wp = game:GetService("Workspace")
               local lplr = game:GetService("Players").LocalPlayer
               local char = lplr.Character

               for _, mapName in pairs({
                  "Bank","Bank2","BioLab","Factory","House2",
                  "Office3","Office2","Workplace","Mineshaft",
                  "Hotel","MilBase","PoliceStation","Hospital2",
                  "Mansion2","Lab2"
               }) do
                  local map = wp:FindFirstChild(mapName)
                  if map then
                     local coinContainer = map:FindFirstChild("CoinContainer")
                     if coinContainer and char and char:FindFirstChild("LowerTorso") then
                        for _, coin in pairs(coinContainer:GetChildren()) do
                           if coin:IsA("BasePart") then
                              coin.CFrame = char.LowerTorso.CFrame
                              task.wait(0.1)
                           end
                        end
                     end
                  end
               end

               if wp:FindFirstChild("GunDrop") and char and char:FindFirstChild("HumanoidRootPart") then
                  char.HumanoidRootPart.CFrame = wp.GunDrop.CFrame
                  task.wait(0.2)
               end

               task.wait(1)
            end
         end)

      else
         autoFarmActive = false
         Rayfield:Notify({
            Title = "Auto Farm",
            Content = "Auto Farm désactivé !",
            Duration = 3,
            Image = nil,
         })
      end
   end,
})

local ExampleButton = mm2Tab:CreateButton({
   Name = "Button Example",
   Callback = function()
   end,
})
