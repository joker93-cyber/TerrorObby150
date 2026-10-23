-- LevelGenerator.server.lua (Versión Blindada y Completa - 150 Niveles)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- ==========================================
-- 1. PISO DE INICIO INMEDIATO (ANTI-CAÍDA AL VACÍO)
-- ==========================================
local safeLobby = Instance.new("Part")
safeLobby.Name = "SafeStartLobby"
safeLobby.Size = Vector3.new(40, 2, 40)
safeLobby.Position = Vector3.new(0, 0, 0)
safeLobby.Anchored = true
safeLobby.Material = Enum.Material.Slate
safeLobby.Color = Color3.fromRGB(45, 45, 50)
safeLobby.Parent = Workspace

local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
if not spawnLocation then
	spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Parent = Workspace
end
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(12, 1, 12)
spawnLocation.Position = Vector3.new(0, 1.5, 0)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color = Color3.fromRGB(80, 20, 20)

-- Luz en la base inicial para que siempre sea visible
local startLight = Instance.new("PointLight")
startLight.Range = 45
startLight.Brightness = 2
startLight.Color = Color3.fromRGB(255, 220, 180)
startLight.Parent = spawnLocation

-- Atmosfera de terror base
Lighting.Brightness = 1
Lighting.ClockTime = 0
Lighting.FogEnd = 250
Lighting.FogColor = Color3.fromRGB(10, 10, 15)
Lighting.Ambient = Color3.fromRGB(35, 35, 45)
Lighting.OutdoorAmbient = Color3.fromRGB(25, 25, 35)

-- ==========================================
-- 2. CARPETAS DEL MAPA Y CHECKPOINTS
-- ==========================================
local mapFolder = Workspace:FindFirstChild("Map") or Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder.Parent = Workspace

local checkpointsFolder = Workspace:FindFirstChild("Checkpoints") or Instance.new("Folder")
checkpointsFolder.Name = "Checkpoints"
checkpointsFolder.Parent = Workspace

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

-- Intentar cargar ProceduralModels de forma segura sin detener el script
local ProceduralModels = nil
pcall(function()
	local mod = ReplicatedStorage:FindFirstChild("ProceduralModels")
	if mod then
		ProceduralModels = require(mod)
	end
end)

-- ==========================================
-- 3. CONFIGURACIÓN DE LOS 5 BIOMAS
-- ==========================================
local BIOMES = {
	[1] = {
		Name = "El Manicomio",
		PrimaryColor = Color3.fromRGB(110, 115, 120),
		SecondaryColor = Color3.fromRGB(70, 25, 25),
		Material = Enum.Material.Concrete,
		HazardColor = Color3.fromRGB(180, 0, 0)
	},
	[2] = {
		Name = "Las Alcantarillas",
		PrimaryColor = Color3.fromRGB(55, 65, 55),
		SecondaryColor = Color3.fromRGB(40, 90, 35),
		Material = Enum.Material.CorrodedMetal,
		HazardColor = Color3.fromRGB(60, 220, 40)
	},
	[3] = {
		Name = "La Mansión Siniestra",
		PrimaryColor = Color3.fromRGB(75, 40, 30),
		SecondaryColor = Color3.fromRGB(120, 20, 30),
		Material = Enum.Material.WoodPlanks,
		HazardColor = Color3.fromRGB(220, 30, 60)
	},
	[4] = {
		Name = "El Bosque Maldito",
		PrimaryColor = Color3.fromRGB(45, 55, 40),
		SecondaryColor = Color3.fromRGB(30, 35, 30),
		Material = Enum.Material.Slate,
		HazardColor = Color3.fromRGB(140, 40, 220)
	},
	[5] = {
		Name = "El Purgatorio",
		PrimaryColor = Color3.fromRGB(30, 25, 30),
		SecondaryColor = Color3.fromRGB(200, 60, 0),
		Material = Enum.Material.Basalt,
		HazardColor = Color3.fromRGB(255, 85, 0)
	}
}

local function getBiome(stage)
	local index = math.clamp(math.ceil(stage / 30), 1, 5)
	return BIOMES[index]
end

-- ==========================================
-- 4. CONSTRUCTORES DE ARMARIOS, ENEMIGOS Y JEFES
-- ==========================================
local function createLocker(position)
	local locker = Instance.new("Part")
	locker.Name = "HidingLocker"
	locker.Size = Vector3.new(4, 8, 4)
	locker.Position = position + Vector3.new(0, 4, 0)
	locker.Anchored = true
	locker.Material = Enum.Material.Metal
	locker.Color = Color3.fromRGB(60, 65, 70)
	locker.Parent = mapFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Armario"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.Parent = locker

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		local isHiding = char:GetAttribute("IsHiding")
		if not isHiding then
			char:SetAttribute("IsHiding", true)
			hrp.Anchored = true
			hrp.CFrame = locker.CFrame
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part:SetAttribute("OrigTrans", part.Transparency)
					part.Transparency = 1
				end
			end
		else
			char:SetAttribute("IsHiding", false)
			hrp.Anchored = false
			hrp.CFrame = locker.CFrame * CFrame.new(0, 0, -5)
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					local orig = part:GetAttribute("OrigTrans")
					if orig ~= nil then
						part.Transparency = orig
					end
				end
			end
		end
	end)
end

local activeEnemies = {}

local function createEnemy(centerPos, patrolRadius, isBoss, biome)
	local enemy = Instance.new("Part")
	enemy.Name = isBoss and "BossEnemy" or "HorrorEnemy"
	enemy.Size = isBoss and Vector3.new(6, 12, 6) or Vector3.new(3, 6, 3)
	enemy.Position = centerPos + Vector3.new(0, enemy.Size.Y / 2, 0)
	enemy.Anchored = true
	enemy.CanCollide = false
	enemy.Material = Enum.Material.Neon
	enemy.Color = isBoss and Color3.fromRGB(255, 20, 20) or biome.HazardColor
	enemy.Parent = enemiesFolder

	-- Ojos brillantes
	local light = Instance.new("PointLight")
	light.Color = enemy.Color
	light.Range = isBoss and 35 or 18
	light.Brightness = 3
	light.Parent = enemy

	enemy.Touched:Connect(function(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and not char:GetAttribute("IsHiding") then
			hum.Health = 0
		end
	end)

	table.insert(activeEnemies, {
		Part = enemy,
		Origin = enemy.Position,
		Radius = patrolRadius,
		IsBoss = isBoss,
		LastWave = tick()
	})
end

-- ==========================================
-- 5. GENERACIÓN DE LOS 150 NIVELES
-- ==========================================
local currentZ = -20
local STAGE_LENGTH = 70

for stage = 1, 150 do
	local biome = getBiome(stage)

	-- Plataforma de Checkpoint
	local cp = Instance.new("Part")
	cp.Name = tostring(stage)
	cp.Size = Vector3.new(16, 2, 16)
	cp.Position = Vector3.new(0, 0, currentZ)
	cp.Anchored = true
	cp.Material = biome.Material
	cp.Color = biome.PrimaryColor
	cp.Parent = checkpointsFolder

	-- Indicador luminoso de Checkpoint
	local neonPad = Instance.new("Part")
	neonPad.Name = "Pad"
	neonPad.Size = Vector3.new(6, 0.4, 6)
	neonPad.Position = cp.Position + Vector3.new(0, 1.1, 0)
	neonPad.Anchored = true
	neonPad.CanCollide = false
	neonPad.Material = Enum.Material.Neon
	neonPad.Color = Color3.fromRGB(0, 200, 100)
	neonPad.Parent = cp

	-- Cartel con el número de Nivel y Bioma
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 140, 0, 50)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.AlwaysOnTop = false
	bg.MaxDistance = 80
	bg.Parent = cp

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "NIVEL " .. stage .. "\n" .. biome.Name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bg

	-- Armario para esconderse cada 3 niveles
	if stage % 3 == 0 then
		createLocker(cp.Position + Vector3.new(-6, 1, 0))
	end

	-- Generar obstáculos o Arena de Jefe
	if stage % 30 == 0 then
		-- Arena de Jefe Final del Bioma
		local arena = Instance.new("Part")
		arena.Name = "BossArena_" .. stage
		arena.Size = Vector3.new(32, 2, STAGE_LENGTH - 16)
		arena.Position = Vector3.new(0, 0, currentZ - (STAGE_LENGTH / 2))
		arena.Anchored = true
		arena.Material = biome.Material
		arena.Color = biome.SecondaryColor
		arena.Parent = mapFolder

		createLocker(arena.Position + Vector3.new(12, 1, 0))
		createLocker(arena.Position + Vector3.new(-12, 1, 0))
		createEnemy(arena.Position, 14, true, biome)
	else
		-- 4 plataformas de salto por nivel + láseres mortales
		local stepCount = 4
		local stepSpacing = STAGE_LENGTH / (stepCount + 1)

		for i = 1, stepCount do
			local stepZ = currentZ - (i * stepSpacing)
			local offsetX = math.sin(stage * i) * 5

			local pad = Instance.new("Part")
			pad.Name = "Step"
			pad.Size = Vector3.new(8, 1.5, 8)
			pad.Position = Vector3.new(offsetX, 0, stepZ)
			pad.Anchored = true
			pad.Material = biome.Material
			pad.Color = (i % 2 == 0) and biome.SecondaryColor or biome.PrimaryColor
			pad.Parent = mapFolder

			-- Trampa láser mortal en niveles pares o avanzados
			if (stage + i) % 2 == 0 then
				local killPart = Instance.new("Part")
				killPart.Name = "LavaLaser"
				killPart.Size = Vector3.new(8, 0.6, 1.2)
				killPart.Position = pad.Position + Vector3.new(0, 1.1, 0)
				killPart.Anchored = true
				killPart.CanCollide = false
				killPart.Material = Enum.Material.Neon
				killPart.Color = biome.HazardColor
				killPart.Parent = mapFolder

				killPart.Touched:Connect(function(hit)
					local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = 0
					end
				end)
			end
		end

		-- Enemigo patrullando cada 5 niveles
		if stage % 5 == 0 then
			local bridge = Instance.new("Part")
			bridge.Size = Vector3.new(14, 1, STAGE_LENGTH - 16)
			bridge.Position = Vector3.new(0, -0.5, currentZ - (STAGE_LENGTH / 2))
			bridge.Anchored = true
			bridge.Material = biome.Material
			bridge.Color = biome.PrimaryColor
			bridge.Parent = mapFolder

			createEnemy(bridge.Position + Vector3.new(0, 1, 0), 6, false, biome)
		end
	end

	currentZ = currentZ - STAGE_LENGTH

	-- Pausa ligera cada 50 niveles para no congelar el arranque
	if stage % 50 == 0 then
		task.wait()
	end
end

-- Meta Final en el Nivel 150
local winPlatform = Instance.new("Part")
winPlatform.Name = "VictoryPlatform"
winPlatform.Size = Vector3.new(30, 2, 30)
winPlatform.Position = Vector3.new(0, 0, currentZ)
winPlatform.Anchored = true
winPlatform.Material = Enum.Material.Neon
winPlatform.Color = Color3.fromRGB(255, 215, 0)
winPlatform.Parent = mapFolder

-- ==========================================
-- 6. SISTEMA DE CHECKPOINTS Y SPAWN SEGURO
-- ==========================================
local function teleportToStage(player, character)
	task.wait(0.1)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local stageVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
	local stageNum = (stageVal and stageVal.Value) or 1
	local cp = checkpointsFolder:FindFirstChild(tostring(stageNum)) or checkpointsFolder:FindFirstChild("1")

	if cp then
		hrp.CFrame = cp.CFrame + Vector3.new(0, 4, 0)
	else
		hrp.CFrame = CFrame.new(0, 5, 0)
	end
end

local function setupPlayer(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end

	local stage = ls:FindFirstChild("Stage")
	if not stage then
		stage = Instance.new("IntValue")
		stage.Name = "Stage"
		stage.Value = 1
		stage.Parent = ls
	end

	player.CharacterAdded:Connect(function(char)
		teleportToStage(player, char)
	end)

	if player.Character then
		teleportToStage(player, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

-- Detectar cuando el jugador pisa un nuevo Checkpoint
for _, cp in ipairs(checkpointsFolder:GetChildren()) do
	if cp:IsA("BasePart") then
		local stageNum = tonumber(cp.Name)
		if stageNum then
			cp.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player and player:FindFirstChild("leaderstats") then
					local stageVal = player.leaderstats:FindFirstChild("Stage")
					if stageVal and stageNum == stageVal.Value + 1 then
						stageVal.Value = stageNum
					end
				end
			end)
		end
	end
end

-- ==========================================
-- 7. IA DE PERSECUCIÓN Y ONDAS DE JEFES
-- ==========================================
RunService.Heartbeat:Connect(function(dt)
	local now = tick()
	for _, data in ipairs(activeEnemies) do
		local part = data.Part
		if part and part.Parent then
			-- Buscar si hay un jugador cerca que NO esté escondido
			local targetPos = nil
			local shortestDist = 35

			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and not char:GetAttribute("IsHiding") then
					local dist = (hrp.Position - data.Origin).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						targetPos = hrp.Position
					end
				end
			end

			if targetPos then
				-- Perseguir al jugador
				local dir = (Vector3.new(targetPos.X, part.Position.Y, targetPos.Z) - part.Position)
				if dir.Magnitude > 0.5 then
					part.Position = part.Position + dir.Unit * (data.IsBoss and 14 or 11) * dt
				end
			else
				-- Patrullar de lado a lado
				local offset = math.sin(now * 2) * data.Radius
				part.Position = data.Origin + Vector3.new(offset, 0, 0)
			end

			-- Onda expansiva si es Jefe cada 4 segundos
			if data.IsBoss and (now - data.LastWave > 4) then
				data.LastWave = now
				local wave = Instance.new("Part")
				wave.Size = Vector3.new(28, 1.2, 2)
				wave.Position = part.Position - Vector3.new(0, (part.Size.Y / 2) - 0.6, 0)
				wave.Anchored = true
				wave.CanCollide = false
				wave.Material = Enum.Material.Neon
				wave.Color = Color3.fromRGB(255, 50, 0)
				wave.Parent = enemiesFolder

				wave.Touched:Connect(function(hit)
					local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
					if hum and not hit.Parent:GetAttribute("IsHiding") then
						hum.Health = 0
					end
				end)

				task.spawn(function()
					for i = 1, 30 do
						wave.Position = wave.Position + Vector3.new(0, 0, 1.2)
						task.wait(0.03)
					end
					wave:Destroy()
				end)
			end
		end
	end
end)
