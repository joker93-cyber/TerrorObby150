-- GameManager.server.lua
-- Ubicación: ServerScriptService.GameManager
-- Incluye motor físico y animación Motor6D para que todas las criaturas corran,
-- muevan brazos/piernas, den zarpazos reales y peleen en grupo contra el jugador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

if not Workspace:FindFirstChild("MainSafetySpawn") then
	local safetyFloor = Instance.new("SpawnLocation")
	safetyFloor.Name = "MainSafetySpawn"
	safetyFloor.Size = Vector3.new(58, 2, 58)
	safetyFloor.CFrame = CFrame.new(0, 9, 0)
	safetyFloor.Color = Color3.fromRGB(110, 88, 95)
	safetyFloor.Material = Enum.Material.Cobblestone
	safetyFloor.Anchored = true
	safetyFloor.CanCollide = true
	safetyFloor.Neutral = true
	safetyFloor.Duration = 0
	safetyFloor.Parent = Workspace
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
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

local toggleFlashlightEvent = getOrCreateRemote("ToggleFlashlight")
local useCrucifixEvent = getOrCreateRemote("UseCrucifix")
local clientNotificationEvent = getOrCreateRemote("ClientNotification")
local shopPurchaseEvent = getOrCreateRemote("ShopCoinPurchase")

local DATASTORE_NAME = "TerrorObby150_Data_v1"
local playerDataStore = nil
pcall(function()
	playerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

local SessionData = {}
local RemoteCooldowns = {}

local DEFAULT_DATA = {
	Stage = 1,
	Coins = 40,
	Wins = 0,
	CrucifixCharges = 2
}

local function loadPlayerData(player)
	local data = table.clone(DEFAULT_DATA)
	if playerDataStore then
		local success, saved = pcall(function()
			return playerDataStore:GetAsync("Player_" .. player.UserId)
		end)
		if success and type(saved) == "table" then
			data.Stage = math.clamp(tonumber(saved.Stage) or 1, 1, 150)
			data.Coins = math.max(0, tonumber(saved.Coins) or 40)
			data.Wins = math.max(0, tonumber(saved.Wins) or 0)
			data.CrucifixCharges = math.max(1, tonumber(saved.CrucifixCharges) or 2)
		end
	end
	SessionData[player.UserId] = data
	return data
end

local function savePlayerData(player)
	local data = SessionData[player.UserId]
	if not data or not playerDataStore then return end
	pcall(function()
		playerDataStore:UpdateAsync("Player_" .. player.UserId, function()
			return {
				Stage = data.Stage,
				Coins = data.Coins,
				Wins = data.Wins,
				CrucifixCharges = data.CrucifixCharges,
				UpdatedAt = os.time()
			}
		end)
	end)
end

local function getCheckpointPart(stageNumber)
	local checkpointsFolder = Workspace:FindFirstChild("Checkpoints")
	if checkpointsFolder then
		local found = checkpointsFolder:FindFirstChild("Checkpoint_" .. tostring(stageNumber))
			or checkpointsFolder:FindFirstChild(tostring(stageNumber))
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return Workspace:FindFirstChild("MainSafetySpawn")
end

local function teleportToStage(player, character, stageNumber)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local checkpoint = getCheckpointPart(stageNumber)
	local targetPos = Vector3.new(0, 14, 0)
	if checkpoint then
		targetPos = checkpoint.Position + Vector3.new(0, 4.5, 0)
	end

	pcall(function()
		player:RequestStreamAroundAsync(targetPos, 3)
	end)

	hrp.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(CFrame.new(targetPos))
end

local function onPlayerAdded(player)
	local data = loadPlayerData(player)
	RemoteCooldowns[player.UserId] = {}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stageVal = Instance.new("IntValue")
	stageVal.Name = "Stage"
	stageVal.Value = data.Stage
	stageVal.Parent = leaderstats

	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = data.Coins
	coinsVal.Parent = leaderstats

	local winsVal = Instance.new("IntValue")
	winsVal.Name = "Wins"
	winsVal.Value = data.Wins
	winsVal.Parent = leaderstats

	player:SetAttribute("CrucifixCharges", data.CrucifixCharges)
	player:SetAttribute("IsHiding", false)
	player:SetAttribute("IsInvisible", false)
	player:SetAttribute("InSafeZone", true)

	player.CharacterAdded:Connect(function(character)
		player:SetAttribute("IsHiding", false)
		player:SetAttribute("IsInvisible", false)
		player:SetAttribute("ActiveShieldUntil", 0)
		player:SetAttribute("SpawnProtectionUntil", os.clock() + 4)

		local humanoid = character:WaitForChild("Humanoid", 10)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not hrp then return end

		task.defer(function()
			if player:GetAttribute("HasVIP") then
				humanoid.WalkSpeed = 23
				player:SetAttribute("VIPShieldReady", true)
			else
				humanoid.WalkSpeed = 18
			end
		end)

		local light = Instance.new("SpotLight")
		light.Name = "ServerFlashlight"
		light.Brightness = 4.5
		light.Range = 55
		light.Angle = 65
		light.Enabled = false
		light.Parent = hrp

		task.wait(0.1)
		teleportToStage(player, character, stageVal.Value)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	SessionData[player.UserId] = nil
	RemoteCooldowns[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

-- Rescate inmediato si el jugador cae al valle inferior
task.spawn(function()
	while true do
		task.wait(0.3)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local stage = (SessionData[player.UserId] and SessionData[player.UserId].Stage) or 1
				local cp = getCheckpointPart(stage)
				local minAllowedY = cp and (cp.Position.Y - 36) or -25
				if hrp.Position.Y < minAllowedY then
					teleportToStage(player, char, stage)
				end
			end
		end
	end
end)

local ConnectedObjects = {}

local function hookObject(obj)
	if ConnectedObjects[obj] then return end

	if obj:IsA("BasePart") then
		local stageNum = obj:GetAttribute("StageNumber") or tonumber(string.match(obj.Name, "^Checkpoint_(%d+)$"))
		if stageNum then
			ConnectedObjects[obj] = true
			obj.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not humanoid or humanoid.Health <= 0 or not hrp then return end
				if (hrp.Position - obj.Position).Magnitude > 26 then return end

				local data = SessionData[player.UserId]
				local leaderstats = player:FindFirstChild("leaderstats")
				if not data or not leaderstats then return end

				local stageVal = leaderstats:FindFirstChild("Stage")
				local coinsVal = leaderstats:FindFirstChild("Coins")
				local winsVal = leaderstats:FindFirstChild("Wins")

				if stageNum > data.Stage and stageNum <= data.Stage + 3 then
					data.Stage = stageNum
					data.Coins = data.Coins + 15
					if stageVal then stageVal.Value = data.Stage end
					if coinsVal then coinsVal.Value = data.Coins end
					player:SetAttribute("CurrentBiome", obj:GetAttribute("BiomeName") or "")

					if stageNum == 150 then
						data.Wins = data.Wins + 1
						data.Coins = data.Coins + 200
						if winsVal then winsVal.Value = data.Wins end
						if coinsVal then coinsVal.Value = data.Coins end
						clientNotificationEvent:FireClient(player, "🏆 ¡VICTORIA ÉPICA! Completaste las 150 Etapas (+200 Monedas)")
					else
						clientNotificationEvent:FireClient(player, "🔥 Etapa " .. stageNum .. " superada (+15 Monedas)")
					end
				end
			end)
		end

		if obj:GetAttribute("IsHazard") or obj.Name == "KillLaser" then
			ConnectedObjects[obj] = true
			obj.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					if player:GetAttribute("VIPShieldReady") then
						player:SetAttribute("VIPShieldReady", false)
						clientNotificationEvent:FireClient(player, "🛡️ ¡Tu Escudo VIP absorbió el láser!")
						task.delay(18, function()
							if player and player.Parent then
								player:SetAttribute("VIPShieldReady", true)
							end
						end)
					elseif (player:GetAttribute("ActiveShieldUntil") or 0) > os.clock() then
						humanoid:TakeDamage(10)
					else
						humanoid:TakeDamage(35)
					end
				end
			end)
		end
	end

	if obj:IsA("ProximityPrompt") and obj.Name == "HidePrompt" then
		ConnectedObjects[obj] = true
		obj.Triggered:Connect(function(player)
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local body = obj.Parent
			if not hrp or not humanoid or humanoid.Health <= 0 or not body or not body:IsA("BasePart") then return end
			if (hrp.Position - body.Position).Magnitude > 14 then return end

			local isHiding = player:GetAttribute("IsHiding")
			if not isHiding then
				player:SetAttribute("IsHiding", true)
				player:SetAttribute("PreHideCFrame", hrp.CFrame)
				hrp.Anchored = true
				character:PivotTo(body.CFrame)
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 1
					end
				end
				clientNotificationEvent:FireClient(player, "🚪 Te escondiste en el armario.")
			else
				player:SetAttribute("IsHiding", false)
				hrp.Anchored = false
				local exitCF = player:GetAttribute("PreHideCFrame") or (body.CFrame * CFrame.new(0, 0, 4))
				character:PivotTo(exitCF)
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 0
					end
				end
				clientNotificationEvent:FireClient(player, "🏃 Saliste del armario.")
			end
		end)
	end
end

task.spawn(function()
	task.wait(0.5)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		hookObject(obj)
	end
	Workspace.DescendantAdded:Connect(hookObject)
end)

toggleFlashlightEvent.OnServerEvent:Connect(function(player)
	local cd = RemoteCooldowns[player.UserId]
	if not cd then return end
	if os.clock() - (cd.Flashlight or 0) < 0.25 then return end
	cd.Flashlight = os.clock()

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local light = hrp and hrp:FindFirstChild("ServerFlashlight")
	if light then
		light.Enabled = not light.Enabled
	end
end)

useCrucifixEvent.OnServerEvent:Connect(function(player)
	local cd = RemoteCooldowns[player.UserId]
	local data = SessionData[player.UserId]
	if not cd or not data then return end
	if os.clock() - (cd.Crucifix or 0) < 1.2 then return end
	cd.Crucifix = os.clock()

	if data.CrucifixCharges <= 0 then
		clientNotificationEvent:FireClient(player, "⚠️ Sin cargas de Crucifijo. Consigue más en la Tienda.")
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local monstersFolder = Workspace:FindFirstChild("Monsters")
	if not monstersFolder then return end

	local stunnedCount = 0
	for _, monster in ipairs(monstersFolder:GetChildren()) do
		local mHum = monster:FindFirstChildOfClass("Humanoid")
		local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
		if mHum and mRoot and mHum.Health > 0 and (mRoot.Position - hrp.Position).Magnitude <= 50 then
			monster:SetAttribute("StunnedUntil", os.clock() + 6)
			mHum:TakeDamage(35)
			stunnedCount += 1
		end
	end

	if stunnedCount > 0 then
		data.CrucifixCharges -= 1
		player:SetAttribute("CrucifixCharges", data.CrucifixCharges)

		-- Rayo dorado sagrado visual
		local holyBlast = Instance.new("Part")
		holyBlast.Shape = Enum.PartType.Ball
		holyBlast.Size = Vector3.new(36, 36, 36)
		holyBlast.CFrame = hrp.CFrame
		holyBlast.Color = Color3.fromRGB(255, 225, 90)
		holyBlast.Material = Enum.Material.Neon
		holyBlast.Transparency = 0.45
		holyBlast.Anchored = true
		holyBlast.CanCollide = false
		holyBlast.Parent = Workspace
		Debris:AddItem(holyBlast, 0.4)

		clientNotificationEvent:FireClient(player, "✝️ ¡Crucifijo Sagrado! " .. stunnedCount .. " criatura(s) herida(s) y congelada(s).")
	else
		clientNotificationEvent:FireClient(player, "✝️ No hay criaturas cerca.")
	end
end)

-- ============================================================================
-- MOTOR DE IA ACTIVA, PERSECUCIÓN FÍSICA Y ANIMACIÓN DE GARRAS / PASOS
-- ============================================================================
local function animateMonsterLimbs(monster, isMoving, isAttacking, now)
	local torso = monster:FindFirstChild("Torso")
	if not torso then return end
	local scale = monster:GetAttribute("Scale") or 1

	local lShoulder = torso:FindFirstChild("LeftShoulderMotor")
	local rShoulder = torso:FindFirstChild("RightShoulderMotor")
	local lHip = torso:FindFirstChild("LeftHipMotor")
	local rHip = torso:FindFirstChild("RightHipMotor")

	local swing = isMoving and math.sin(now * 10) * 0.65 or math.sin(now * 2.5) * 0.12
	local armRaise = isAttacking and math.rad(115) or (isMoving and (math.rad(45) + swing * 0.5) or math.rad(25))

	if lShoulder then
		lShoulder.C0 = CFrame.new(-1.55 * scale, 0.9 * scale, 0) * CFrame.Angles(armRaise, 0, math.rad(-12))
	end
	if rShoulder then
		rShoulder.C0 = CFrame.new(1.55 * scale, 0.9 * scale, 0) * CFrame.Angles(armRaise - swing * 0.4, 0, math.rad(12))
	end
	if lHip then
		lHip.C0 = CFrame.new(-0.68 * scale, -1.1 * scale, 0) * CFrame.Angles(swing, 0, 0)
	end
	if rHip then
		rHip.C0 = CFrame.new(0.68 * scale, -1.1 * scale, 0) * CFrame.Angles(-swing, 0, 0)
	end
end

task.spawn(function()
	while true do
		task.wait(0.12)
		local monstersFolder = Workspace:FindFirstChild("Monsters")
		if monstersFolder then
			local now = os.clock()
			for _, monster in ipairs(monstersFolder:GetChildren()) do
				local mHum = monster:FindFirstChildOfClass("Humanoid")
				local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
				if mHum and mRoot and mHum.Health > 0 then
					local stunnedUntil = monster:GetAttribute("StunnedUntil") or 0
					if now < stunnedUntil then
						mHum.WalkSpeed = 0
						mRoot.AssemblyLinearVelocity = Vector3.new(0, mRoot.AssemblyLinearVelocity.Y, 0)
						animateMonsterLimbs(monster, false, false, now)
					else
						local baseSpeed = monster:GetAttribute("BaseSpeed") or 16
						if monster:GetAttribute("IsBoss") and mHum.Health < (mHum.MaxHealth * 0.5) then
							baseSpeed += 4
						end
						mHum.WalkSpeed = baseSpeed

						local nearestPlayer = nil
						local nearestDist = 75

						for _, player in ipairs(Players:GetPlayers()) do
							if not player:GetAttribute("IsHiding") and not player:GetAttribute("IsInvisible") then
								local char = player.Character
								local pRoot = char and char:FindFirstChild("HumanoidRootPart")
								local pHum = char and char:FindFirstChildOfClass("Humanoid")
								if pRoot and pHum and pHum.Health > 0 then
									local dist = (pRoot.Position - mRoot.Position).Magnitude
									if dist < nearestDist then
										nearestDist = dist
										nearestPlayer = player
									end
								end
							end
						end

						if nearestPlayer and nearestPlayer.Character then
							local targetPos = nearestPlayer.Character.HumanoidRootPart.Position
							local flatTarget = Vector3.new(targetPos.X, mRoot.Position.Y, targetPos.Z)
							local dir = (flatTarget - mRoot.Position)

							if dir.Magnitude > 0.5 then
								local unitDir = dir.Unit
								-- Orientar criatura hacia el jugador y aplicar impulso de corrida real
								mRoot.CFrame = CFrame.lookAt(mRoot.Position, flatTarget)
								mHum:MoveTo(targetPos)
								mRoot.AssemblyLinearVelocity = Vector3.new(
									unitDir.X * baseSpeed,
									mRoot.AssemblyLinearVelocity.Y,
									unitDir.Z * baseSpeed
								)
							end

							local isClose = nearestDist <= 6.8
							animateMonsterLimbs(monster, true, isClose, now)

							-- Ataque de garras con enfriamiento de 1.1s para permitir batallas justas
							if isClose then
								local lastHit = monster:GetAttribute("LastAttackTime") or 0
								if now - lastHit >= 1.1 then
									monster:SetAttribute("LastAttackTime", now)

									-- Efecto visual de zarpazo rojo del monstruo
									local clawSlash = Instance.new("Part")
									clawSlash.Size = Vector3.new(5, 0.4, 5)
									clawSlash.CFrame = mRoot.CFrame * CFrame.new(0, 0.5, -3) * CFrame.Angles(0, 0, math.rad(35))
									clawSlash.Color = Color3.fromRGB(255, 30, 30)
									clawSlash.Material = Enum.Material.Neon
									clawSlash.Transparency = 0.25
									clawSlash.Anchored = true
									clawSlash.CanCollide = false
									clawSlash.Parent = Workspace
									Debris:AddItem(clawSlash, 0.2)

									local pHum = nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
									if pHum and pHum.Health > 0 then
										if nearestPlayer:GetAttribute("VIPShieldReady") then
											nearestPlayer:SetAttribute("VIPShieldReady", false)
											monster:SetAttribute("StunnedUntil", now + 2.5)
											clientNotificationEvent:FireClient(nearestPlayer, "🛡️ ¡Tu Escudo VIP bloqueó el zarpazo y aturdió a la criatura!")
										elseif (nearestPlayer:GetAttribute("ActiveShieldUntil") or 0) > now then
											pHum:TakeDamage(8)
										else
											pHum:TakeDamage(monster:GetAttribute("IsBoss") and 35 or 22)
										end
									end
								end
							end
						else
							-- Patrullaje activo de lado a lado cuando el jugador aún está lejos
							local spawnPos = monster:GetAttribute("SpawnPosition") or mRoot.Position
							local patrolOffset = Vector3.new(math.sin(now * 1.2 + spawnPos.Z) * 10, 0, math.cos(now * 1.2 + spawnPos.Z) * 8)
							local goal = Vector3.new(spawnPos.X + patrolOffset.X, mRoot.Position.Y, spawnPos.Z + patrolOffset.Z)
							local dir = goal - mRoot.Position
							if dir.Magnitude > 1.5 then
								mRoot.CFrame = CFrame.lookAt(mRoot.Position, goal)
								mRoot.AssemblyLinearVelocity = Vector3.new(dir.Unit.X * 10, mRoot.AssemblyLinearVelocity.Y, dir.Unit.Z * 10)
								animateMonsterLimbs(monster, true, false, now)
							else
								animateMonsterLimbs(monster, false, false, now)
							end
						end
					end
				end
			end
		end
	end
end)

_G.TerrorObbyAddCoins = function(player, amount)
	local data = SessionData[player.UserId]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not data or not leaderstats then return end
	data.Coins = math.max(0, data.Coins + (tonumber(amount) or 0))
	local coinsVal = leaderstats:FindFirstChild("Coins")
	if coinsVal then
		coinsVal.Value = data.Coins
	end
end

_G.TerrorObbyGrantItem = function(player, itemType)
	local data = SessionData[player.UserId]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not data or not leaderstats then return false, "Datos no disponibles" end

	local coinsVal = leaderstats:FindFirstChild("Coins")
	if itemType == "CrucifixCharge" then
		if data.Coins < 40 then
			return false, "Necesitas 40 Monedas para comprar un Crucifijo."
		end
		data.Coins -= 40
		data.CrucifixCharges += 1
		if coinsVal then coinsVal.Value = data.Coins end
		player:SetAttribute("CrucifixCharges", data.CrucifixCharges)
		return true, "✝️ Compraste +1 Carga de Crucifijo Sagrado."
	elseif itemType == "SkipStageCoin" then
		if data.Coins < 120 then
			return false, "Necesitas 120 Monedas para saltar de etapa."
		end
		if data.Stage >= 150 then
			return false, "Ya estás en la última etapa."
		end
		data.Coins -= 120
		data.Stage += 1
		if coinsVal then coinsVal.Value = data.Coins end
		if leaderstats:FindFirstChild("Stage") then
			leaderstats.Stage.Value = data.Stage
		end
		if player.Character then
			teleportToStage(player, player.Character, data.Stage)
		end
		return true, "⚡ Saltaste a la Etapa " .. data.Stage .. "."
	end
	return false, "Artículo desconocido."
end

print("[GameManager] Motor de criaturas articuladas y combate en vivo listo.")
