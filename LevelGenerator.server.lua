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

		createLocker(hall.Position +
