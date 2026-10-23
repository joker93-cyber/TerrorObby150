-- LevelGenerator.server.lua (Edición Tierra: Pasillos Reales, Trampas Móviles y Monstruos 3D)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- ==========================================
-- 1. CIELO TERRESTRE Y ATMÓSFERA (CERO ESPACIO EXTERIOR)
-- ==========================================
local function applyEarthLighting()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") and child.Name ~= "EarthHorrorSky" then
			child:Destroy()
		end
	end

	Lighting.Brightness = 2
	Lighting.ClockTime = 0
	Lighting.Ambient = Color3.fromRGB(75, 70, 75)
	Lighting.OutdoorAmbient = Color3.fromRGB(65, 65, 75)
	Lighting.FogStart = 45
	Lighting.FogEnd = 260
	Lighting.FogColor = Color3.fromRGB(28, 30, 35)

	if not Lighting:FindFirstChild("EarthHorrorSky") then
		local sky = Instance.new("Sky")
		sky.Name = "EarthHorrorSky"
		sky.StarCount = 0
		sky.CelestialBodiesShown = false
		sky.Parent = Lighting
	end
end

applyEarthLighting()
task.delay(2, applyEarthLighting)

-- ==========================================
-- 2. CARPETAS DEL MUNDO
-- ==========================================
local mapFolder = Workspace:FindFirstChild("Map") or Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder:ClearAllChildren()
mapFolder.Parent = Workspace

local checkpointsFolder = Workspace:FindFirstChild("Checkpoints") or Instance.new("Folder")
checkpointsFolder.Name = "Checkpoints"
checkpointsFolder:ClearAllChildren()
checkpointsFolder.Parent = Workspace

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder:ClearAllChildren()
enemiesFolder.Parent = Workspace

-- ==========================================
-- 3. SALA DE INICIO EN LA TIERRA (BÚNKER DEL MANICOMIO)
-- ==========================================
local function makeWall(size, pos, mat, col)
	local w = Instance.new("Part")
	w.Size = size
	w.Position = pos
	w.Anchored = true
	w.Material = mat
	w.Color = col
	w.Parent = mapFolder
	return w
end

local safeLobby = makeWall(Vector3.new(36, 2, 36), Vector3.new(0, 0, 0), Enum.Material.Concrete, Color3.fromRGB(85, 85, 90))
safeLobby.Name = "SafeStartLobby"

local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.Position = Vector3.new(0, 1.5, 8)
spawnLocation.Anchored = true
spawnLocation.Material = Enum.Material.Slate
spawnLocation.Color = Color3.fromRGB(50, 50, 55)
spawnLocation.Parent = Workspace

-- Paredes y techo del Lobby
makeWall(Vector3.new(2, 22, 36), Vector3.new(-18, 11, 0), Enum.Material.Brick, Color3.fromRGB(65, 60, 60))
makeWall(Vector3.new(2, 22, 36), Vector3.new(18, 11, 0), Enum.Material.Brick, Color3.fromRGB(65, 60, 60))
makeWall(Vector3.new(38, 22, 2), Vector3.new(0, 11, 18), Enum.Material.Brick, Color3.fromRGB(65, 60, 60))
makeWall(Vector3.new(38, 2, 36), Vector3.new(0, 22, 0), Enum.Material.Concrete, Color3.fromRGB(45, 45, 50))

local lobbyLightPart = makeWall(Vector3.new(6, 0.5, 6), Vector3.new(0, 20.8, 0), Enum.Material.Neon, Color3.fromRGB(255, 235, 190))
local lobbyLight = Instance.new("PointLight")
lobbyLight.Range = 55
lobbyLight.Brightness = 2.5
lobbyLight.Color = Color3.fromRGB(255, 235, 190)
lobbyLight.Parent = lobbyLightPart

-- ==========================================
-- 4. DEFINICIÓN DE LOS 5 BIOMAS TERRESTRES
-- ==========================================
local BIOMES = {
	[1] = {
		Name = "El Manicomio Abandonado",
		Indoor = true,
		WallMat = Enum.Material.Concrete,
		WallColor = Color3.fromRGB(95, 100, 100),
		FloorMat = Enum.Material.Slate,
		FloorColor = Color3.fromRGB(65, 70, 75),
		PitColor = Color3.fromRGB(90, 15, 15),
		PitMat = Enum.Material.Granite,
		LightColor = Color3.fromRGB(220, 240, 255),
		MonsterColor = Color3.fromRGB(200, 20, 20)
	},
	[2] = {
		Name = "Las Alcantarillas Tóxicas",
		Indoor = true,
		WallMat = Enum.Material.Brick,
		WallColor = Color3.fromRGB(55, 65, 55),
		FloorMat = Enum.Material.CorrodedMetal,
		FloorColor = Color3.fromRGB(75, 65, 55),
		PitColor = Color3.fromRGB(50, 200, 40),
		PitMat = Enum.Material.Neon,
		LightColor = Color3.fromRGB(160, 255, 160),
		MonsterColor = Color3.fromRGB(40, 220, 50)
	},
	[3] = {
		Name = "La Mansión Sangrienta",
		Indoor = true,
		WallMat = Enum.Material.WoodPlanks,
		WallColor = Color3.fromRGB(70, 40, 30),
		FloorMat = Enum.Material.Cobblestone,
		FloorColor = Color3.fromRGB(90, 30, 30),
		PitColor = Color3.fromRGB(140, 0, 20),
		PitMat = Enum.Material.Neon,
		LightColor = Color3.fromRGB(255, 190, 130),
		MonsterColor = Color3.fromRGB(220, 15, 40)
	},
	[4] = {
		Name = "El Bosque Maldito",
		Indoor = false,
		WallMat = Enum.Material.Slate,
		WallColor = Color3.fromRGB(45, 55, 40),
		FloorMat = Enum.Material.Grass,
		FloorColor = Color3.fromRGB(45, 65, 40),
		PitColor = Color3.fromRGB(35, 45, 30),
		PitMat = Enum.Material.Mud,
		LightColor = Color3.fromRGB(180, 200, 255),
		MonsterColor = Color3.fromRGB(150, 40, 230)
	},
	[5] = {
		Name = "Las Ruinas del Purgatorio",
		Indoor = false,
		WallMat = Enum.Material.Basalt,
		WallColor = Color3.fromRGB(40, 35, 35),
		FloorMat = Enum.Material.CrackedLava,
		FloorColor = Color3.fromRGB(65, 35, 30),
		PitColor = Color3.fromRGB(255, 75, 0),
		PitMat = Enum.Material.Neon,
		LightColor = Color3.fromRGB(255, 130, 60),
		MonsterColor = Color3.fromRGB(255, 60, 0)
	}
}

local function getBiome(stage)
	local idx = math.clamp(math.ceil(stage / 30), 1, 5)
	return BIOMES[idx]
end

-- ==========================================
-- 5. SISTEMAS DINÁMICOS (TRAMPAS, PUERTAS, ARMARIOS Y MONSTRUOS 3D)
-- ==========================================
local movingHazards = {}
local flickeringLights = {}
local activeEnemies = {}

local function createLocker(position)
	local locker = makeWall(Vector3.new(4.5, 8.5, 4), position + Vector3.new(0, 4.25, 0), Enum.Material.Metal, Color3.fromRGB(50, 60, 70))
	locker.Name = "HidingLocker"

	makeWall(Vector3.new(3.5, 1.5, 0.2), locker.Position + Vector3.new(0, 2, 2), Enum.Material.Metal, Color3.fromRGB(25, 30, 35))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Armario de Seguridad"
	prompt.HoldDuration = 0.15
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
			hrp.CFrame = locker.CFrame * CFrame.new(0, 0, 5)
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

local function createMonster3D(centerPos, patrolRadius, isBoss, biome, speed)
	local scale = isBoss and 2.2 or 1.15
	local root = Instance.new("Part")
	root.Name = isBoss and "BossMonster" or "StalkerMonster"
	root.Size = Vector3.new(3 * scale, 6 * scale, 2 * scale)
	root.Position = centerPos + Vector3.new(0, (3 * scale) + 1, 0)
	root.Anchored = true
	root.CanCollide = false
	root.Material = Enum.Material.Slate
	root.Color = Color3.fromRGB(20, 20, 25)
	root.Parent = enemiesFolder

	local head = Instance.new("Part")
	head.Size = Vector3.new(2.2 * scale, 2.2 * scale, 2.2 * scale)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(220, 210, 200)
	head.Parent = root

	local eyeLeft = Instance.new("Part")
	eyeLeft.Size = Vector3.new(0.4 * scale, 0.3 * scale, 0.2 * scale)
	eyeLeft.Anchored = true
	eyeLeft.CanCollide = false
	eyeLeft.Material = Enum.Material.Neon
	eyeLeft.Color = biome.MonsterColor
	eyeLeft.Parent = root

	local eyeRight = eyeLeft:Clone()
	eyeRight.Parent = root

	local blade = Instance.new("Part")
	blade.Size = Vector3.new(0.6 * scale, 4.5 * scale, 1.2 * scale)
	blade.Anchored = true
	blade.CanCollide = false
	blade.Material = Enum.Material.Neon
	blade.Color = biome.MonsterColor
	blade.Parent = root

	local auraLight = Instance.new("PointLight")
	auraLight.Color = biome.MonsterColor
	auraLight.Range = isBoss and 45 or 26
	auraLight.Brightness = 3.5
	auraLight.Parent = root

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 130, 0, 36)
	bg.StudsOffset = Vector3.new(0, (4 * scale) + 1.5, 0)
	bg.MaxDistance = 75
	bg.Parent = root

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Text = isBoss and "💀 JEFE DEL BIOMA 💀" or "🔪 ASESINO"
	title.TextColor3 = Color3.fromRGB(255, 45, 45)
	title.TextStrokeTransparency = 0
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = bg

	local function onTouch(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and not char:GetAttribute("IsHiding") then
			hum.Health = 0
		end
	end
	root.Touched:Connect(onTouch)
	blade.Touched:Connect(onTouch)

	table.insert(activeEnemies, {
		Root = root,
		Head = head,
		EyeL = eyeLeft,
		EyeR = eyeRight,
		Blade = blade,
		Scale = scale,
		Origin = root.Position,
		Radius = patrolRadius,
		IsBoss = isBoss,
		Speed = speed or (isBoss and 15.5 or 13),
		LastWave = tick()
	})
end

local function buildStageEnvironment(stage, zStart, length, biome)
	local zCenter = zStart - (length / 2)

	-- Suelo mortal de fosa terrestre debajo del nivel
	local pit = makeWall(
		Vector3.new(38, 2, length),
		Vector3.new(0, -10, zCenter),
		biome.PitMat,
		biome.PitColor
	)
	pit.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)

	if biome.Indoor then
		makeWall(Vector3.new(2, 26, length), Vector3.new(-18, 2, zCenter), biome.WallMat, biome.WallColor)
		makeWall(Vector3.new(2, 26, length), Vector3.new(18, 2, zCenter), biome.WallMat, biome.WallColor)
		makeWall(Vector3.new(38, 2, length), Vector3.new(0, 15, zCenter), Enum.Material.Concrete, Color3.fromRGB(35, 35, 40))

		local lamp = makeWall(Vector3.new(4, 0.5, 4), Vector3.new(0, 13.8, zCenter), Enum.Material.Neon, biome.LightColor)
		local pLight = Instance.new("PointLight")
		pLight.Range = 55
		pLight.Brightness = 2.4
		pLight.Color = biome.LightColor
		pLight.Parent = lamp

		if stage % 2 == 0 then
			table.insert(flickeringLights, {Lamp = lamp, Light = pLight, BaseBrightness = 2.4})
		end
	else
		makeWall(Vector3.new(6, 18, length), Vector3.new(-20, -2, zCenter), biome.WallMat, biome.WallColor)
		makeWall(Vector3.new(6, 18, length), Vector3.new(20, -2, zCenter), biome.WallMat, biome.WallColor)

		for t = 1, 2 do
			local tz = zStart - (t * (length / 3))
			local side = (t % 2 == 0) and 14 or -14
			makeWall(Vector3.new(2.5, 18, 2.5), Vector3.new(side, 0, tz), Enum.Material.Wood, Color3.fromRGB(45, 35, 30))
			local lantern = makeWall(Vector3.new(1.5, 1.5, 1.5), Vector3.new(side * 0.7, 7, tz), Enum.Material.Neon, biome.LightColor)
			local lLight = Instance.new("PointLight")
			lLight.Range = 50
			lLight.Brightness = 2.2
			lLight.Color = biome.LightColor
			lLight.Parent = lantern
		end
	end
end

-- ==========================================
-- 6. GENERACIÓN DE LOS 150 NIVELES CON DESAFÍOS REALES
-- ==========================================
local currentZ = -18
local STAGE_LENGTH = 72

for stage = 1, 150 do
	local biome = getBiome(stage)
	buildStageEnvironment(stage, currentZ, STAGE_LENGTH, biome)

	local cp = makeWall(Vector3.new(18, 2, 14), Vector3.new(0, 0, currentZ), biome.FloorMat, biome.FloorColor)
	cp.Name = tostring(stage)
	cp.Parent = checkpointsFolder

	local neonPad = makeWall(Vector3.new(6, 0.3, 6), cp.Position + Vector3.new(0, 1.1, 0), Enum.Material.Neon, Color3.fromRGB(0, 220, 110))
	neonPad.CanCollide = false
	neonPad.Parent = cp

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 160, 0, 55)
	bg.StudsOffset = Vector3.new(0, 5.5, 0)
	bg.MaxDistance = 90
	bg.Parent = cp

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "ETAPA " .. stage .. " / 150\n" .. biome.Name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bg

	createLocker(cp.Position + Vector3.new(-6.5, 1, -2))

	local challengeType = (stage - 1) % 5

	if stage % 30 == 0 then
		-- Arena de Jefe Final del Bioma
		local arena = makeWall(
			Vector3.new(30, 2, STAGE_LENGTH - 14),
			Vector3.new(0, 0, currentZ - (STAGE_LENGTH / 2)),
			biome.FloorMat,
			biome.FloorColor
		)
		createLocker(arena.Position + Vector3.new(11, 1, 10))
		createLocker(arena.Position + Vector3.new(-11, 1, -10))
		createMonster3D(arena.Position, 12, true, biome, 16)

	elseif challengeType == 0 then
		-- Desafío 1: Pasillo del Asesino (Persecución + Escondite desde el Nivel 1)
		local corridor = makeWall(
			Vector3.new(14, 2, STAGE_LENGTH - 14),
			Vector3.new(0, 0, currentZ - (STAGE_LENGTH / 2)),
			biome.FloorMat,
			biome.FloorColor
		)
		createLocker(corridor.Position + Vector3.new(4.5, 1, 0))
		makeWall(Vector3.new(6, 4, 1.5), corridor.Position + Vector3.new(-3, 3, 12), Enum.Material.Metal, Color3.fromRGB(90, 25, 25))
		makeWall(Vector3.new(6, 4, 1.5), corridor.Position + Vector3.new(3, 3, -12), Enum.Material.Metal, Color3.fromRGB(90, 25, 25))
		createMonster3D(corridor.Position, 5, false, biome, 13.5)

	elseif challengeType == 1 then
		-- Desafío 2: Guillotinas y Sierras Oscilantes
		makeWall(
			Vector3.new(8, 2, STAGE_LENGTH - 14),
			Vector3.new(0, 0, currentZ - (STAGE_LENGTH / 2)),
			biome.FloorMat,
			biome.FloorColor
		)

		for s = 1, 3 do
			local sawZ = currentZ - 14 - (s * 14)
			local saw = makeWall(Vector3.new(5, 5, 1), Vector3.new(0, 3.5, sawZ), Enum.Material.Neon, Color3.fromRGB(255, 30, 30))
			saw.CanCollide = false
			saw.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum then hum.Health = 0 end
			end)
			table.insert(movingHazards, {
				Part = saw,
				Origin = saw.Position,
				Amplitude = 6.5,
				Speed = 2.5 + (s * 0.5),
				Phase = s * 1.2
			})
		end

	elseif challengeType == 2 then
		-- Desafío 3: Puente de Tablas Podridas
		local rows = 4
		local spacing = (STAGE_LENGTH - 14) / (rows + 1)

		for r = 1, rows do
			local rowZ = currentZ - 7 - (r * spacing)
			local leftIsSafe = ((stage + r) % 2 == 0)

			local leftPad = makeWall(Vector3.new(6.5, 1.2, 8), Vector3.new(-4.5, 0, rowZ), Enum.Material.WoodPlanks, leftIsSafe and Color3.fromRGB(110, 75, 50) or Color3.fromRGB(65, 40, 35))
			local rightPad = makeWall(Vector3.new(6.5, 1.2, 8), Vector3.new(4.5, 0, rowZ), Enum.Material.WoodPlanks, (not leftIsSafe) and Color3.fromRGB(110, 75, 50) or Color3.fromRGB(65, 40, 35))

			local fakePad = leftIsSafe and rightPad or leftPad
			fakePad.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and fakePad.CanCollide then
					fakePad.CanCollide = false
					fakePad.Transparency = 0.65
					task.delay(2.5, function()
						if fakePad and fakePad.Parent then
							fakePad.CanCollide = true
							fakePad.Transparency = 0
						end
					end)
				end
			end)
		end

	elseif challengeType == 3 then
		-- Desafío 4: Puerta Cerrada con Válvula + Monstruo Acechando
		local hall = makeWall(
			Vector3.new(16, 2, STAGE_LENGTH - 14),
			Vector3.new(0, 0, currentZ - (STAGE_LENGTH / 2)),
			biome.FloorMat,
			biome.FloorColor
		)

		local gate = makeWall(Vector3.new(16, 12, 1.5), Vector3.new(0, 7, currentZ - STAGE_LENGTH + 10), Enum.Material.CorrodedMetal, Color3.fromRGB(60, 50, 50))
		local valve = makeWall(Vector3.new(2.5, 5, 2.5), hall.Position + Vector3.new(-5.5, 3.5, 4), Enum.Material.Neon, Color3.fromRGB(220, 40, 40))

		local gatePrompt = Instance.new("ProximityPrompt")
		gatePrompt.ActionText = "Girar Válvula (Abrir Reja)"
		gatePrompt.ObjectText = "Mecanismo de Escape"
		gatePrompt.HoldDuration = 0.5
		gatePrompt.MaxActivationDistance = 10
		gatePrompt.Parent = valve

		gatePrompt.Triggered:Connect(function()
			gate.CanCollide = false
			gate.Transparency = 0.75
			valve.Color = Color3.fromRGB(40, 220, 80)
			task.delay(6, function()
				if gate and gate.Parent then
					gate.CanCollide = true
					gate.Transparency = 0
					valve.Color = Color3.fromRGB(220, 40, 40)
				end
			end)
		end)

		createLocker(hall.Position + Vector3.new(5.5, 1, -4))
		createMonster3D(hall.Position + Vector3.new(0, 0, -6), 5, false, biome, 13)

	else
		-- Desafío 5: Salto de Vigas con Trampas Móviles
		for i = 1, 4 do
			local stepZ = currentZ - 8 - (i * 11.5)
			local xOff = (i % 2 == 0) and 3.5 or -3.5
			local pad = makeWall(Vector3.new(8, 1.5, 8.5), Vector3.new(xOff, 0, stepZ), biome.FloorMat, biome.FloorColor)

			local laser = makeWall(Vector3.new(8, 0.8, 1), pad.Position + Vector3.new(0, 1.2, 0), Enum.Material.Neon, biome.MonsterColor)
			laser.CanCollide = false
			laser.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum then hum.Health = 0 end
			end)
			table.insert(movingHazards, {
				Part = laser,
				Origin = laser.Position,
				Amplitude = 3,
				Speed = 2,
				Phase = i,
				MoveZ = true
			})
		end
	end

	currentZ = currentZ - STAGE_LENGTH

	if stage % 35 == 0 then
		task.wait()
	end
end

-- ==========================================
-- 7. SANTUARIO DE VICTORIA EN EL NIVEL 150
-- ==========================================
local winPlatform = makeWall(Vector3.new(34, 2, 34), Vector3.new(0, 0, currentZ), Enum.Material.Neon, Color3.fromRGB(255, 215, 0))
winPlatform.Name = "VictoryPlatform"

-- ==========================================
-- 8. GESTIÓN DE JUGADORES Y CHECKPOINTS
-- ==========================================
local function teleportToStage(player, character)
	task.wait(0.1)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local stageVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
	local stageNum = (stageVal and stageVal.Value) or 1
	local cp = checkpointsFolder:FindFirstChild(tostring(stageNum)) or checkpointsFolder:FindFirstChild("1")

	if cp then
		hrp.CFrame = cp.CFrame + Vector3.new(0, 4.5, 0)
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

for _, cp in ipairs(checkpointsFolder:GetChildren()) do
	if cp:IsA("BasePart") then
		local stageNum = tonumber(cp.Name)
		if stageNum then
			cp.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player and player:FindFirstChild("leaderstats") then
					local stageVal = player.leaderstats:FindFirstChild("Stage")
					if stageVal and stageNum > stageVal.Value and stageNum <= stageVal.Value + 2 then
						stageVal.Value = stageNum
					end
				end
			end)
		end
	end
end

-- ==========================================
-- 9. BUCLE MAESTRO: IA DE MONSTRUOS 3D, SIERRAS Y LUCES
-- ==========================================
RunService.Heartbeat:Connect(function(dt)
	local now = tick()

	for _, h in ipairs(movingHazards) do
		if h.Part and h.Part.Parent then
			local offset = math.sin(now * h.Speed + h.Phase) * h.Amplitude
			if h.MoveZ then
				h.Part.Position = h.Origin + Vector3.new(0, 0, offset)
			else
				h.Part.Position = h.Origin + Vector3.new(offset, 0, 0)
			end
		end
	end

	if #flickeringLights > 0 and math.random() < 0.08 then
		local pick = flickeringLights[math.random(1, #flickeringLights)]
		if pick and pick.Light and pick.Lamp then
			local off = (math.random() < 0.35)
			pick.Light.Brightness = off and 0.4 or pick.BaseBrightness
			pick.Lamp.Transparency = off and 0.6 or 0
		end
	end

	for _, m in ipairs(activeEnemies) do
		local root = m.Root
		if root and root.Parent then
			local targetPos = nil
			local shortestDist = 34

			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and not char:GetAttribute("IsHiding") then
					local dist = (hrp.Position - m.Origin).Magnitude
					if dist < shortestDist then
						shortestDist = dist
						targetPos = hrp.Position
					end
				end
			end

			local newPos = root.Position
			local lookAt = newPos + Vector3.new(0, 0, 1)

			if targetPos then
				local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
				local dir = (flatTarget - root.Position)
				if dir.Magnitude > 0.5 then
					newPos = root.Position + dir.Unit * m.Speed * dt
					lookAt = flatTarget
				end
			else
				local zWalk = math.cos(now * 1.8) * (m.Radius * 2)
				local xWalk = math.sin(now * 2.5) * m.Radius
				newPos = m.Origin + Vector3.new(xWalk, 0, zWalk)
				lookAt = newPos + Vector3.new(0, 0, (math.sin(now * 1.8) >= 0 and -1 or 1))
			end

			local cf = CFrame.lookAt(newPos, lookAt)
			root.CFrame = cf

			local s = m.Scale
			m.Head.CFrame = cf * CFrame.new(0, 3.8 * s, 0)
			m.EyeL.CFrame = cf * CFrame.new(-0.5 * s, 4 * s, -1.1 * s)
			m.EyeR.CFrame = cf * CFrame.new(0.5 * s, 4 * s, -1.1 * s)
			local swing = math.sin(now * 8) * 0.6
			m.Blade.CFrame = cf * CFrame.new(1.8 * s, 1 * s, -1.2 * s) * CFrame.Angles(swing, 0, 0)

			if m.IsBoss and (now - m.LastWave > 4) then
				m.LastWave = now
				local wave = Instance.new("Part")
				wave.Size = Vector3.new(28, 1.4, 2)
				wave.Position = Vector3.new(0, 1.2, root.Position.Z)
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
					for i = 1, 28 do
						wave.Position = wave.Position + Vector3.new(0, 0, 1.3)
						task.wait(0.03)
					end
					wave:Destroy()
				end)
			end
		end
	end
end)
