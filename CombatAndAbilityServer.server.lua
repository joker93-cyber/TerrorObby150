-- CombatAndAbilityServer.server.lua
-- Ubicación: ServerScriptService.CombatAndAbilityServer
-- Equipa una Espada de Energía al jugador, genera Ondas de Corte 3D, Números de Daño Flotantes,
-- Sonidos de Combate, brillo de impacto y efectos explosivos para todos los poderes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local AbilityConfig = require(ReplicatedStorage:WaitForChild("AbilityConfig"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local basicAttackEvent = getOrCreateRemote("BasicAttack")
local activateAbilityEvent = getOrCreateRemote("ActivateAbility")
local combatFeedbackEvent = getOrCreateRemote("CombatFeedback")
local clientNotificationEvent = getOrCreateRemote("ClientNotification")

local PlayerCooldowns = {}
local KillRewardHistory = {}

local function getCooldownTable(userId)
	if not PlayerCooldowns[userId] then
		PlayerCooldowns[userId] = {
			LastAttack = 0,
			Abilities = {}
		}
	end
	return PlayerCooldowns[userId]
end

local function play3DSound(parentPart, soundId, pitch, volume)
	if not parentPart then return end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.PlaybackSpeed = pitch or 1
	s.Volume = volume or 0.7
	s.RollOffMaxDistance = 80
	s.Parent = parentPart
	pcall(function()
		s:Play()
	end)
	Debris:AddItem(s, 2)
end

local function showFloatingDamage(position, damageAmount, isCrit)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position + Vector3.new(math.random(-15, 15) / 10, 2.5, math.random(-15, 15) / 10))
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Parent = Workspace
	Debris:AddItem(anchor, 0.85)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(110, 42)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.TextStrokeTransparency = 0.1
	txt.TextColor3 = isCrit and Color3.fromRGB(255, 215, 40) or Color3.fromRGB(255, 75, 75)
	txt.Text = "-" .. tostring(damageAmount) .. (isCrit and " ⚡" or " 💥")
	txt.Parent = bb
end

local function equipEnergyBlade(character)
	local hand = character:WaitForChild("RightHand", 3) or character:WaitForChild("Right Arm", 3)
	if not hand then return end

	local blade = Instance.new("Part")
	blade.Name = "EquippedEnergyBlade"
	blade.Size = Vector3.new(0.25, 0.35, 4.2)
	blade.Color = Color3.fromRGB(255, 35, 55)
	blade.Material = Enum.Material.Neon
	blade.Anchored = false
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = hand.CFrame * CFrame.new(0, -1.0, -1.8)
	blade.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = blade
	weld.Parent = blade
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.spawn(equipEnergyBlade, char)
	end)
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		task.spawn(equipEnergyBlade, p.Character)
	end
end

local function isPlayerInSafeZone(player)
	if not player or not player.Character then return true end
	if player:GetAttribute("IsHiding") then return true end
	if os.clock() < (player:GetAttribute("SpawnProtectionUntil") or 0) then
		return true
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return true end
	local pos = hrp.Position

	if (pos - Vector3.new(0, 10, 0)).Magnitude <= AbilityConfig.Combat.HubSafeRadius then
		return true
	end

	local checkpointsFolder = Workspace:FindFirstChild("Checkpoints")
	if checkpointsFolder then
		for _, cp in ipairs(checkpointsFolder:GetChildren()) do
			if cp:IsA("BasePart") and (pos - cp.Position).Magnitude <= AbilityConfig.Combat.CheckpointSafeRadius then
				return true
			end
		end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.4)
		for _, player in ipairs(Players:GetPlayers()) do
			local safe = isPlayerInSafeZone(player)
			if player:GetAttribute("InSafeZone") ~= safe then
				player:SetAttribute("InSafeZone", safe)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerCooldowns[player.UserId] = nil
	KillRewardHistory[player.UserId] = nil
end)

local function damageMonster(attacker, monster, damageAmount, stunDuration, attackerPos)
	local mHum = monster:FindFirstChildOfClass("Humanoid")
	local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
	if not mHum or not mRoot or mHum.Health <= 0 then return false end

	mHum:TakeDamage(damageAmount)
	if stunDuration and stunDuration > 0 then
		monster:SetAttribute("StunnedUntil", os.clock() + stunDuration)
	end

	if attackerPos then
		local pushDir = (mRoot.Position - attackerPos)
		if pushDir.Magnitude > 0.1 then
			mRoot.AssemblyLinearVelocity = pushDir.Unit * 32 + Vector3.new(0, 12, 0)
		end
	end

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineColor = Color3.fromRGB(255, 40, 40)
	hl.FillTransparency = 0.25
	hl.Parent = monster
	Debris:AddItem(hl, 0.18)

	showFloatingDamage(mRoot.Position, damageAmount, damageAmount >= 32)
	play3DSound(mRoot, "rbxassetid://12222208", 0.95, 0.85)
	combatFeedbackEvent:FireClient(attacker, "HitMonster", mRoot.Position)

	if mHum.Health <= 0 and not monster:GetAttribute("RewardGranted") then
		monster:SetAttribute("RewardGranted", true)
		local isBoss = monster:GetAttribute("IsBoss")
		local coinReward = isBoss and 100 or 25
		if _G.TerrorObbyAddCoins then
			_G.TerrorObbyAddCoins(attacker, coinReward)
		end

		local burst = Instance.new("Part")
		burst.Shape = Enum.PartType.Ball
		burst.Size = Vector3.new(12, 12, 12)
		burst.CFrame = mRoot.CFrame
		burst.Color = Color3.fromRGB(255, 70, 30)
		burst.Material = Enum.Material.Neon
		burst.Transparency = 0.3
		burst.Anchored = true
		burst.CanCollide = false
		burst.Parent = Workspace
		Debris:AddItem(burst, 0.35)

		clientNotificationEvent:FireClient(
			attacker,
			(isBoss and "💀 ¡JEFE DERROTADO: " or "⚔️ ¡Eliminaste a ") .. monster.Name .. "! (+" .. coinReward .. " Monedas)"
		)
		task.delay(0.35, function()
			if monster and monster.Parent then
				monster:Destroy()
			end
		end)
	end
	return true
end

basicAttackEvent.OnServerEvent:Connect(function(attacker)
	local cd = getCooldownTable(attacker.UserId)
	local now = os.clock()
	if now - cd.LastAttack < 0.45 then
		return
	end
	cd.LastAttack = now

	local char = attacker.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	if attacker:GetAttribute("IsHiding") then return end

	if attacker:GetAttribute("IsInvisible") then
		attacker:SetAttribute("IsInvisible", false)
	end

	local monstersFolder = Workspace:FindFirstChild("Monsters")
	local closestMonster = nil
	local closestDist = 14
	if monstersFolder then
		for _, m in ipairs(monstersFolder:GetChildren()) do
			local mHum = m:FindFirstChildOfClass("Humanoid")
			local mRoot = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
			if mHum and mRoot and mHum.Health > 0 then
				local d = (mRoot.Position - hrp.Position).Magnitude
				if d < closestDist then
					closestDist = d
					closestMonster = m
				end
			end
		end
	end

	if closestMonster and closestMonster.PrimaryPart then
		local mPos = closestMonster.PrimaryPart.Position
		hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(mPos.X, hrp.Position.Y, mPos.Z))
	end

	play3DSound(hrp, "rbxassetid://12222216", 1.05, 0.75)

	local slashWave = Instance.new("Part")
	slashWave.Name = "SlashCrescent"
	slashWave.Size = Vector3.new(9, 0.45, 5.5)
	slashWave.CFrame = hrp.CFrame * CFrame.new(0, 0.4, -4.2) * CFrame.Angles(0, 0, math.rad(-18))
	slashWave.Color = attacker:GetAttribute("HasVIP") and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(255, 40, 65)
	slashWave.Material = Enum.Material.Neon
	slashWave.Transparency = 0.2
	slashWave.Anchored = true
	slashWave.CanCollide = false
	slashWave.Parent = Workspace
	Debris:AddItem(slashWave, 0.2)

	local baseDamage = attacker:GetAttribute("HasVIP") and 35 or 28
	local lookVec = hrp.CFrame.LookVector

	if monstersFolder then
		for _, monster in ipairs(monstersFolder:GetChildren()) do
			local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
			if mRoot then
				local offset = mRoot.Position - hrp.Position
				local dist = offset.Magnitude
				if dist <= 9.5 or (dist <= 14.5 and lookVec:Dot(offset.Unit) > -0.2) then
					damageMonster(attacker, monster, baseDamage, 0.75, hrp.Position)
				end
			end
		end
	end

	if isPlayerInSafeZone(attacker) then
		return
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= attacker and targetPlayer.Character and not isPlayerInSafeZone(targetPlayer) then
			local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			local tHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and tHum and tHum.Health > 0 then
				local offset = tRoot.Position - hrp.Position
				if offset.Magnitude <= 11 then
					local finalDamage = baseDamage
					local hasActiveShield = (targetPlayer:GetAttribute("ActiveShieldUntil") or 0) > now
					if hasActiveShield then
						finalDamage = math.floor(baseDamage * 0.25)
					end

					tHum:TakeDamage(finalDamage)
					showFloatingDamage(tRoot.Position, finalDamage, false)
					combatFeedbackEvent:FireClient(attacker, "HitPlayer", tRoot.Position)

					if not hasActiveShield then
						tRoot.AssemblyLinearVelocity = (offset.Unit + Vector3.new(0, 0.35, 0)).Unit * 32
					end

					if tHum.Health <= 0 then
						KillRewardHistory[attacker.UserId] = KillRewardHistory[attacker.UserId] or {}
						local lastReward = KillRewardHistory[attacker.UserId][targetPlayer.UserId] or 0
						if now - lastReward >= AbilityConfig.Combat.SameVictimRewardCooldown then
							KillRewardHistory[attacker.UserId][targetPlayer.UserId] = now
							if _G.TerrorObbyAddCoins then
								_G.TerrorObbyAddCoins(attacker, AbilityConfig.Combat.KillCoinReward)
							end
							clientNotificationEvent:FireClient(attacker, "⚔️ Derrotaste a " .. targetPlayer.Name .. " (+15 Monedas)")
						end
					end
					break
				end
			end
		end
	end
end)

activateAbilityEvent.OnServerEvent:Connect(function(player, abilityId)
	if type(abilityId) ~= "string" then return end
	local cfg = AbilityConfig.Abilities[abilityId]
	if not cfg then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	if player:GetAttribute("IsHiding") then return end

	local cd = getCooldownTable(player.UserId)
	local now = os.clock()
	if now < (cd.Abilities[abilityId] or 0) then
		return
	end

	cd.Abilities[abilityId] = now + cfg.Cooldown
	combatFeedbackEvent:FireClient(player, "AbilityAccepted", abilityId, cfg.Cooldown)

	if abilityId == "Dash" then
		play3DSound(hrp, "rbxassetid://12222200", 1.3, 0.8)
		local look = hrp.CFrame.LookVector
		local flatDir = Vector3.new(look.X, 0.18, look.Z).Unit
		hrp.AssemblyLinearVelocity = flatDir * 78

		local trailPart = Instance.new("Part")
		trailPart.Size = Vector3.new(4, 4, 14)
		trailPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
		trailPart.Color = Color3.fromRGB(80, 220, 255)
		trailPart.Material = Enum.Material.Neon
		trailPart.Transparency = 0.35
		trailPart.Anchored = true
		trailPart.CanCollide = false
		trailPart.Parent = Workspace
		Debris:AddItem(trailPart, 0.28)

		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if monstersFolder then
			for _, m in ipairs(monstersFolder:GetChildren()) do
				local mRoot = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
				if mRoot and (mRoot.Position - hrp.Position).Magnitude <= 12 then
					damageMonster(player, m, 22, 1.5, hrp.Position)
				end
			end
		end

	elseif abilityId == "Shield" then
		play3DSound(hrp, "rbxassetid://12222242", 1.0, 0.8)
		player:SetAttribute("ActiveShieldUntil", now + cfg.Duration)
		hum.Health = math.min(hum.MaxHealth, hum.Health + 25)

		local shieldSphere = Instance.new("Part")
		shieldSphere.Shape = Enum.PartType.Ball
		shieldSphere.Size = Vector3.new(7.5, 7.5, 7.5)
		shieldSphere.CFrame = hrp.CFrame
		shieldSphere.Color = Color3.fromRGB(60, 255, 140)
		shieldSphere.Material = Enum.Material.ForceField
		shieldSphere.Transparency = 0.25
		shieldSphere.Anchored = false
		shieldSphere.CanCollide = false
		shieldSphere.Massless = true
		shieldSphere.Parent = char
		local w = Instance.new("WeldConstraint")
		w.Part0 = hrp
		w.Part1 = shieldSphere
		w.Parent = shieldSphere
		Debris:AddItem(shieldSphere, cfg.Duration)

	elseif abilityId == "EnergyPulse" then
		play3DSound(hrp, "rbxassetid://12222084", 0.9, 0.9)
		local wave = Instance.new("Part")
		wave.Name = "EnergyPulseWave"
		wave.Shape = Enum.PartType.Ball
		wave.Size = Vector3.new(34, 34, 34)
		wave.CFrame = hrp.CFrame
		wave.Color = Color3.fromRGB(65, 195, 255)
		wave.Material = Enum.Material.Neon
		wave.Transparency = 0.35
		wave.Anchored = true
		wave.CanCollide = false
		wave.Parent = Workspace
		Debris:AddItem(wave, 0.38)

		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if monstersFolder then
			for _, monster in ipairs(monstersFolder:GetChildren()) do
				local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
				if mRoot and (mRoot.Position - hrp.Position).Magnitude <= 22 then
					damageMonster(player, monster, 45, cfg.MonsterStunSeconds, hrp.Position)
				end
			end
		end

	elseif abilityId == "Invisibility" then
		play3DSound(hrp, "rbxassetid://12222200", 0.75, 0.8)
		player:SetAttribute("IsInvisible", true)
		hum.WalkSpeed = (player:GetAttribute("HasVIP") and 23 or 18) + 6

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0.75
			end
		end
		task.delay(cfg.Duration, function()
			if player and player.Parent then
				player:SetAttribute("IsInvisible", false)
			end
			if hum and hum.Parent then
				hum.WalkSpeed = player:GetAttribute("HasVIP") and 23 or 18
			end
			if char and char.Parent and not player:GetAttribute("IsHiding") then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 0
					end
				end
			end
		end)

	elseif abilityId == "Trap" then
		play3DSound(hrp, "rbxassetid://12222242", 1.2, 0.8)
		local trap = Instance.new("Part")
		trap.Name = "RuneTrap_" .. player.Name
		trap.Shape = Enum.PartType.Cylinder
		trap.Size = Vector3.new(0.4, 9, 9)
		trap.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trap.Color = Color3.fromRGB(205, 55, 255)
		trap.Material = Enum.Material.Neon
		trap.Transparency = 0.2
		trap.Anchored = true
		trap.CanCollide = false
		trap.Parent = Workspace
		Debris:AddItem(trap, cfg.Lifetime)

		local triggered = false
		trap.Touched:Connect(function(hit)
			if triggered then return end
			local model = hit.Parent
			if not model or model == char then return end

			if model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model) then
				triggered = true
				damageMonster(player, model, 55, cfg.MonsterStunSeconds, trap.Position)
				clientNotificationEvent:FireClient(player, "🕸️ ¡Trampa Rúnica detonada sobre la criatura!")
				trap:Destroy()
			end
		end)
	end
end)

print("[CombatAndAbilityServer] Katana de Energía, Combate de Hordas y Poderes listos.")
