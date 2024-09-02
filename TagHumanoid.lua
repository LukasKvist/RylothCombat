local CS = game:GetService("CollectionService")

local module = {}

function getPreloadedDict(givenChar)
	local dict
	
	if not game.Players:GetPlayerFromCharacter(givenChar) then
		dict = givenChar.grabDict:Invoke()
	else
		dict = _G.preloaded_dict[givenChar.Name]
	end
	
	return dict	
end

module.Parry = function(character, target, saberColor)
	local root = character.HumanoidRootPart
	local eroot = target.HumanoidRootPart
	
	_G.mm.clearConstraints("all", root, eroot)
	
	local character_preloaded_dict = getPreloadedDict(character)
	local target_preloaded_dict = getPreloadedDict(target)
	
	local charWeapon = character.MainValues.CurrentWeapon.Value
	local targetWeapon = target.MainValues.CurrentWeapon.Value
	
	--target is parrying
	--character is getting parried
	pcall(function()
		target_preloaded_dict[targetWeapon .. "Block"]:Stop()

		if character.Combo.Value ~= 0 then
			character_preloaded_dict[charWeapon .. "" .. character.Combo.Value]:Stop()
		end
		
		target_preloaded_dict[targetWeapon .. "ParrySuccess"]:Play(0)
		character_preloaded_dict[charWeapon .. "GettingParry"]:Play(0)
	end)
	
	local test = pcall(function()
		-- PARRY VFX
		print("Parry VFX!")
		target.MainValues.ToolObject.Value.ToolModel.Value.Blade.Spark.Color = ColorSequence.new(saberColor)
		target.MainValues.ToolObject.Value.ToolModel.Value.Blade.Spark:Emit(25)
		target.MainValues.ToolObject.Value.ToolModel.Value.Blade.Embers:Emit(250)
	end)
	
	_G.DoEffect:FireAllClients("ParryHighlight", {char = target, timeTo = 0.6})
	
	local Sound = Instance.new("Sound", eroot) -- THis is the sound that plays when a parry is hit
	Sound.SoundId = "rbxassetid://16669196659"
	Sound:Play()
	_G.DS:AddItem(Sound,1)
	-- Stun stuff
	
	-- Value that stuns the parried player, makes it so they cant keep m1ing directly after being parried.
	local t = Instance.new("BoolValue")
	t.Name = "Stunned"
	t.Parent= character.Effects
	_G.DS:AddItem(t,.4) -- the .4 part here is how long it lasts, for example if i were to put 2 instead itd last for 2 sec
	
	-- Disables the combat completely for the parried person
	local t = Instance.new("BoolValue")
	t.Name = "CombatDisable"
	t.Parent= character.Effects
	_G.DS:AddItem(t,.4) -- the .4 part here is how long it lasts, for example if i were to put 2 instead itd last for 2 sec
	
	-- Slows their walking speed down, ameks it so threy cnat use movement etc
	local t = Instance.new("NumberValue")
	t.Name = "Slow"
	t.Value = character.MainValues.BaseSpeed.Value/3.5 -- THis is how much it affects theyre walking speed
	t.Parent = character.Effects
	_G.DS:AddItem(t,.4) -- the .4 part here is how long it lasts, for example if i were to put 2 instead itd last for 2 sec
	
end

return module
