-- LevelGenerator.server.lua (Mundo Abierto Optimizado, Monstruos Avatar R6 y Súper Tienda)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local VIP_GAMEPASS_ID = 2052196520 -- Tu Pase VIP oficial de 250 Robux
local SKIP_STAGE_PRODUCT_ID = 0 -- Cambia el 0 si tienes un ID de producto para saltar nivel

-- Función auxiliar para sonidos 3D optimizados
local function add3DSound(parent, soundId, volume, pitch, looped, maxDist)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(soundId)
	s.Volume = volume or 1
	s.PlaybackSpeed = pitch or 1
	s.Looped = looped or false
	s.RollOffMaxDistance = maxDist or 60
	s.RollOffMinDistance = 8
	s.RollOffMode = Enum.RollOffMode.Linear
	s.Parent = parent
	if looped then
		s:Play()
	end
	return s
end

-- ==========================================
-- 1. ATMÓSFERA ABIERTA EN LA TIERRA (CREPÚSCULO SANGRIENTO, CERO PAREDES)
-- ==========================================
local function setupOpenEarthAtmosphere()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end

	-- Hora crepuscular en la Tierra (17:45) para ver el horizonte, nubes y colores sin oscuridad espacial
	Lighting.ClockTime = 17.75
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(95, 80, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 90, 95)
	Lighting.FogStart = 80
	Lighting.FogEnd = 450
	Lighting.FogColor = Color3.fromRGB(75, 45, 50)

	local sky = Instance.new("Sky")
	sky.Name = "EarthTwilightSky"
	sky.StarCount = 0
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.35
	atmo.Offset = 0.2
	atmo.Color = Color3.fromRGB(110, 60, 65)
	atmo.Decay = Color3.fromRGB(55, 30, 35)
	atmo.Haze = 2.5
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.04
	cc.Contrast = 0.18
	cc.Saturation = 0.1
	cc.Parent = Lighting
end

setupOpenEarthAtmosphere()
task.delay(2, setupOpenEarthAtmosphere)

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

local function makePart(size, pos, mat, col, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Material = mat
	p.Color = col
	p.CastShadow = false -- Optimización clave para 60 FPS en iPhone
	p.Parent = parent or mapFolder
	return p
end

-- ==========================================
-- 3. PLAZA DE INICIO AL AIRE LIBRE
-- ==========================================
local safeLobby = makePart(Vector3.new(42, 3, 42), Vector3.new(0, 0, 0), Enum.Material.Cobblestone, Color3.fromRGB(95, 95, 100))
safeLobby.Name = "SafeStartLobby"

-- Barandillas bajas decorativas (no tapan la cámara)
makePart(Vector3.new(2, 3.5, 42), Vector3.new(-20, 3, 0), Enum.Material.Brick, Color3.fromRGB(60, 55, 60))
makePart(Vector3.new(2, 3.5, 42), Vector3.new(20, 3, 0), Enum.Material.Brick, Color3.fromRGB(60, 55, 60))
makePart(Vector3.new(42, 3.5, 2), Vector3.new(0, 3, 20), Enum.Material.Brick, Color3.fromRGB(60, 55, 60))

local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.Position = Vector3.new(0, 2, 8)
spawnLocation.Anchored = true
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color = Color3.fromRGB(200, 40, 40)
spawnLocation.Parent = Workspace

-- ==========================================
-- 4. DEFINICIÓN DE LOS 5 BIOMAS ABIERTOS
-- ==========================================
local BIOMES = {
	[1] = {
		Name = "Ruinas del Manicomio",
		FloorMat = Enum.Material.Slate,
		FloorColor = Color3.fromRGB(90, 95, 105),
		AccentColor = Color3.fromRGB(160, 35, 35),
		MonsterShirt = Color3.fromRGB(120, 25, 25),
		MonsterFace = "rbxassetid://7074764", -- Cara terrorífica clásica
		LightColor = Color3.fromRGB(255, 180, 140)
	},
	[2] = {
		Name = "Puentes Tóxicos",
		FloorMat = Enum.Material.CorrodedMetal,
		FloorColor = Color3.fromRGB(70, 85, 70),
		AccentColor = Color3.fromRGB(60, 230, 50),
		MonsterShirt = Color3.fromRGB(35, 110, 45),
		MonsterFace = "rbxassetid://173789324", -- Rostro mutante
		LightColor = Color3.fromRGB(150, 255, 150)
	},
	[3] = {
		Name = "Jardines Sangrientos",
		FloorMat = Enum.Material.WoodPlanks,
		FloorColor = Color3.fromRGB(95, 55, 45),
		AccentColor = Color3.fromRGB(220, 25, 55),
		MonsterShirt = Color3.fromRGB(70, 15, 25),
		MonsterFace = "rbxassetid://7074764",
		LightColor = Color3.fromRGB(255, 140, 140)
	},
	[4] = {
		Name = "Cañón del Bosque Maldito",
		FloorMat = Enum.Material.Grass,
		FloorColor = Color3.fromRGB(55, 80, 50),
		AccentColor = Color3.fromRGB(160, 50, 240),
		MonsterShirt = Color3.fromRGB(50, 25, 80),
		MonsterFace = "rbxassetid://173789324",
		LightColor = Color3.fromRGB(200, 160, 255)
	},
	[5] = {
		Name = "Volcán del Purgatorio",
		FloorMat = Enum.Material.Basalt,
		FloorColor = Color3.fromRGB(55, 45, 50),
		AccentColor = Color3.fromRGB(255, 85, 0),
		MonsterShirt = Color3.fromRGB(180, 40, 0),
		MonsterFace = "rbxassetid://7074764",
		LightColor = Color3.fromRGB(255, 130, 50)
	}
}

local function getBiome(stage)
	local idx = math.clamp(math.ceil(stage / 30), 1, 5)
	return BIOMES[idx]
end

-- ==========================================
-- 5. MONSTRUOS CALIDAD AVATAR (HUMANOID R6 + CARA DE TERROR)
-- ==========================================
local movingHazards = {}
local activeEnemies = {}

local function createLocker(position)
	local locker = makePart(Vector3.new(4.5, 8.5, 4), position + Vector3.new(0, 4.25, 0), Enum.Material.Metal, Color3.fromRGB(55, 65, 75))
	locker.Name = "HidingLocker"
	makePart(Vector3.new(3.5, 1.5, 0.3), locker.Position + Vector3.new(0, 2, 2), Enum.Material.Neon, Color3.fromRGB(0, 220, 255))

	local doorSound = add3DSound(locker, 9114074523, 0.9, 0.9, false, 45)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Cabina de Refugio"
	prompt.HoldDuration = 0.1
	prompt.MaxActivationDistance = 10
	prompt.Parent = locker

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		doorSound:Play()
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

-- Constructor de Monstruo con calidad de Personaje R6 y Cara de Terror
local function createAvatarMonster(centerPos, patrolRadius, isBoss, biome, speed)
	local s = isBoss and 2.1 or 1.15
	local npcModel = Instance.new("Model")
	npcModel.Name = isBoss and "💀 JEFE DEL BIOMA 💀" or "🔪 ASESINO"
	npcModel.Parent = enemiesFolder

	-- Humanoid para que Roblox suavice los bordes como un jugador real
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = npcModel

	-- Torso
	local torso = makePart(Vector3.new(2 * s, 2 * s, 1 * s), centerPos + Vector3.new(0, 3 * s, 0), Enum.Material.SmoothPlastic, biome.MonsterShirt, npcModel)
	torso.Name = "Torso"
	torso.CanCollide = false
	npcModel.PrimaryPart = torso

	-- Cabeza con forma real de Avatar Roblox (SpecialMesh Head)
	local head = makePart(Vector3.new(2 * s, 1 * s, 1 * s), torso.Position + Vector3.new(0, 1.5 * s, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(235, 225, 220), npcModel)
	head.Name = "Head"
	head.CanCollide = false

	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	-- Textura de Cara de Terror en la parte frontal de la cabeza
	local faceDecal = Instance.new("Decal")
	faceDecal.Name = "face"
	faceDecal.Face = Enum.NormalId.Front
	faceDecal.Texture = biome.MonsterFace
	faceDecal.Parent = head

	-- Ojos brillantes de neón sobresalientes para que den miedo de lejos
	local eyeL = makePart(Vector3.new(0.28 * s, 0.22 * s, 0.2 * s), head.Position, Enum.Material.Neon, biome.AccentColor, npcModel)
	eyeL.CanCollide = false
	local eyeR = eyeL:Clone()
	eyeR.Parent = npcModel

	-- Extremidades articuladas (Brazos y Piernas igual a un jugador R6)
	local armL = makePart(Vector3.new(1 * s, 2 * s, 1 * s), torso.Position, Enum.Material.SmoothPlastic, Color3.fromRGB(215, 205, 200), npcModel)
	armL.Name = "Left Arm"
	armL.CanCollide = false

	local armR = armL:Clone()
	armR.Name = "Right Arm"
	armR.Parent = npcModel

	local legL = makePart(Vector3.new(1 * s, 2 * s, 1 * s), torso.Position, Enum.Material.SmoothPlastic, Color3.fromRGB(30, 30, 35), npcModel)
	legL.Name = "Left Leg"
	legL.CanCollide = false

	local legR = legL:Clone()
	legR.Name = "Right Leg"
	legR.Parent = npcModel

	-- Machete / Guadaña sangrienta en la mano derecha
	local weapon = makePart(Vector3.new(0.35 * s, 3.8 * s, 0.9 * s), torso.Position, Enum.Material.Neon, biome.AccentColor, npcModel)
	weapon.Name = "BloodyBlade"
	weapon.CanCollide = false

	-- Luz de aura terrorífica
	local light = Instance.new("PointLight")
	light.Color = biome.AccentColor
	light.Range = isBoss and 38 or 22
	light.Brightness = 2.5
	light.Parent = torso

	-- Sonido 3D del monstruo
	add3DSound(torso, 9114397505, isBoss and 1.0 or 0.7, isBoss and 0.45 or 0.65, true, 65)
	local roarSound = add3DSound(torso, 9114221735, 1.2, isBoss and 0.55 or 0.75, false, 80)

	-- Daño al tocar al jugador (respeta el Escudo y el Armario)
	local function onHit(hit)
		local char = hit.Parent
		local pHum = char and char:FindFirstChildOfClass("Humanoid")
		if pHum and pHum.Health > 0 and not char:GetAttribute("IsHiding") and not torso:GetAttribute("Stunned") then
			if char:GetAttribute("HasShield") then
				char:SetAttribute("HasShield", false)
				local ff = char:FindFirstChildOfClass("ForceField")
				if ff then ff:Destroy() end
				torso:SetAttribute("Stunned", true)
				task.delay(3, function()
					if torso then torso:SetAttribute("Stunned", false) end
				end)
				return
			end
			roarSound:Play()
			pHum.Health = 0
		end
	end

	torso.Touched:Connect(onHit)
	weapon.Touched:Connect(onHit)

	table.insert(activeEnemies, {
		Model = npcModel,
		Torso = torso,
		Head = head,
		EyeL = eyeL,
		EyeR = eyeR,
		ArmL = armL,
		ArmR = armR,
		LegL = legL,
		LegR = legR,
		Weapon = weapon,
		Roar = roarSound,
		Scale = s,
		Origin = torso.Position,
		Radius = patrolRadius,
		IsBoss = isBoss,
		Speed = speed or (isBoss and 15.5 or 13),
		LastWave = tick(),
		LastRoar = tick()
	})
end

-- ==========================================
-- 6. GENERACIÓN DE LOS 150 NIVELES ABIERTOS Y OPTIMIZADOS
-- ==========================================
local currentZ = -20
local STAGE_LENGTH = 70

-- Gran río de lava/abismo terrestre continuo debajo de todo el mapa (1 sola pieza cada 15 etapas para máxima optimización)
for chunk = 1, 10 do
	local chunkLen = STAGE_LENGTH * 15
	local zCenter = -20 - ((chunk - 0.5) * chunkLen)
	local b = getBiome((chunk - 1) * 15 + 1)
	local abyss = makePart(Vector3.new(160, 2, chunkLen), Vector3.new(0, -18, zCenter), Enum.Material.Neon, b.AccentColor)
	abyss.Transparency = 0.25
	abyss.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end)
end

for stage = 1, 150 do
	local biome = getBiome(stage)
	local zCenter = currentZ - (STAGE_LENGTH / 2)

	-- Faroles terrestres en los bordes cada 2 etapas (Sin paredes ni techos para vista abierta)
	if stage % 2 == 1 then
		local side = (stage % 4 == 1) and -11 or 11
		makePart(Vector3.new(1.2, 10, 1.2), Vector3.new(side, 5, currentZ), Enum.Material.Metal, Color3.fromRGB(40, 40, 45))
		local lantern = makePart(Vector3.new(2, 2, 2), Vector3.new(side, 10.5, currentZ), Enum.Material.Neon, biome.LightColor)
		local pl = Instance.new("PointLight")
		pl.Range = 45
		pl.Brightness = 2
		pl.Color = biome.LightColor
		pl.Parent = lantern
	end

	-- Plataforma de Checkpoint abierta
	local cp = makePart(Vector3.new(18, 2, 14), Vector3.new(0, 0, currentZ), biome.FloorMat, biome.FloorColor, checkpointsFolder)
	cp.Name = tostring(stage)

	local neonPad = makePart(Vector3.new(6, 0.3, 6), cp.Position + Vector3.new(0, 1.1, 0), Enum.Material.Neon, Color3.fromRGB(0, 230, 115), cp)
	neonPad.CanCollide = false

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 160, 0, 50)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.MaxDistance = 85
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
		-- Arena abierta de Jefe Final del Bioma
		local arena = makePart(Vector3.new(32, 2, STAGE_LENGTH - 14), Vector3.new(0, 0, zCenter), biome.FloorMat, biome.FloorColor)
		createLocker(arena.Position + Vector3.new(12, 1, 10))
		createLocker(arena.Position + Vector3.new(-12, 1, -10))
		createAvatarMonster(arena.Position, 12, true, biome, 16)

	elseif challengeType == 0 then
		-- Desafío 1: Puente del Asesino con barricadas bajas
		local bridge = makePart(Vector3.new(14, 2, STAGE_LENGTH - 14), Vector3.new(0, 0, zCenter), biome.FloorMat, biome.FloorColor)
		createLocker(bridge.Position + Vector3.new(4.5, 1, 0))
		makePart(Vector3.new(5.5, 3.5, 1.5), bridge.Position + Vector3.new(-3, 2.7, 12), Enum.Material.Metal, biome.AccentColor)
		makePart(Vector3.new(5.5, 3.5, 1.5), bridge.Position + Vector3.new(3, 2.7, -12), Enum.Material.Metal, biome.AccentColor)
		createAvatarMonster(bridge.Position, 5, false, biome, 13.5)

	elseif challengeType == 1 then
		-- Desafío 2: Péndulos y Sierras Giratorias Abiertas
		makePart(Vector3.new(8.5, 2, STAGE_LENGTH - 14), Vector3.new(0, 0, zCenter), biome.FloorMat, biome.FloorColor)

		for s = 1, 3 do
			local sawZ = currentZ - 13 - (s * 13)
			local saw = makePart(Vector3.new(5, 5, 0.8), Vector3.new(0, 3.5, sawZ), Enum.Material.Neon, biome.AccentColor)
			saw.CanCollide = false
			saw.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and not hit.Parent:GetAttribute("HasShield") then hum.Health = 0 end
			end)
			table.insert(movingHazards, {
				Part = saw,
				Origin = saw.Position,
				Amplitude = 6.5,
				Speed = 2.5 + (s * 0.45),
				Phase = s * 1.2
			})
		end

	elseif challengeType == 2 then
		-- Desafío 3: Puente Colgante de Tablas Podridas
		local rows = 4
		local spacing = (STAGE_LENGTH - 14) / (rows + 1)

		for r = 1, rows do
			local rowZ = currentZ - 7 - (r * spacing)
			local leftIsSafe = ((stage + r) % 2 == 0)

			local leftPad = makePart(Vector3.new(6.5, 1.2, 8), Vector3.new(-4.5, 0, rowZ), Enum.Material.WoodPlanks, leftIsSafe and Color3.fromRGB(120, 80, 55) or Color3.fromRGB(70, 42, 35))
			local rightPad = makePart(Vector3.new(6.5, 1.2, 8), Vector3.new(4.5, 0, rowZ), Enum.Material.WoodPlanks, (not leftIsSafe) and Color3.fromRGB(120, 80, 55) or Color3.fromRGB(70, 42, 35))

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
		-- Desafío 4: Reja de Hierro + Válvula + Asesino R6
		local hall = makePart(Vector3.new(16, 2, STAGE_LENGTH - 14), Vector3.new(0, 0, zCenter), biome.FloorMat, biome.FloorColor)
		local gate = makePart(Vector3.new(16, 10, 1.2), Vector3.new(0, 6, currentZ - STAGE_LENGTH + 10), Enum.Material.CorrodedMetal, Color3.fromRGB(60, 50, 50))
		local valve = makePart(Vector3.new(2.5, 4.5, 2.5), hall.Position + Vector3.new(-5.5, 3.2, 4), Enum.Material.Neon, Color3.fromRGB(230, 40, 40))

		local gatePrompt = Instance.new("ProximityPrompt")
		gatePrompt.ActionText = "Girar Válvula (Abrir Paso)"
		gatePrompt.ObjectText = "Mecanismo Antiguo"
		gatePrompt.HoldDuration = 0.4
		gatePrompt.MaxActivationDistance = 10
		gatePrompt.Parent = valve

		gatePrompt.Triggered:Connect(function()
			gate.CanCollide = false
			gate.Transparency = 0.75
			valve.Color = Color3.fromRGB(40, 230, 80)
			task.delay(6, function()
				if gate and gate.Parent then
					gate.CanCollide = true
					gate.Transparency = 0
					valve.Color = Color3.fromRGB(230, 40, 40)
				end
			end)
		end)

		createLocker(hall.Position + Vector3.new(5.5, 1, -4))
		createAvatarMonster(hall.Position + Vector3.new(0, 0, -6), 5, false, biome, 13)

	else
		-- Desafío 5: Plataformas Flotantes con Barras Láser Móviles
		for i = 1, 4 do
			local stepZ = currentZ - 8 - (i * 11)
			local xOff = (i % 2 == 0) and 3.5 or -3.5
			local pad = makePart(Vector3.new(8, 1.5, 8.5), Vector3.new(xOff, 0, stepZ), biome.FloorMat, biome.FloorColor)

			local laser = makePart(Vector3.new(8, 0.8, 1), pad.Position + Vector3.new(0, 1.2, 0), Enum.Material.Neon, biome.AccentColor)
			laser.CanCollide = false
			laser.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and not hit.Parent:GetAttribute("HasShield") then hum.Health = 0 end
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
	if stage % 50 == 0 then task.wait() end
end

local winPlatform = makePart(Vector3.new(36, 2, 36), Vector3.new(0, 0, currentZ), Enum.Material.Neon, Color3.fromRGB(255, 215, 0))
winPlatform.Name = "VictoryPlatform"

-- ==========================================
-- 7. HERRAMIENTAS ÉPICAS Y SÚPER TIENDA LLAMATIVA
-- ==========================================
local function giveCrucifixTool(player)
	local bp = player:FindFirstChildOfClass("Backpack")
	if not bp or bp:FindFirstChild("Crucifijo Sagrado") then return end

	local tool = Instance.new("Tool")
	tool.Name = "Crucifijo Sagrado"
	tool.ToolTip = "Toca para congelar a los monstruos cercanos"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 3.2, 0.4)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(255, 215, 80)
	handle.Parent = tool

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 230, 120)
	light.Range = 20
	light.Brightness = 2
	light.Parent = handle

	local sound = add3DSound(handle, 9114074523, 1.2, 1.5, false, 50)

	tool.Activated:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		sound:Play()

		-- Congelar a todos los monstruos en un radio de 45 studs por 5 segundos
		for _, m in ipairs(activeEnemies) do
			if m.Torso and m.Torso.Parent then
				local dist = (m.Torso.Position - hrp.Position).Magnitude
				if dist < 45 then
					m.Torso:SetAttribute("Stunned", true)
					m.EyeL.Color = Color3.fromRGB(0, 220, 255)
					m.EyeR.Color = Color3.fromRGB(0, 220, 255)
					task.delay(5, function()
						if m.Torso and m.Torso.Parent then
							m.Torso:SetAttribute("Stunned", false)
							m.EyeL.Color = Color3.fromRGB(255, 30, 30)
							m.EyeR.Color = Color3.fromRGB(255, 30, 30)
						end
					end)
				end
			end
		end
	end)

	tool.Parent = bp
end

local function buildMegaShopGui(player)
	local pGui = player:WaitForChild("PlayerGui", 10)
	if not pGui or pGui:FindFirstChild("MegaHorrorShop") then return end

	local sg = Instance.new("ScreenGui")
	sg.Name = "MegaHorrorShop"
	sg.ResetOnSpawn = false
	sg.Parent = pGui

	-- Botón Flotante Llamativo para abrir la Súper Tienda
	local openBtn = Instance.new("TextButton")
	openBtn.Name = "OpenShopButton"
	openBtn.Size = UDim2.new(0, 155, 0, 46)
	openBtn.Position = UDim2.new(0, 16, 0.42, 0)
	openBtn.BackgroundColor3 = Color3.fromRGB(220, 30, 55)
	openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	openBtn.Font = Enum.Font.GothamBlack
	openBtn.TextScaled = true
	openBtn.Text = "🔥 SÚPER TIENDA"
	openBtn.Parent = sg

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = openBtn

	-- Ventana Principal de la Tienda
	local frame = Instance.new("Frame")
	frame.Name = "ShopWindow"
	frame.Size = UDim2.new(0, 440, 0, 310)
	frame.Position = UDim2.new(0.5, -220, 0.5, -155)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	frame.Visible = false
	frame.Parent = sg

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 16)
	fCorner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 42)
	title.Position = UDim2.new(0, 16, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "⚡ ARSENAL DE SUPERVIVENCIA Y VIP ⚡"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextScaled = true
	closeBtn.Parent = frame

	openBtn.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)
	closeBtn.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	local ITEMS = {
		{Name = "👑 PASE REY VIP (250 R$)", Desc = "Velocidad + Aura + Crucifijo", Color = Color3.fromRGB(215, 155, 0), Action = "VIP"},
		{Name = "✝️ CRUCIFIJO SAGRado", Desc = "Congela monstruos por 5s", Color = Color3.fromRGB(160, 45, 220), Action = "CRUCIFIX"},
		{Name = "⚡ BOBINA VELOCIDAD", Desc = "Corre el doble de rápido", Color = Color3.fromRGB(0, 170, 240), Action = "SPEED"},
		{Name = "🌀 SUPER GRAVEDAD", Desc = "Saltos gigantes anti-trampas", Color = Color3.fromRGB(40, 195, 95), Action = "GRAVITY"},
		{Name = "🛡️ ESCUDO FANTASMA", Desc = "Sobrevive a 1 ataque mortal", Color = Color3.fromRGB(60, 110, 220), Action = "SHIELD"},
		{Name = "⏭️ SALTAR ETAPA", Desc = "Avanza al siguiente nivel", Color = Color3.fromRGB(225, 65, 40), Action = "SKIP"}
	}

	for idx, item in ipairs(ITEMS) do
		local col = (idx - 1) % 2
		local row = math.floor((idx - 1) / 2)

		local card = Instance.new("TextButton")
		card.Size = UDim2.new(0, 198, 0, 74)
		card.Position = UDim2.new(0, 16 + (col * 208), 0, 56 + (row * 82))
		card.BackgroundColor3 = item.Color
		card.Text = item.Name .. "\n" .. item.Desc
		card.TextColor3 = Color3.fromRGB(255, 255, 255)
		card.Font = Enum.Font.GothamBold
		card.TextScaled = true
		card.Parent = frame

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 10)
		cCorner.Parent = card

		card.MouseButton1Click:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then return end

			if item.Action == "VIP" then
				MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
			elseif item.Action == "CRUCIFIX" then
				giveCrucifixTool(player)
			elseif item.Action == "SPEED" then
				hum.WalkSpeed = 26
			elseif item.Action == "GRAVITY" then
				hum.UseJumpPower = true
				hum.JumpPower = 75
			elseif item.Action == "SHIELD" then
				char:SetAttribute("HasShield", true)
				if not char:FindFirstChildOfClass("ForceField") then
					Instance.new("ForceField", char)
				end
			elseif item.Action == "SKIP" then
				if SKIP_STAGE_PRODUCT_ID > 0 then
					MarketplaceService:PromptProductPurchase(player, SKIP_STAGE_PRODUCT_ID)
				else
					local ls = player:FindFirstChild("leaderstats")
					local st = ls and ls:FindFirstChild("Stage")
					if st and st.Value < 150 then
						st.Value = st.Value + 1
						local nextCp = checkpointsFolder:FindFirstChild(tostring(st.Value))
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if nextCp and hrp then
							hrp.CFrame = nextCp.CFrame + Vector3.new(0, 4.5, 0)
						end
					end
				end
			end
		end)
	end
end

-- ==========================================
-- 8. GESTIÓN DE JUGADORES Y CHECKPOINTS
-- ==========================================
local function teleportToStage(player, character)
	task.wait(0.1)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local hum = character:WaitForChild("Humanoid", 5)
	if not hrp then return end

	local stageVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
	local stageNum = (stageVal and stageVal.Value) or 1
	local cp = checkpointsFolder:FindFirstChild(tostring(stageNum)) or checkpointsFolder:FindFirstChild("1")

	if cp then
		hrp.CFrame = cp.CFrame + Vector3.new(0, 4.5, 0)
	else
		hrp.CFrame = CFrame.new(0, 5, 0)
	end

	-- Dar Crucifijo de inicio y beneficios VIP si tiene el pase
	giveCrucifixTool(player)
	pcall(function()
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID) and hum then
			hum.WalkSpeed = 24
			character:SetAttribute("HasShield", true)
		end
	end)
end

local function setupPlayer(player)
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local stage = ls:FindFirstChild("Stage") or Instance.new("IntValue")
	stage.Name = "Stage"
	if stage.Value == 0 then stage.Value = 1 end
	stage.Parent = ls

	task.spawn(buildMegaShopGui, player)

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
			local cpSound = add3DSound(cp, 9114074523, 0.8, 1.35, false, 35)
			cp.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = Players:GetPlayerFromCharacter(char)
				if player and player:FindFirstChild("leaderstats") then
					local stageVal = player.leaderstats:FindFirstChild("Stage")
					if stageVal and stageNum > stageVal.Value and stageNum <= stageVal.Value + 2 then
						stageVal.Value = stageNum
						cpSound:Play()
					end
				end
			end)
		end
	end
end

-- ==========================================
-- 9. BUCLE MAESTRO OPTIMIZADO (DISTANCE CULLING 60 FPS)
-- ==========================================
RunService.Heartbeat:Connect(function(dt)
	local now = tick()
	local playerPositions = {}

	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			table.insert(playerPositions, {Player = p, Pos = hrp.Position, Char = p.Character})
		end
	end

	-- 1. Mover sierras solo si hay un jugador cerca (< 150 studs)
	for _, h in ipairs(movingHazards) do
		if h.Part and h.Part.Parent then
			local near = false
			for _, pp in ipairs(playerPositions) do
				if math.abs(pp.Pos.Z - h.Origin.Z) < 150 then
					near = true
					break
				end
			end
			if near then
				local offset = math.sin(now * h.Speed + h.Phase) * h.Amplitude
				if h.MoveZ then
					h.Part.Position = h.Origin + Vector3.new(0, 0, offset)
				else
					h.Part.Position = h.Origin + Vector3.new(offset, 0, 0)
				end
			end
		end
	end

	-- 2. Animar Monstruos Avatar R6 solo si hay jugadores cerca (< 150 studs)
	for _, m in ipairs(activeEnemies) do
		local torso = m.Torso
		if torso and torso.Parent then
			local closestDist = 999
			local targetPos = nil

			for _, pp in ipairs(playerPositions) do
				local dist = (pp.Pos - m.Origin).Magnitude
				if dist < closestDist then
					closestDist = dist
				end
				local hum = pp.Char:FindFirstChildOfClass("Humanoid")
				if dist < 36 and hum and hum.Health > 0 and not pp.Char:GetAttribute("IsHiding") then
					targetPos = pp.Pos
				end
			end

			if closestDist < 150 and not torso:GetAttribute("Stunned") then
				local newPos = torso.Position
				local lookAt = newPos + Vector3.new(0, 0, 1)

				if targetPos then
					if now - m.LastRoar > 4.5 then
						m.LastRoar = now
						m.Roar:Play()
					end
					local flatTarget = Vector3.new(targetPos.X, torso.Position.Y, targetPos.Z)
					local dir = (flatTarget - torso.Position)
					if dir.Magnitude > 0.5 then
						newPos = torso.Position + dir.Unit * m.Speed * dt
						lookAt = flatTarget
					end
				else
					local zWalk = math.cos(now * 1.8) * (m.Radius * 2)
					local xWalk = math.sin(now * 2.5) * m.Radius
					newPos = m.Origin + Vector3.new(xWalk, 0, zWalk)
					lookAt = newPos + Vector3.new(0, 0, (math.sin(now * 1.8) >= 0 and -1 or 1))
				end

				local cf = CFrame.lookAt(newPos, lookAt)
				local s = m.Scale
				local walkSwing = math.sin(now * 10) * 0.65

				-- Articulación de Avatar R6 (Cabeza, Brazos y Piernas caminando)
				torso.CFrame = cf
				m.Head.CFrame = cf * CFrame.new(0, 1.5 * s, 0)
				m.EyeL.CFrame = cf * CFrame.new(-0.35 * s, 1.6 * s, -0.55 * s)
				m.EyeR.CFrame = cf * CFrame.new(0.35 * s, 1.6 * s, -0.55 * s)

				m.ArmL.CFrame = cf * CFrame.new(-1.5 * s, 0, 0) * CFrame.Angles(-walkSwing, 0, 0)
				m.ArmR.CFrame = cf * CFrame.new(1.5 * s, 0, 0) * CFrame.Angles(walkSwing + 0.5, 0, 0)
				m.LegL.CFrame = cf * CFrame.new(-0.5 * s, -2 * s, 0) * CFrame.Angles(walkSwing, 0, 0)
				m.LegR.CFrame = cf * CFrame.new(0.5 * s, -2 * s, 0) * CFrame.Angles(-walkSwing, 0, 0)
				m.Weapon.CFrame = m.ArmR.CFrame * CFrame.new(0, -1.2 * s, -1.2 * s) * CFrame.Angles(math.rad(-75), 0, 0)
			end
		end
	end
end)
