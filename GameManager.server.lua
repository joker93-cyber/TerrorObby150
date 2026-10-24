-- GameManager.server.lua
-- Ubicación: ServerScriptService.GameManager
-- Incluye IA de monstruos por variante, ataques de Jefes con anillo de advertencia
-- y rescate automático anti-vacío.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

if not Workspace:FindFirstChild("MainSafetySpawn") then
	local safetyFloor = Instance.new("SpawnLocation")
	safetyFloor.Name = "MainSafetySpawn"
	safetyFloor.Size = Vector3.new(54, 2, 54)
	safetyFloor.CFrame = CFrame.new(0, 9, 0)
	safetyFloor.Color = Color3.fromRGB(75, 65, 78)
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
	Coins = 25,
	Wins = 0,
	CrucifixCharges = 1
}

local function loadPlayerData(player)
	local data = table.clone(DEFAULT_DATA)
	if playerDataStore then
		local success, saved = pcall(function()
			return playerDataStore:GetAsync("Player_" .. player.UserId)
		end)
		if success and type(saved) == "table" then
			data.Stage = math.clamp(tonumber(saved.Stage) or 1, 1, 150)
			data.Coins = math.max(0, tonumber(saved.Coins) or 25)
			data.Wins = math.max(0, tonumber(saved.Wins) or 0)
			data.CrucifixCharges = math.max(0, tonumber(saved.CrucifixCharges) or 1)
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
		player:SetAttribute("SpawnProtectionUntil", os.clock() + 5)

		local humanoid = character:WaitForChild("Humanoid", 10)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not hrp then return end

		task.defer(function()
			if player:GetAttribute("HasVIP") then
				humanoid.WalkSpeed = 22
				player:SetAttribute("VIPShieldReady", true)
			else
				humanoid.WalkSpeed = 16
			end
		end)

		local light = Instance.new("SpotLight")
		light.Name = "ServerFlashlight"
		light.Brightness = 3.5
		light.Range = 45
		light.Angle = 60
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

-- Rescate automático si un jugador cae por debajo del mapa
task.spawn(function()
	while true do
		task.wait(0.35)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local cp = getCheckpointPart(
					(SessionData[player.UserId] and SessionData[player.UserId].Stage) or 1
				)
				local minAllowedY = cp and (cp.Position.Y - 45) or -35
				if hrp.Position.Y < minAllowedY then
					teleportToStage(
						player,
						char,
						(SessionData[player.UserId] and SessionData[player.UserId].Stage) or 1
					)
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
				if (hrp.Position - obj.Position).Magnitude > 24 then return end

				local data = SessionData[player.UserId]
				local leaderstats = player:FindFirstChild("leaderstats")
				if not data or not leaderstats then return end

				local stageVal = leaderstats:FindFirstChild("Stage")
				local coinsVal = leaderstats:FindFirstChild("Coins")
				local winsVal = leaderstats:FindFirstChild("Wins")

				if stageNum > data.Stage and stageNum <= data.Stage + 3 then
					data.Stage = stageNum
					data.Coins = data.Coins + 10
					if stageVal then stageVal.Value = data.Stage end
					if coinsVal then coinsVal.Value = data.Coins end

					if stageNum == 150 then
						data.Wins = data.Wins + 1
						data.Coins = data.Coins + 150
						if winsVal then winsVal.Value = data.Wins end
						if coinsVal then coinsVal.Value = data.Coins end
						clientNotificationEvent:FireClient(player, "🏆 ¡COMPLETASTE LAS 150 ETAPAS! +150 Monedas")
					else
						clientNotificationEvent:FireClient(player, "✅ Etapa " .. stageNum .. " alcanzada (+10 Monedas)")
					end
				end
			end)
		end

		if obj:GetAttribute("IsHazard") or obj.Name == "KillLaser" or obj.Name == "KillPart" then
			ConnectedObjects[obj] = true
			obj.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					if player:GetAttribute("VIPShieldReady") then
						player:SetAttribute("VIPShieldReady", false)
						clientNotificationEvent:FireClient(player, "🛡️ ¡Tu Escudo VIP bloqueó una trampa mortal!")
						task.delay(20, function()
							if player and player.Parent then
								player:SetAttribute("VIPShieldReady", true)
							end
						end)
					elseif (player:GetAttribute("ActiveShieldUntil") or 0) > os.clock() then
						humanoid:TakeDamage(12)
					else
						humanoid:TakeDamage(50)
					end
				end
			end)
		end
	end

	if obj:IsA("ProximityPrompt") and (obj.Name == "HidePrompt" or string.find(string.lower(obj.ActionText), "esconder")) then
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
				clientNotificationEvent:FireClient(player, "🚪 Estás escondido en el armario.")
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
	if os.clock() - (cd.Crucifix or 0) < 1.5 then return end
	cd.Crucifix = os.clock()

	if data.CrucifixCharges <= 0 then
		clientNotificationEvent:FireClient(player, "⚠️ No tienes cargas del Crucifijo Sagrado. Consigue más en la Tienda.")
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local monstersFolder = Workspace:FindFirstChild("Monsters")
	local candidates = monstersFolder and monstersFolder:GetChildren() or Workspace:GetChildren()

	local stunnedCount = 0
	for _, monster in ipairs(candidates) do
		if monster:IsA("Model") and not Players:GetPlayerFromCharacter(monster) then
			local mHum = monster:FindFirstChildOfClass("Humanoid")
			local mRoot = monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart")
			if mHum and mRoot and (mRoot.Position - hrp.Position).Magnitude <= 45 then
				monster:SetAttribute("StunnedUntil", os.clock() + 6)
				stunnedCount += 1
			end
		end
	end

	if stunnedCount > 0 then
		data.CrucifixCharges -= 1
		player:SetAttribute("CrucifixCharges", data.CrucifixCharges)
		clientNotificationEvent:FireClient(player, "✝️ ¡Crucifijo Sagrado activado! Monstruo congelado por 6s.")
	else
		clientNotificationEvent:FireClient(player, "✝️ No hay monstruos cerca (máx. 45 studs).")
	end
end)

-- Ataque telegrafiado de Jefe (Crea un anillo de advertencia rojo 1.2s antes de explotar)
local function executeBossShockwave(bossModel, bossRoot)
	local telegraph = Instance.new("Part")
	telegraph.Name = "BossShockwaveTelegraph"
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.4, 24, 24)
	telegraph.CFrame = CFrame.new(bossRoot.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	telegraph.Color = Color3.fromRGB(255, 30, 30)
	telegraph.Material = Enum.Material.Neon
	telegraph.Transparency = 0.45
	telegraph.Anchored = true
	telegraph.CanCollide = false
	telegraph.Parent = Workspace
	Debris:AddItem(telegraph, 1.35)

	task.delay(1.2, function()
		if not bossModel or not bossModel.Parent then return end
		telegraph.Transparency = 0.1
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local pRoot = char and char:FindFirstChild("HumanoidRootPart")
			local pHum = char and char:FindFirstChildOfClass("Humanoid")
			if pRoot and pHum and pHum.Health > 0 then
				local horizontalDist = (Vector3.new(pRoot.Position.X, 0, pRoot.Position.Z) - Vector3.new(telegraph.Position.X, 0, telegraph.Position.Z)).Magnitude
				local verticalDiff = pRoot.Position.Y - telegraph.Position.Y
				-- Si el jugador salta a tiempo (verticalDiff > 3.5), esquiva la onda expansiva
				if horizontalDist <= 12 and verticalDiff < 3.5 then
					pHum:TakeDamage(35)
				end
			end
		end
	end)
end

-- Bucle de IA de Monstruos y Jefes
task.spawn(function()
	while true do
		task.wait(0.25)
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
						mHum:MoveTo(mRoot.Position)
					else
						local baseSpeed = monster:GetAttribute("BaseSpeed") or 15
						-- Si es Jefe y tiene menos de 50% de vida, entra en Fase 2 (Furia)
						if monster:GetAttribute("IsBoss") and mHum.Health < (mHum.MaxHealth * 0.5) then
							baseSpeed = baseSpeed + 4
						end
						mHum.WalkSpeed = baseSpeed

						local nearestPlayer = nil
						local nearestDist = 60

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
							local targetRoot = nearestPlayer.Character.HumanoidRootPart
							mHum:MoveTo(targetRoot.Position)

							-- Si es Jefe, lanza onda expansiva telegrafiada cada 6 segundos
							if monster:GetAttribute("IsBoss") and nearestDist <= 18 then
								local lastSlam = monster:GetAttribute("LastBossSlam") or 0
								if now - lastSlam >= 6 then
									monster:SetAttribute("LastBossSlam", now)
									executeBossShockwave(monster, mRoot)
								end
							end

							if nearestDist <= 5.5 then
								local pHum = nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
								if pHum and pHum.Health > 0 then
									if nearestPlayer:GetAttribute("VIPShieldReady") then
										nearestPlayer:SetAttribute("VIPShieldReady", false)
										monster:SetAttribute("StunnedUntil", now + 3)
										clientNotificationEvent:FireClient(nearestPlayer, "🛡️ ¡Tu Escudo VIP te salvó del monstruo!")
									elseif (nearestPlayer:GetAttribute("ActiveShieldUntil") or 0) > now then
										nearestPlayer:SetAttribute("ActiveShieldUntil", 0)
										monster:SetAttribute("StunnedUntil", now + 2.5)
										pHum:TakeDamage(35)
										clientNotificationEvent:FireClient(nearestPlayer, "🛡️ ¡Tu Escudo amortiguó el golpe!")
									else
										pHum:TakeDamage(monster:GetAttribute("IsBoss") and 55 or 100)
									end
								end
							end
						else
							local spawnPos = monster:GetAttribute("SpawnPosition")
							if spawnPos and (mRoot.Position - spawnPos).Magnitude > 35 then
								mHum:MoveTo(spawnPos)
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

print("[GameManager] Sistema completo actualizado con IA de Jefes y variantes.")
