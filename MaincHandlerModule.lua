local module = {}

local function sub(...)
	task.spawn(...)
end

local TS = game:GetService("TweenService")

local player
local character
local hum
local effects
local info
--local stats
local preloaded 
local root 

local repAnimFolder = game.ReplicatedStorage.Assets.Animations
local cdRemote = game.ReplicatedStorage.Notify

function checkIfStunned()
	if effects:FindFirstChild("Stunned") or effects:FindFirstChild("CombatDisable") or effects:FindFirstChild("Carried") then
		return true
	end
end

--carry params are up here, required because of character argument
local CanDrop
local last_target
local carriedanim
local carryanim
local weld = nil 
local CarryCD = false
local CarryTags = {}
local CarryMassless = {}
local carryanim
local connectio  = nil
local c
--loaded anims
local helmetOn 
local helmetOff 
module.init = function(arg) -- {player = player, character = character, hum = humanoid, root = root, effects = effects, info = info, preloaded = preloaded, stats = stats}
	player = arg.player
	character = arg.character
	hum = arg.hum
	root = arg.root
	effects = arg.effects
	info = arg.info
	preloaded = arg.preloaded
	--stats = arg.stats
	
	helmetOn = hum:LoadAnimation(repAnimFolder.HelmetOn)
	helmetOff = hum:LoadAnimation(repAnimFolder.HelmetOff)
	
	local Events = character:WaitForChild("Events")
	local ForceDrop = Events:WaitForChild("ForceDrop")
	ForceDrop.Event:Connect(function(Character) 
		if CanDrop == true and last_target then
			for i,v in pairs(CarryTags) do
				v:Destroy()
			end

			if carryanim then
				carryanim:Stop()
				carryanim:Destroy()
			end

			if carriedanim then
				carriedanim:Stop()
				carriedanim:Destroy()
			end
		end
	end)
	
	warn("Initialized")	
end

------------------------------------------------
--LINDACHAR
------------------------------------------------
local saberOn = false
local handsOn = false
local equipAnim
local FSCD = nil
module.equipWeapon = function(arg) -- {which = which}
	local which = arg.which
	if effects:FindFirstChild("Carried") then return end 
	if effects:FindFirstChild("Stunned") then return end 
	if effects:FindFirstChild("Attacking") then return end
	if effects:FindFirstChild("Knocked") then return end 
	if FSCD then return end

	if info.Which.Value == which then -- equipping same slot again
		if info.WeaponEquipped.Value then --equip
			info.WeaponEquipped.Value = false
			info.Which.Value = ""
			info.CurrentWeapon.Value = ""
			hum:UnequipTools()
		end
	else --either nothing equipped or equipping a new weapon
		if which == "primary" then
			if info.PrimaryWeapon.Value == "" then warn("Priamry is empty") return end
			warn("Equipping primary")
			info.WeaponEquipped.Value = true
			info.CurrentWeapon.Value = info.PrimaryWeapon.Value
			hum:UnequipTools()
			hum:EquipTool(player.Backpack:FindFirstChild(info.CurrentWeapon.Value))
			info.Which.Value = which
		elseif which == "secondary" then
			if info.SecondaryWeapon.Value == "" then warn("Secondary is empty") return end
			info.WeaponEquipped.Value = true
			info.CurrentWeapon.Value = info.SecondaryWeapon.Value
			hum:UnequipTools()
			hum:EquipTool(player.Backpack:FindFirstChild(info.CurrentWeapon.Value))
			info.Which.Value = which
		--[[	
		elseif which == "third" then
			info.WeaponEquipped.Value = true
			info.CurrentWeapon.Value = info.Third.Value
			humanoid:UnequipTools()
			humanoid:EquipTool(player.Backpack:FindFirstChild(info.CurrentWeapon.Value))
			info.Which.Value = which
		]]
		elseif which == "saber" and info.Which.Value == "" then
			if info.SaberStyle.Value == "" then warn("Saberstyle is empty") return end
			info.WeaponEquipped.Value = true
			info.CurrentWeapon.Value = info.SaberStyle.Value
			hum:UnequipTools()
			hum:EquipTool(player.Backpack:FindFirstChild(info.CurrentWeapon.Value))
			info.Which.Value = which

			FSCD = true
			task.delay(0.1,function()
				FSCD = nil
			end)
		end
	end
end

module.Carry = function(arg) -- {}
	--warn("attempting carry: CarryCD", CarryCD)
	
	if CarryCD == true then return end
	if checkIfStunned() then
		return
	end
	local hitted
	local target
	for i, v in pairs(workspace.LivingThings:GetChildren()) do
		--checks if not noexe and has ragdoll
		if v and v ~= character and v:findFirstChild('HumanoidRootPart') and v:findFirstChild('Humanoid') and v.Humanoid.Health > 0 and not v.Effects:findFirstChild('Carried') and not v:GetAttribute("GettingGripped") and not v.Effects:findFirstChild('NoExecute') and v.Effects:findFirstChild('Ragdolled') and not v.Effects:FindFirstChild("CombatDisable") then
			warn(v)
			local calculations = (v.HumanoidRootPart.Position - character.HumanoidRootPart.Position).magnitude
			if calculations <= 8 then
				hitted = true
				target = v
				break
			end
		end
	end
	CarryCD = true
	--if (target) then
	--	warn("getting to canDrop", CanDrop, target, target.Effects:findFirstChild('Ragdolled'), target.Effects:FindFirstChild("CombatDisable"), target.Effects:FindFirstChild("Carried"), hitted)
	--end
	
	if (not CanDrop) and (target) and (target.Effects:findFirstChild('Ragdolled')) and (hitted) and (not target.Effects:FindFirstChild("CombatDisable")) and (not target.Effects:FindFirstChild("Carried")) then
		CanDrop = true
		last_target = target
		last_target.Info.Pause.Value = true

		carryanim = hum:LoadAnimation(repAnimFolder.Carry)
		carryanim:Play()

		carriedanim = target.Humanoid:LoadAnimation(repAnimFolder.Carried)
		carriedanim:Play()

		local seat = Instance.new('Seat')
		seat.CFrame = character.Torso.CFrame
		seat.Anchored = false
		seat.CanCollide = false
		seat.Transparency = 1
		seat.Massless = true
		seat.Parent = character
		table.insert(CarryTags,seat)

		local weld = Instance.new('Weld')
		weld.Name = 'weld'
		weld.Part0 = seat
		weld.Part1 = character.Torso
		weld.C1 = CFrame.new(0, -2, 1)
		table.insert(CarryTags, weld)

		target.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)

		target.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		seat:Sit(target.Humanoid)

		--character:SetAttribute("InCombat", true)
		--target:SetAttribute("InCombat", true)

		local t = Instance.new('BoolValue')
		t.Name = 'Carried'
		t.Parent = target.Effects
		table.insert(CarryTags,t)

		game.ReplicatedStorage.Remotes.updateTag:Fire(root, character)
		game.ReplicatedStorage.Remotes.updateTag:Fire(target.HumanoidRootPart, target)

		--[[
		local t = Instance.new('BoolValue')
		t.Name = 'InCombat'
		t.Parent = target.Effects
		table.insert(CarryTags,t)
		
		local t = Instance.new('BoolValue')
		t.Name = 'InCombat'
		t.Parent = effects
		table.insert(CarryTags,t)
		]]

		local t = Instance.new("BoolValue")
		t.Name = "NoJump"
		t.Parent = target.Effects
		table.insert(CarryTags,t)


		local t = Instance.new("ObjectValue")
		t.Name = "IsCarrying"
		t.Value = target
		t.Parent = effects
		table.insert(CarryTags,t)

		weld.Parent = seat

		for i,v in pairs(target:GetChildren()) do
			if v.ClassName == 'MeshPart' or v.ClassName == 'Part' then
				if v.Massless == false then
					table.insert(CarryMassless,v)
					v.Massless = true
				end
			end
		end

		connectio = player.CharacterRemoving:Connect(function(char)
			for i,v in pairs(CarryTags) do
				v:Destroy()
			end

			last_target.Humanoid.Sit = false
			last_target.Info.Pause.Value = false

			if carryanim then
				carryanim:Stop()
				carryanim:Destroy()
			end

			if carriedanim then
				carriedanim:Stop()
				carriedanim:Destroy()
			end

			if last_target and not last_target.Effects:FindFirstChild('Ragdolled') then
				last_target.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

			if connectio then
				connectio:Disconnect()
				connectio = nil
			end
		end)

		sub(function()
			while (CanDrop == true) and task.wait(.5) do
				if not target or target.Humanoid.Health < 1 then
					CanDrop = false

					for i,v in pairs(CarryTags) do
						v:Destroy()
					end
					last_target.Humanoid.Sit = false
					last_target.Info.Pause.Value = false

					if carryanim then
						carryanim:Stop()
						carryanim:Destroy()
					end

					if carriedanim then
						carriedanim:Stop()
						carriedanim:Destroy()
					end

					if connectio then
						connectio:Disconnect()
						connectio = nil
					end

					if last_target and not last_target.Effects:FindFirstChild('Ragdolled') then
						last_target.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					last_target = nil
				end

				if not target.Effects:FindFirstChild("Carried") or effects:findFirstChild('Stunned') or effects:findFirstChild('Ragdolled') or seat.Occupant == nil then
					for i,v in pairs(CarryMassless) do
						v.Massless = false
					end

					CanDrop = false

					if carryanim then
						carryanim:Stop()
						carryanim:Destroy()
					end

					if connectio then
						connectio:Disconnect()
						connectio = nil
					end

					if carriedanim then
						carriedanim:Stop()
						carriedanim:Destroy()
					end

					for i,v in pairs(CarryTags) do
						v:Destroy()
					end


					last_target.Humanoid.Sit = false
					last_target.Info.Pause.Value = false

					if not last_target.Effects:FindFirstChild('Ragdolled') then
						last_target.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end

					last_target = nil
					break
				end
			end
		end)
	elseif CanDrop == true and last_target then
		warn('344')
		for i,v in pairs(CarryTags) do
			v:Destroy()
		end

		if connectio then
			connectio:Disconnect()
			connectio = nil
		end


		last_target.Humanoid.Sit = false
		last_target.Info.Pause.Value = false

		if carryanim then
			carryanim:Stop()
			carryanim:Destroy()
		end

		if carriedanim then
			carriedanim:Stop()
			carriedanim:Destroy()
		end
	end
	task.wait(1) --.1
	CarryCD = false
end

module.Reset = function(arg) -- {}
	if character:GetAttribute("InCombat") or effects:FindFirstChild("InSpiritWorld") then
		return
	end

	hum:TakeDamage(9999999)
end

module.Run = function(arg) -- {type = type}
	info.Running.Value = arg.type
end

local dashcd = false
local rollTime = 0.4
local iframe = 0.5

module.Dash = function(arg) -- {key = key}
	if dashcd == true then
		return
	end
	if effects:FindFirstChild("Attacking") then return end
	if effects:FindFirstChild("CombatDisable") and not (effects:FindFirstChild("Attacking") or character:GetAttribute("Blocking")) then
		return
	end
	if effects:FindFirstChild("Stunned")  then
		return
	end
	
	local dashcdTime = 2.5
	if info.Which.Value == "saber" then
		dashcdTime = 1
	end

	cdRemote:FireClient(player, "Dash", dashcdTime)

	if arg.key == 'w' then
		rollTime = 0.625
	end

	character:SetAttribute("Rolling", true)
	delay(rollTime,function()
		character:SetAttribute("Rolling", false)
	end)

	dashcd = true
	delay(dashcdTime,function()
		dashcd = false
	end)

	if info.Which.Value ==  "saber" then
		root.ForceDash:Play()
		if (arg.key == 'a' or arg.key == 'd' or arg.key == 's') then
			if character:GetAttribute("PerfectDodgeCD") then return end
			character:SetAttribute("DodgeIFrame", true)
			delay(iframe, function()
				character:SetAttribute("DodgeIFrame", false)
			end)
		end
	else
		root.Dash:Play()
	end
end

module.Slide = function(arg) --{on = ???}
	if arg.on then
		info.Sliding.Value = true
	elseif not arg.on then
		info.Sliding.Value = false
	end
end
------------------------------------------------
--LINDATROOPER
------------------------------------------------
--COMBAT
local meleeCD = false
local meleeCDTime = 6
module.Melee = function(arg) -- {}
	if info.CurrentWeapon.Value == "" or info.Which.Value == "saber" then return end
	if checkIfStunned() then return end
	if info.Sliding.Value == true then
		info.Sliding.Value = false
	end
	if meleeCD then return end

	local module = require(game.ServerScriptService.Modules.Melee[info.CurrentWeapon.Value])
	module(character)

	cdRemote:FireClient(player, "Melee", meleeCDTime)

	sub(function()
		meleeCD = true
		task.wait(meleeCDTime)
		meleeCD = false
	end)
end

local grenadeCDTime = 15
local grenadeCD = false
module.Grenade = function(arg) --{t = t, lastHit = lastHit, type = type}
	if character:GetAttribute("GrenadeCD") then return end

	cdRemote:FireClient(player, arg.type, grenadeCDTime)

	character:SetAttribute("GrenadeCD", true)
	delay(grenadeCDTime, function()
		character:SetAttribute("GrenadeCD", false)
	end)

	local g = Vector3.new(0, -game.Workspace.Gravity, 0);
	local x0 = root.CFrame * Vector3.new(0, 2, -2)
	local v0 = (arg.lastHit - x0 - 0.5*g*arg.t*arg.t)/arg.t / 1.5;

	if arg.type == "grenade" then
		local module = require(game.ServerScriptService.Modules.Throwables["Thermal Imploder"])
		module(character, g, x0, v0)
	elseif arg.type == "stun" then
		local module = require(game.ServerScriptService.Modules.Throwables["Stun Grenade"])
		module(character, g, x0, v0)
	end
end

--ACCESSORIES
local transparent = {}
local helmState = true
local helmetDebounce = false
module.Helmet = function(arg) -- {}
	if helmetDebounce then return end
	if character:GetAttribute("RangeFinderOn") then return end

	cdRemote:FireClient(player, "Helmet", 2)
	helmetDebounce = true
	delay(2, function()
		helmetDebounce = false
	end)

	local armor = character.Armor
	local helm = armor:FindFirstChild("Helmet")
	if not helm then return end

	if helmState then
		helmState = false
		helmetOff:Play()
		sub(function()
			task.wait(0.2)
			character.Head.Transparency = 0
			for i,v in pairs(character:GetChildren()) do
				if v:IsA("Accessory") then
					v.Handle.Transparency = 0
				end
			end
			task.wait(0.4)
			for _,v in pairs (helm:GetDescendants()) do
				if (v:IsA("BasePart") or v:IsA("Texture") or v:IsA("Decal")) and v.Transparency < 1 then
					table.insert(transparent, v)
					v:SetAttribute("OriginalTransparency", v.Transparency)
					v.Transparency = 1
				end
			end
		end)
	else
		helmState = true
		helmetOn:Play()
		sub(function()
			task.wait(0.2)
			for _,v in pairs (transparent) do
				v.Transparency = v:GetAttribute("OriginalTransparency")
			end
			table.clear(transparent)
			task.wait(0.5)
			if armor:FindFirstChild("Invis") then
				character.Head.Transparency = 1
			else
				character.Head.Transparency = 0
			end
			for i,v in pairs(character:GetChildren()) do
				if v:IsA("Accessory") then
					v.Handle.Transparency = 1
				end
			end
		end)
	end
end

local pingTime = 5
local on = false
module.rangeFinder = function(arg) -- {state = state}
	if not character.Armor:FindFirstChild("Helmet") then return end
	if not arg.state then return end 
	local helm = character.Armor.Helmet
	if not helm then return end
	if not helm:FindFirstChild("Manipulate") then return end
	if arg.state == "equip" then
		if not character:GetAttribute("RangeFinderOn") then 
			character:SetAttribute("RangeFinderOn", true)
			TS:Create(helm.Manipulate, TweenInfo.new(1), {C0 = helm.Manipulate.C1 * CFrame.Angles(math.rad(-90),0,0)}):Play()
		else
			character:SetAttribute("RangeFinderOn", false)
			TS:Create(helm.Manipulate, TweenInfo.new(1), {C0 = helm.Manipulate.C1}):Play()
		end
	else
		if character:GetAttribute("RangeFinderOn") then
			local target = character.GetTarget:InvokeClient(player, true, 0.1)
			if not target then return end
			if target.Info:FindFirstChild("Marked") then return end

			local x = Instance.new("Folder")
			x.Name = "Marked"
			x.Parent = target.Info
			_G.DS:AddItem(x, 10)
			
			_G.DoEffect:FireAllClients("PingPlr", {team = character.Team.Value, target = target})
		end
	end
end
------------------------------------------------
--LINDAMELEE + SABER
------------------------------------------------
local parryCDTime = 1
local parryTime = 0.6
module.Block = function(arg) -- {}
	if info.Which.Value ~= "saber" and info.CurrentWeapon.Value == "" then return end
	
	if checkIfStunned() then
		return
	end
	if effects:findFirstChild('Ragdolled') or effects:FindFirstChild("Attacking") or effects:FindFirstChild("IFrame") or effects:FindFirstChild("Carried")or effects:FindFirstChild("NoBlock") or effects:FindFirstChild("BlockBroken") then
		return
	end
	
	local blockanim = preloaded[info.CurrentWeapon.Value .. "Block"]
	blockanim:Play()	
	
	if character:GetAttribute("ParryCD") then
				
		local Tags = {}

		character:SetAttribute("Blocking", true)
		character:SetAttribute("FKeydown", true)

		if info.WeaponEquipped:GetAttribute("SharpBlock") then
			local t = Instance.new("BoolValue")
			t.Name = "Sharp"
			t.Parent = effects
			table.insert(Tags,t)
		end

		local t = Instance.new("BoolValue")
		t.Name = "CombatDisable"
		t.Parent = effects
		table.insert(Tags,t)
		local t = Instance.new("BoolValue")
		t.Name = "NoJump"
		t.Parent = effects
		table.insert(Tags,t)

		hum.WalkSpeed = 8
		repeat
			task.wait()
			if effects:FindFirstChild("Stunned") then
				break
			end
			hum.WalkSpeed = 8
		until not character:GetAttribute("Blocking")
		character:SetAttribute("Blocking", false)

		if not effects:FindFirstChild("Stunned") then
			hum.WalkSpeed = character.MainValues.BaseSpeed.Value
		end

		blockanim:Stop()

		for i,v in pairs(Tags) do
			v:Destroy()
		end
		Tags = nil
		
	else
		hum.WalkSpeed = 8
		
		character:SetAttribute("FKeydown", true) -- Add keydown

		cdRemote:FireClient(player, "Parry", parryCDTime)

		character:SetAttribute("Parry", true)
		task.delay(parryTime, function()
			character:SetAttribute("Parry", false)
			if not effects:FindFirstChild("Stunned") then
				hum.WalkSpeed = character.MainValues.BaseSpeed.Value
			end
		end)
		
		character:SetAttribute("ParryCD", true)
		delay(parryCDTime,function()
			character:SetAttribute("ParryCD", false)
		end)
		
		--[[
		This makes the white flash
		
		_G.DoEffect:FireClient(player, "ParryCam", {})
		]]
		task.delay(parryTime, function()
			if character:GetAttribute("FKeydown") then
				module.Block(arg)
			else
				blockanim:Stop()
			end
		end)
	end
	
end

module.Unblock = function(arg) -- {}
	character:SetAttribute("Blocking", false)
	character:SetAttribute("FKeydown", false)
end

module.clashText = function(arg) -- {check = check}
	if not player.PlayerGui.HealthUI:FindFirstChild("Key") then return end
	local server_key = player.PlayerGui.HealthUI.Key.Text
	if arg.check == Enum.KeyCode[server_key] then
		if info.Clash.Value < 9 then
			info.Clash.Value += 1
		end
	else
		info.Clash.Value -= 1
	end

	local keys = {"Q", "W", "E", "A", "S", "D"}
	table.remove(keys, table.find(keys, server_key))
	player.PlayerGui.HealthUI.Key.TextColor3 = Color3.fromRGB(255,255,255)
	player.PlayerGui.HealthUI.Key.Text = keys[math.random(1,#keys)]
end

local m1cd = nil
module.M1 = function(arg) -- {}
	if info.Which.Value ~= "saber" then return end
	if info.CurrentWeapon.Value == "" then return end
	if effects:FindFirstChild("CombatDisable") then
		return
	end

	if character:GetAttribute("Rolling") then
		return
	end
	
	if m1cd then
		return
	end
	if checkIfStunned() then
		return
	end
	if info.Sliding.Value == true then
		print("Player is sliding")
		info.Sliding.Value = false
	end

	m1cd = true
	sub(function()
		if info.CurrentWeapon.Value ~= "" and info.Which.Value == "saber" then
			local module = require(game.ServerScriptService.Modules.Combat.M1:FindFirstChild(info.CurrentWeapon.Value))
			module(character)
		end
	end)
	task.wait(info.SwingSpeed.Value) 
	m1cd = nil
end

local heavyCDTime = 5
local heavyCD = false
module.Heavy = function(arg) -- {}
	if info.Which.Value ~= "saber" and info.CurrentWeapon.Value == "" then return end
	if checkIfStunned() then return end
	
	if character:GetAttribute("Rolling") then
		return
	end
	
	if info.Sliding.Value == true then
		info.Sliding.Value = false
	end
	
	if heavyCD == false then
		heavyCD = true
		
		local module = require(game.ServerScriptService.Modules.Combat.M2[info.CurrentWeapon.Value])
		module(character)
		cdRemote:FireClient(player, "Saber Heavy", heavyCDTime)
		
		task.wait(heavyCDTime)
		heavyCD = false
	end
end

local throwCDTime = 8
local ForceAmount = 20
local throwCD
module.saberThrow = function(arg) -- {}
	if info.Which.Value ~= "saber" and info.CurrentWeapon.Value == "" then return end
	if checkIfStunned() then return end
	
	if character:GetAttribute("Rolling") then
		return
	end
	
	if character.MainValues.Force.Value < ForceAmount then print("Not enough force") return end
		
	if info.Sliding.Value == true then
		info.Sliding.Value = false
	end	
	
	if throwCD then return end
	throwCD = true
	
	character.MainValues.Force.Value -= ForceAmount

	local module = require(game.ServerScriptService.Modules.Combat.M2["SaberThrow"])
	module(character)
	cdRemote:FireClient(player, "Saber Throw", throwCDTime)

	task.wait(throwCDTime)
	throwCD = false
end

local forceCDTime = 15
local MoveForceAmount = 30
local forceCD
module.forceMove = function(arg) -- {}
	if info.Which.Value ~= "saber" and info.CurrentWeapon.Value == "" then return end
	if checkIfStunned() then return end
	
	if character:GetAttribute("Rolling") then
		return
	end
	
	if character.MainValues.Force.Value < MoveForceAmount then return end
	
	if info.Sliding.Value == true then
		info.Sliding.Value = false
	end
	if forceCD then return end
	forceCD = true
	
	character.MainValues.Force.Value -= MoveForceAmount

	local module = require(game.ServerScriptService.Modules.Combat.Force["Force Choke"])
	module(character)
	cdRemote:FireClient(player, "Force Choke", forceCDTime)

	task.wait(forceCDTime)
	forceCD = false
end

-- VAULT
local MaxSize = 5
local Folder = game.Workspace:WaitForChild("VaultParts")

local AnimId = "rbxassetid://16808302008"

module.Vault = function(arg) -- {}
	-- raycast from character
	-- if we find a part, shorter than max then we vualt
	
	local Params = RaycastParams.new()
	
	Params.FilterDescendantsInstances = {Folder}
	Params.FilterType = Enum.RaycastFilterType.Include
	
	local ray = workspace:Raycast(character.HumanoidRootPart.CFrame.Position, character.HumanoidRootPart.CFrame.LookVector * 6, Params) -- create our rays
	
	if ray then -- if the ray hit anything
		if ray.Instance.Size.Y <= MaxSize then
			warn("Vaulting")
			
			-- Creating animation
			local Anim = Instance.new("Animation", character)
			Anim.Name = "VaultAnimation"
			Anim.AnimationId = AnimId
			
			local Track = hum:LoadAnimation(Anim)
			Track:Play()
						
			-- Velocity stuff
			local Vel = Instance.new("LinearVelocity", character.HumanoidRootPart)
			Vel.Attachment0 = character.HumanoidRootPart.RootAttachment
			Vel.RelativeTo = Enum.ActuatorRelativeTo.World
			Vel.Name = "VaultVelocity"
			Vel.MaxForce = 10000
			Vel.VectorVelocity = character.HumanoidRootPart.CFrame.LookVector * 25 + character.HumanoidRootPart.CFrame.UpVector * 5
			
			game.Debris:AddItem(Vel, .2)
		else
			warn("Cant vault over part, too tall")
		end
	end
end

--LAZY GRIP
--[[
local gripCD = false
local gripTime = 2
Remotes.Grip.OnServerEvent:Connect(function()
	if info.Which.Value ~= "saber" and info.CurrentWeapon.Value == "" then return end
	if character:GetAttribute("Gripping") then
		warn("add stunned")
		local t = Instance.new("BoolValue")
		t.Name = "Stunned"
		t.Parent = effects
		_G.DS:AddItem(t, 0.2)
		task.wait(0.2)
		gripCD = false
		return
	end
	if gripCD then return end

	local GripTags = {}

	local function exit(char, target)
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.Anchored = false
			char:SetAttribute("Gripping", false)
		end
		if target and target:FindFirstChild("HumanoidRootPart") then
			target.HumanoidRootPart.Anchored = false
			target:SetAttribute("GettingGripped", false)
			task.delay(2, function()
				if target.Humanoid.Health == 0 then
					for _, part in pairs(target:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CollisionGroup = "Players"
						end
					end
				end
			end)
		end
		gripCD = false
		for _,v in pairs(GripTags) do
			v:Destroy()
		end
		GripTags = nil
	end

	local target
	local ehum
	local eroot
	for _, echar in pairs(workspace.LivingThings:GetChildren()) do
		if echar and echar ~= character and echar:FindFirstChild("Humanoid") and echar:FindFirstChild("Effects") then
			if not echar:GetAttribute("GettingGripped") and not echar.Effects:FindFirstChild("Carried") and not echar.Effects:FindFirstChild("NoExecute") and echar.Humanoid.Health > 0 and echar.Effects:FindFirstChild("Ragdolled") then
				local distance = (echar.HumanoidRootPart.Position - root.Position).magnitude
				if distance < 10 then
					target = echar
					ehum = echar.Humanoid
					eroot = echar.HumanoidRootPart
				end
			end
		end
	end

	if target then
		local onSurface, _ = _G.mm.Raycast(root.Position, root.CFrame.UpVector, -4, {target, character})
		if onSurface then
			for _, part in pairs(target:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CollisionGroup = "Ragdoll"
				end
			end
			gripCD = true
			target:SetAttribute("GettingGripped", true)
			character:SetAttribute("Gripping", true)

			local t = Instance.new("BoolValue")
			t.Name = "CombatDisable"
			t.Parent = effects
			table.insert(GripTags, t)

			local t = Instance.new("BoolValue")
			t.Name = "AntiRotate"
			t.Parent = effects
			table.insert(GripTags, t)

			local t = Instance.new("BoolValue")
			t.Name = "AntiRotate"
			t.Parent = target.Effects
			table.insert(GripTags, t)

			root.Anchored = true
			eroot.Anchored = true

			local newCFrame = root.CFrame * CFrame.new(0,0,0.0001)

			root.CFrame = newCFrame
			eroot.CFrame = root.CFrame * CFrame.new(0,0,0.0001)

			--* CFrame.Angles(0, math.rad(0), 0)
			local weld = _G.mm.inPlaceWeld(root, eroot, root)
			table.insert(GripTags, weld)

			local animFolder = game.ServerStorage.PreloadAnimations.notPreloaded[info.CurrentWeapon.Value]

			local gettingGrippedAnim = ehum:LoadAnimation(animFolder["gettingGripped"])
			local grippingAnim = humanoid:LoadAnimation(animFolder["gripping"])

			gettingGrippedAnim:Play()
			grippingAnim:Play()

			--GRIPPING LOGIC
			local canGrip = true

			--GRIP FINISHING
			task.delay(gripTime, function()
				if canGrip then
					character:SetAttribute("Gripping", false)

					ehum:TakeDamage(math.huge)
					warn("FINISHED")

				end
			end)

			--GRIP FX
			sub(function()
				task.wait(1.1) -- yea i have to hardcode this.
				if not canGrip then return end
				eroot.gripSlam:Play()
				goreModule.Bleed(character, eroot, eroot.CFrame.UpVector * 25, 55, 100, 3, eroot.CFrame * CFrame.new(0,0,-7))
				task.wait(0.3)
				if not canGrip then return end
				eroot.gripSlam:Play()
				goreModule.Bleed(character, eroot, eroot.CFrame.UpVector * 25, 55, 100, 3, eroot.CFrame * CFrame.new(0,0,-7))
				--anything works
			end)

			--WAIT UNTIL GRIP FINISHES OR GETS CANCELLED
			while character and target and character:GetAttribute("Gripping") do
				if effects:FindFirstChild("Stunned") or target.Effects:FindFirstChild("GetUpTag") then
					canGrip = false
					break
				end
				task.wait()
			end

			gettingGrippedAnim:Stop()
			grippingAnim:Stop()
			exit(character, target)
		end
	end
end)

]]

-- kill character
module.Kill = function(arg)
	character.Humanoid.Health = 0
end


return module