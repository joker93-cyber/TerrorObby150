-- CombatAndAbilityServer.server.lua
-- Ubicación: ServerScriptService.CombatAndAbilityServer
-- Equipa una Katana Demoníaca esculpida con Trail, anima los brazos del jugador en Combo 1-2-3
-- y despliega efectos con TweenService y ParticleEmitter para todos los poderes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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
			ComboStep = 1,
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
	s.Volume = volume or 0.75
	s.RollOffMaxDistance = 85
	s.Parent = parentPart
	pcall(function()
		s:Play()
	end)
	Debris:AddItem(s, 2)
end

local function showFloatingDamage(position, damageAmount, isCrit)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position + Vector3.new(math.random(-12, 12) / 10, 2.2, math.random(-12, 12) / 10))
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 28)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.TextStrokeTransparency = 0.1
	txt.TextColor3 = isCrit and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(255, 70, 70)
	txt.Text = "-" .. tostring(damageAmount)
	txt.Parent = bb

	TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = anchor.CFrame * CFrame.new(0, 3.5, 0)
	}):Play()
	Debris:AddItem(anchor, 0.7)
end

-- ============================================================================
-- KATANA DEMONÍACA ESCULPIDA CON GUARDA, FILO BRILLANTE Y TRAIL EN EL AIRE
-- ============================================================================
local function equipKatanaModel(character)
	local hand = character:WaitForChild("RightHand", 4) or character:WaitForChild("Right Arm", 4)
	if not hand then return end

	local oldKatana = character:FindFirstChild("DemonKatana")
	if oldKatana then oldKatana:Destroy() end

	local katana = Instance.new("Model")
	katana.Name = "DemonKatana"

	-- Empuñadura (Tsuka)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.22, 0.28, 1.3)
	handle.Color = Color3.fromRGB(25, 20, 28)
	handle.Material = Enum.Material.Fabric
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = hand.CFrame * CFrame.new(0, -0.9, -0.3)
	handle.Parent = katana

	local gripWeld = Instance.new("WeldConstraint")
	gripWeld.Part0 = hand
	gripWeld.Part1 = handle
	gripWeld.Parent = handle

	-- Guarda Dorada (Tsuba)
	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.65, 0.65, 0.14)
	guard.Color = Color3.fromRGB(240, 180, 40)
	guard.Material = Enum.Material.Metal
	guard.Anchored = false
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = handle.CFrame * CFrame.new(0, 0, -0.7)
	guard.Parent = katana

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = handle
	w1.Part1 = guard
	w1.Parent = guard

	-- Hoja Metálica de la Katana
	local blade = Instance.new("Part")
	blade.Name = "BladeBody"
	blade.Size = Vector3.new(0.1, 0.28, 4.0)
	blade.Color = Color3.fromRGB(220, 230, 245)
	blade.Material = Enum.Material.Metal
	blade.Anchored = false
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = handle.CFrame * CFrame.new(0, 0.02, -2.75)
	blade.Parent = katana

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = handle
	w2.Part1 = blade
	w2.Parent = blade

	-- Filo de Energía Carmesí / Cian Brillante
	local edge = Instance.new("Part")
	edge.Name = "GlowingEdge"
	edge.Size = Vector3.new(0.12, 0.12, 4.1)
	edge.Color = Color3.fromRGB(255, 35, 75)
	edge.Material = Enum.Material.Neon
	edge.Anchored = false
	edge.CanCollide = false
	edge.Massless = true
	edge.CFrame = blade.CFrame * CFrame.new(0, -0.1, -0.05)
	edge.Parent = katana

	local w3 = Instance.new("WeldConstraint")
	w3.Part0 = blade
	w3.Part1 = edge
	w3.Parent = edge

	-- Estela (Trail) real que dibuja el corte en el aire al mover el brazo
	local att0 = Instance.new("Attachment")
	att0.Name = "BaseAtt"
	att0.Position = Vector3.new(0, 0, 1.8)
	att0.Parent = edge

	local att1 = Instance.new("Attachment")
	att1.Name = "TipAtt"
	att1.Position = Vector3.new(0, 0, -2.0)
	att1.Parent = edge

	local trail = Instance.new("Trail")
	trail.Name = "SwordTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 35, 75)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 40))
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.25
	trail.FaceCamera = true
	trail.Parent = edge

	katana.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.spawn(equipKatanaModel, char)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		task.spawn(equipKatanaModel, p.Character)
	end
end

-- ============================================================================
-- ANIMACIÓN DEL BRAZO Y TORSO DEL JUGADOR EN COMBO (Compatible R15 y R6)
-- ============================================================================
local function animatePlayerSwordSwing(character, comboStep)
	-- Buscar articulación del brazo derecho en R15 o R6
	local rUpperArm = character:FindFirstChild("RightUpperArm")
	local rShoulder = rUpperArm and rUpperArm:FindFirstChild("RightShoulder")
	local torso = character:FindFirstChild("Torso")
	local r6Shoulder = torso and torso:FindFirstChild("Right Shoulder")

	if rShoulder and rShoulder:IsA("Motor6D") then
		local baseC0 = rShoulder:GetAttribute("OrigC0")
		if not baseC0 then
			baseC0 = rShoulder.C0
			rShoulder:SetAttribute("OrigC0", baseC0)
		end

		local windUp, strikePose
		if comboStep == 1 then
			windUp = baseC0 * CFrame.Angles(math.rad(135), math.rad(25), math.rad(35))
			strikePose = baseC0 * CFrame.Angles(math.rad(25), math.rad(-35), math.rad(-45))
		elseif comboStep == 2 then
			windUp = baseC0 * CFrame.Angles(math.rad(20), math.rad(-45), math.rad(-50))
			strikePose = baseC0 * CFrame.Angles(math.rad(130), math.rad(30), math.rad(40))
		else
			windUp = baseC0 * CFrame.Angles(math.rad(90), 0, math.rad(85))
			strikePose = baseC0 * CFrame.Angles(math.rad(90), math.rad(-80), math.rad(-75))
		end

		rShoulder.C0 = windUp
		TweenService:Create(rShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = strikePose}):Play()
		task.delay(0.22, function()
			if rShoulder and rShoulder.Parent then
				TweenService:Create(rShoulder, TweenInfo.new(0.15), {C0 = baseC0}):Play()
			end
		end)

	elseif r6Shoulder and r6Shoulder:IsA("Motor6D") then
		local baseC0 = r6Shoulder:GetAttribute("OrigC0")
		if not baseC0 then
			baseC0 = r6Shoulder.C0
			r6Shoulder:SetAttribute("OrigC0", baseC0)
		end

		local windUp = baseC0 * CFrame.Angles(0, math.rad(30), math.rad(130))
		local strikePose = baseC0 * CFrame.Angles(0, math.rad(-35), math.rad(20))
		r6Shoulder.C0 = windUp
		TweenService:Create(r6Shoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = strikePose}):Play()
		task.delay(0.22, function()
			if r6Shoulder and r6Shoulder.Parent then
				TweenService:Create(r6Shoulder, TweenInfo.new(0.15), {C0 = baseC0}):Play()
			end
		end)
	end
end

-- Crea una Onda de Energía de Katana animada con TweenService + Chispas (¡Sin bloques amarillos!)
local function createAnimatedSlashVFX(hrp, comboStep)
	local slashRing = Instance.new("Part")
	slashRing.Name = "KatanaSlashArc"
	slashRing.Shape = Enum.PartType.Cylinder
	slashRing.Size = Vector3.new(0.25, 5, 5)

	local tilt = (comboStep == 1) and math.rad(28) or ((comboStep == 2) and math.rad(-28) or 0)
	slashRing.CFrame = (hrp.CFrame * CFrame.new(0, 0.5, -3.5))
		* CFrame.Angles(0, 0, math.rad(90) + tilt)
	slashRing.Color = (comboStep == 3) and Color3.fromRGB(80, 225, 255) or Color3.fromRGB(255, 35, 85)
	slashRing.Material = Enum.Material.Neon
	slashRing.Transparency = 0.15
	slashRing.Anchored = true
	slashRing.CanCollide = false
	slashRing.Parent = Workspace

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(slashRing.Color, Color3.fromRGB(255, 220, 120))
	sparks.Size = NumberSequence.new(0.6, 0)
	sparks.Lifetime = NumberRange.new(0.15, 0.3)
	sparks.Speed = NumberRange.new(18, 32)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 0
	sparks.Parent = slashRing
	sparks:Emit(18)

	TweenService:Create(slashRing, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, 15, 15),
		CFrame = slashRing.CFrame * CFrame.new(0, 0, -4),
		Transparency = 1
	}):Play()
	Debris:AddItem(slashRing, 0.25)
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
			mRoot.AssemblyLinearVelocity = pushDir.Unit * 34 + Vector3.new(0, 14, 0)
		end
	end

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineColor = Color3.fromRGB(255, 45, 75)
	hl.FillTransparency = 0.2
	hl.Parent = monster
	Debris:AddItem(hl, 0.16)

	showFloatingDamage(mRoot.Position, damageAmount, damageAmount >= 34)
	play3DSound(mRoot, "rbxassetid://12222208", 1.0, 0.85)
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
		burst.Size = Vector3.new(3, 3, 3)
		burst.CFrame = mRoot.CFrame
		burst.Color = Color3.fromRGB(255, 60, 80)
		burst.Material = Enum.Material.Neon
		burst.Anchored = true
		burst.CanCollide = false
		burst.Parent = Workspace
		TweenService:Create(burst, TweenInfo.new(0.35), {Size = Vector3.new(18, 18, 18), Transparency = 1}):Play()
		Debris:AddItem(burst, 0.4)

		clientNotificationEvent:FireClient(
			attacker,
			(isBoss and "💀 ¡JEFE DERROTADO: " or "⚔️ ¡Eliminaste a ") .. monster.Name .. "! (+" .. coinReward .. " Monedas)"
		)
		task.delay(0.3, function()
			if monster and monster.Parent then
				monster:Destroy()
			end
		end)
	end
	return true
end

-- 1. ATAQUE DE KATANA CON ANIMACIÓN DE BRAZOS Y COMBO
basicAttackEvent.OnServerEvent:Connect(function(attacker)
	local cd = getCooldownTable(attacker.UserId)
	local now = os.clock()
	if now - cd.LastAttack < 0.38 then
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

	-- Auto-orientar hacia la criatura más cercana (<= 15 studs)
	local monstersFolder = Workspace:FindFirstChild("Monsters")
	local closestMonster = nil
	local closestDist = 15
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

	local combo = cd.ComboStep
	cd.ComboStep = (combo % 3) + 1

	animatePlayerSwordSwing(char, combo)
	createAnimatedSlashVFX(hrp, combo)
	play3DSound(hrp, "rbxassetid://12222216", 0.95 + combo * 0.1, 0.8)

	local baseDamage = (attacker:GetAttribute("HasVIP") and 34 or 26) + (combo == 3 and 10 or 0)
	local lookVec = hrp.CFrame.LookVector

	if monstersFolder then
		for _, monster in ipairs(monstersFolder:GetChildren()) do
			local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
			if mRoot then
				local offset = mRoot.Position - hrp.Position
				local dist = offset.Magnitude
				if dist <= 10.5 or (dist <= 15.5 and lookVec:Dot(offset.Unit) > -0.25) then
