-- CombatAndAbilityServer.server.lua
-- Ubicación: ServerScriptService.CombatAndAbilityServer
-- Permite golpear y derrotar Monstruos y Jefes de Bioma además del combate PvP.

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

local function isPlayerInSafeZone(player)
	if not player or not player.Character then return true end
	if player:GetAttribute("IsHiding") then return true end

	local spawnProt = player:GetAttribute("SpawnProtectionUntil") or 0
	if os.clock() < spawnProt then
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

-- Daño a Monstruos y Jefes con recompensa de monedas y reaparición automática tras 25s
local function damageMonster(attacker, monster, damageAmount, stunDuration)
	local mHum = monster:FindFirstChildOfClass("Humanoid")
	local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
	if not mHum or not mRoot or mHum.Health <= 0 then return end

	mHum:TakeDamage(damageAmount)
	if stunDuration and stunDuration > 0 then
		monster:SetAttribute("StunnedUntil", os.clock() + stunDuration)
	end
	combatFeedbackEvent:FireClient(attacker, "HitMonster", mRoot.Position)

	if mHum.Health <= 0 and not monster:GetAttribute("RewardGranted") then
		monster:SetAttribute("RewardGranted", true)
		local isBoss = monster:GetAttribute("IsBoss")
		local coinReward = isBoss and 80 or 20
		if _G.TerrorObbyAddCoins then
			_G.TerrorObbyAddCoins(attacker, coinReward)
		end
		clientNotificationEvent:FireClient(
			attacker,
			(isBoss and "💀 ¡DERROTASTE AL JEFE " or "🗡️ ¡Abatiste a ") .. monster.Name .. "! (+" .. coinReward .. " Monedas)"
		)
		task.delay(2, function()
			if monster and monster.Parent then
				monster:Destroy()
			end
		end)
	end
end

basicAttackEvent.OnServerEvent:Connect(function(attacker)
	local cd = getCooldownTable(attacker.UserId)
	local now = os.clock()
	if now - cd.LastAttack < AbilityConfig.Combat.MeleeCooldown then
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

	local baseDamage = attacker:GetAttribute("HasVIP")
		and AbilityConfig.Combat.VIPMeleeDamage
		or AbilityConfig.Combat.MeleeDamage

	local maxRange = AbilityConfig.Combat.MeleeRange + 2
	local lookVec = hrp.CFrame.LookVector

	-- A) Atacar Monstruos y Jefes
	local monstersFolder = Workspace:FindFirstChild("Monsters")
	if monstersFolder then
		for _, monster in ipairs(monstersFolder:GetChildren()) do
			local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
			if mRoot then
				local offset = mRoot.Position - hrp.Position
				if offset.Magnitude <= maxRange and lookVec:Dot(offset.Unit) > 0.1 then
					damageMonster(attacker, monster, baseDamage, 1.2)
				end
			end
		end
	end

	-- B) Combate PvP (Fuera de Zonas Seguras)
	if isPlayerInSafeZone(attacker) then
		return
	end

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= attacker and targetPlayer.Character then
			if not isPlayerInSafeZone(targetPlayer) then
				local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				local tHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if tRoot and tHum and tHum.Health > 0 then
					local offset = tRoot.Position - hrp.Position
					if offset.Magnitude <= maxRange and lookVec:Dot(offset.Unit) > 0.15 then
						local finalDamage = baseDamage
						local hasActiveShield = (targetPlayer:GetAttribute("ActiveShieldUntil") or 0) > now
						if hasActiveShield then
							finalDamage = math.floor(baseDamage * (1 - AbilityConfig.Abilities.Shield.DamageReduction))
						end

						tHum:TakeDamage(finalDamage)
						combatFeedbackEvent:FireClient(attacker, "HitPlayer", tRoot.Position)

						if not hasActiveShield then
							local pushDir = (offset.Unit + Vector3.new(0, 0.35, 0)).Unit
							tRoot.AssemblyLinearVelocity = pushDir * AbilityConfig.Combat.KnockbackForce
						end

						if tHum.Health <= 0 then
							KillRewardHistory[attacker.UserId] = KillRewardHistory[attacker.UserId] or {}
							local lastReward = KillRewardHistory[attacker.UserId][targetPlayer.UserId] or 0
							if now - lastReward >= AbilityConfig.Combat.SameVictimRewardCooldown then
								KillRewardHistory[attacker.UserId][targetPlayer.UserId] = now
								if _G.TerrorObbyAddCoins then
									_G.TerrorObbyAddCoins(attacker, AbilityConfig.Combat.KillCoinReward)
								end
								clientNotificationEvent:FireClient(
									attacker,
									"⚔️ Derrotaste a " .. targetPlayer.Name .. " (+" .. AbilityConfig.Combat.KillCoinReward .. " Monedas)"
								)
							else
								clientNotificationEvent:FireClient(
									attacker,
									"⚔️ Derrotaste a " .. targetPlayer.Name .. " (Recompensa en enfriamiento)"
								)
							end
						end
						break
					end
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
	local readyAt = cd.Abilities[abilityId] or 0
	if now < readyAt then
		return
	end

	cd.Abilities[abilityId] = now + cfg.Cooldown
	combatFeedbackEvent:FireClient(player, "AbilityAccepted", abilityId, cfg.Cooldown)

	if abilityId == "Dash" then
		local look = hrp.CFrame.LookVector
		local flatDir = Vector3.new(look.X, 0.15, look.Z).Unit
		hrp.AssemblyLinearVelocity = flatDir * cfg.DashSpeed

	elseif abilityId == "Shield" then
		player:SetAttribute("ActiveShieldUntil", now + cfg.Duration)
		local ff = Instance.new("ForceField")
		ff.Name = "AbilityShieldVisual"
		ff.Visible = true
		ff.Parent = char
		Debris:AddItem(ff, cfg.Duration)

	elseif abilityId == "EnergyPulse" then
		local wave = Instance.new("Part")
		wave.Name = "EnergyPulseWave"
		wave.Shape = Enum.PartType.Ball
		wave.Size = Vector3.new(28, 28, 28)
		wave.CFrame = hrp.CFrame
		wave.Color = Color3.fromRGB(70, 180, 255)
		wave.Material = Enum.Material.Neon
		wave.Transparency = 0.55
		wave.Anchored = true
		wave.CanCollide = false
		wave.Parent = Workspace
		Debris:AddItem(wave, 0.35)

		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if monstersFolder then
			for _, monster in ipairs(monstersFolder:GetChildren()) do
				local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
				if mRoot and (mRoot.Position - hrp.Position).Magnitude <= cfg.Radius then
					damageMonster(player, monster, 35, cfg.MonsterStunSeconds)
				end
			end
		end

		if not isPlayerInSafeZone(player) then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player and other.Character and not isPlayerInSafeZone(other) then
					local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
					local oHum = other.Character:FindFirstChildOfClass("Humanoid")
					if oRoot and oHum and oHum.Health > 0 then
						local diff = oRoot.Position - hrp.Position
						if diff.Magnitude <= cfg.Radius then
							oHum:TakeDamage(cfg.PlayerDamage)
							oRoot.AssemblyLinearVelocity = (diff.Unit + Vector3.new(0, 0.4, 0)).Unit * cfg.PlayerKnockback
						end
					end
				end
			end
		end

	elseif abilityId == "Invisibility" then
		player:SetAttribute("IsInvisible", true)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0.75
			end
		end
		task.delay(cfg.Duration, function()
			if player and player.Parent then
				player:SetAttribute("IsInvisible", false)
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
		local trap = Instance.new("Part")
		trap.Name = "RuneTrap_" .. player.Name
		trap.Size = Vector3.new(6, 0.4, 6)
		trap.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.6, 0))
		trap.Color = Color3.fromRGB(190, 45, 255)
		trap.Material = Enum.Material.Neon
		trap.Transparency = 0.25
		trap.Anchored = true
		trap.CanCollide = false
		trap.Parent = Workspace
		Debris:AddItem(trap, cfg.Lifetime)

		local triggered = false
		trap.Touched:Connect(function(hit)
			if triggered then return end
			local model = hit.Parent
			if not model or model == char then return end

			local hitPlayer = Players:GetPlayerFromCharacter(model)
			if hitPlayer then
				if not isPlayerInSafeZone(hitPlayer) then
					local hHum = model:FindFirstChildOfClass("Humanoid")
					if hHum and hHum.Health > 0 then
						triggered = true
						local originalSpeed = hitPlayer:GetAttribute("HasVIP") and 22 or 16
						hHum.WalkSpeed = cfg.SlowedWalkSpeed
						clientNotificationEvent:FireClient(hitPlayer, "🕸️ ¡Caíste en una Trampa Rúnica! Velocidad reducida.")
						task.delay(cfg.PlayerSlowSeconds, function()
							if hHum and hHum.Parent then
								hHum.WalkSpeed = originalSpeed
							end
						end)
						trap:Destroy()
					end
				end
			elseif model:FindFirstChildOfClass("Humanoid") then
				triggered = true
				damageMonster(player, model, 25, cfg.MonsterStunSeconds)
				clientNotificationEvent:FireClient(player, "🕸️ ¡Tu Trampa Rúnica hirió y congeló a un monstruo!")
				trap:Destroy()
			end
		end)
	end
end)

print("[CombatAndAbilityServer] Combate contra Jefes, Monstruos y PvP activo.")
