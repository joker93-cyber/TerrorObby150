-- ServerScriptService/LevelGenerator (Script)
-- v2: etapas largas (140 studs), 8 tipos de módulos que se combinan, jefes con arena ancha
-- y vacío mortal dividido por etapa. Compatible con GameManager, HorrorClient y AudioManager.
--
-- CONTRATO CON LOS DEMÁS SCRIPTS (no cambiar nombres sin cambiar también los otros):
--   workspace.Checkpoints        -> partes llamadas "1".."150" y "150_WIN"
--   workspace.ActiveKillers      -> carpeta donde GameManager pone los monstruos
--   workspace atributos          -> StageLength, TotalStages, MapReady
--   Tags                         -> KillBrick, FadeBrick, HideLocker, MovingKill
--   Partes llamadas "VoidKill"   -> GameManager lanza el screamer de meme al tocarlas

-- Diagnóstico: todo el generador corre protegido; si falla, el error queda en workspace:GetAttribute("GenError")
workspace:SetAttribute("GenStarted", os.time())
local genOk, genErr = xpcall(function()

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

---------------------------------------------------------------- CONFIGURACIÓN
local TOTAL_STAGES = 150
local STAGE_LENGTH = 140 -- antes 84
local BOSS_EVERY = 30
local BASE_Y = 5
local THICK = 1.5
local TOP_Y = BASE_Y + THICK / 2 -- altura de la superficie de las plataformas normales
local CP_HALF = 8 -- la plataforma de checkpoint mide 16x16
local MODULES_PER_STAGE = 4
local MODULE_LEN = (STAGE_LENGTH - CP_HALF * 2) / MODULES_PER_STAGE -- 31 studs
local BOSS_ARENA_WIDTH = 60 -- antes 34: más espacio para luchar
local VOID_Y = -35

---------------------------------------------------------------- ILUMINACIÓN
Lighting.Brightness = 0.25
Lighting.ClockTime = 0
Lighting.FogEnd = 115
Lighting.FogColor = Color3.fromRGB(8, 8, 12)
Lighting.Ambient = Color3.fromRGB(18, 18, 24)
Lighting.OutdoorAmbient = Color3.fromRGB(12, 12, 18)

---------------------------------------------------------------- CARPETAS (si ya existen, se vacían: evita mapas duplicados)
local function makeFolder(name)
	local f = workspace:FindFirstChild(name)
	if f then
		f:ClearAllChildren()
		return f
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = workspace
	return f
end

local mapFolder = makeFolder("GeneratedMap")
local checkpointsFolder = makeFolder("Checkpoints")
makeFolder("ActiveKillers")

workspace:SetAttribute("StageLength", STAGE_LENGTH)
workspace:SetAttribute("TotalStages", TOTAL_STAGES)

---------------------------------------------------------------- BIOMAS
local BIOMES = {
	[1] = {Name = "El Manicomio", BossName = "El Cirujano Demente", Color = Color3.fromRGB(150, 155, 150), Material = Enum.Material.Tiles, KillColor = Color3.fromRGB(150, 0, 0)},
	[2] = {Name = "Las Alcantarillas", BossName = "La Aberración Tóxica", Color = Color3.fromRGB(50, 70, 50), Material = Enum.Material.CorrodedMetal, KillColor = Color3.fromRGB(50, 210, 30)},
	[3] = {Name = "La Mansión Fantasma", BossName = "La Dama Espectral", Color = Color3.fromRGB(65, 42, 32), Material = Enum.Material.WoodPlanks, KillColor = Color3.fromRGB(140, 80, 255)},
	[4] = {Name = "El Bosque Muerto", BossName = "El Carnicero de la Niebla", Color = Color3.fromRGB(40, 35, 30), Material = Enum.Material.Slate, KillColor = Color3.fromRGB(210, 25, 25)},
	[5] = {Name = "El Purgatorio", BossName = "El Monarca del Abismo", Color = Color3.fromRGB(22, 18, 25), Material = Enum.Material.Basalt, KillColor = Color3.fromRGB(255, 65, 0)},
}

local function getBiome(stageNum)
	local index = math.clamp(math.ceil(stageNum / BOSS_EVERY), 1, 5)
	return BIOMES[index], index
end

---------------------------------------------------------------- CONSTRUCTORES BÁSICOS
local function createPart(size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Armario de escondite con ProximityPrompt (GameManager lo conecta por el tag HideLocker)
local function createLocker(cframe, parent)
	local locker = createPart(Vector3.new(4.5, 8, 4.5), cframe, Color3.fromRGB(45, 35, 25), Enum.Material.Wood, parent)
	locker.Name = "HideLocker"

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Armario Seguro"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = locker

	CollectionService:AddTag(locker, "HideLocker")
	return locker
end

-- Plataforma plana normal
local function floorPad(ctx, cx, cz, sx, sz, y)
	return createPart(Vector3.new(sx, THICK, sz), CFrame.new(cx, y or BASE_Y, cz), ctx.biome.Color, ctx.biome.Material, ctx.folder)
end

-- Obstáculo mortal: siempre visible (color de peligro del bioma, neón)
local function hazard(ctx, size, cframe)
	local p = createPart(size, cframe, ctx.biome.KillColor, Enum.Material.Neon, ctx.folder)
	p.Name = "Hazard"
	CollectionService:AddTag(p, "KillBrick")
	return p
end

-- Rampa entre dos puntos: la superficie de arriba pasa exactamente por a y b
local function slab(ctx, a, b, width, material, color, friction)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -THICK / 2, 0)
	local p = createPart(Vector3.new(width, THICK, len), cf, color or ctx.biome.Color, material or ctx.biome.Material, ctx.folder)
	if friction then
		p.CustomPhysicalProperties = PhysicalProperties.new(0.7, friction, 0, 1, 1)
	end
	return p
end

-- Plataformas de borde (entrada y salida de un módulo, siempre a nivel del suelo)
local function endCaps(ctx, z0, capLen)
	floorPad(ctx, 0, z0 - capLen / 2, 14, capLen)
	floorPad(ctx, 0, z0 - MODULE_LEN + capLen / 2, 14, capLen)
end

---------------------------------------------------------------- MÓDULOS
-- Cada módulo mide MODULE_LEN studs hacia -Z desde z0 y empieza y termina a nivel del suelo.
-- Todos los saltos son de 6 studs o menos (el salto normal alcanza unos 15).
local MODULES = {}

-- Escaleras que suben y bajan (sube 5.4 studs)
MODULES.stairs = function(ctx, z0)
	local rise = 1.8
	local depth = MODULE_LEN / 5
	local mult = {1, 2, 3, 2, 1}
	for i = 1, 5 do
		floorPad(ctx, 0, z0 - depth * (i - 0.5), 12, depth, BASE_Y + rise * mult[i])
	end
end

-- Zigzag lateral: las plataformas se hacen más angostas al avanzar en el juego
MODULES.zigzag = function(ctx, z0)
	local capLen = 2.5
	local n, depth = 3, 5
	local width = 8 - 3 * ctx.difficulty
	endCaps(ctx, z0, capLen)
	local gap = (MODULE_LEN - capLen * 2 - n * depth) / (n + 1)
	for i = 1, n do
		local x = (i % 2 == 0) and 5.5 or -5.5
		floorPad(ctx, x, z0 - capLen - gap * i - depth * (i - 0.5), width, depth)
	end
end

-- Tobogán de hielo hacia abajo y rampa para volver a subir
MODULES.slide_valley = function(ctx, z0)
	local capLen, drop, slideLen, padLen = 2, 5, 12, 5
	endCaps(ctx, z0, capLen)
	local zA = z0 - capLen
	local zB = zA - slideLen
	local lowTop = TOP_Y - drop
	local ice = ctx.biome.Color:Lerp(Color3.fromRGB(190, 225, 245), 0.6)
	slab(ctx, Vector3.new(0, TOP_Y, zA), Vector3.new(0, lowTop, zB), 12, Enum.Material.Ice, ice, 0.05)
	floorPad(ctx, 0, zB - padLen / 2, 12, padLen, lowTop - THICK / 2)
	slab(ctx, Vector3.new(0, lowTop, zB - padLen), Vector3.new(0, TOP_Y, z0 - MODULE_LEN + capLen), 12)
end

-- Puente de losas que desaparecen al pisarlas (FadeBrick lo maneja GameManager)
MODULES.fade_bridge = function(ctx, z0)
	local capLen, n = 2.5, 4
	endCaps(ctx, z0, capLen)
	local depth = (MODULE_LEN - capLen * 2) / n
	for i = 1, n do
		local x = (i % 2 == 0) and 3 or -3
		local tile = createPart(Vector3.new(8, THICK, depth - 1.2), CFrame.new(x, BASE_Y, z0 - capLen - depth * (i - 0.5)), ctx.biome.Color, Enum.Material.ForceField, ctx.folder)
		CollectionService:AddTag(tile, "FadeBrick")
	end
end

-- Pasillo con láseres bajos que hay que saltar
MODULES.laser_hall = function(ctx, z0)
	floorPad(ctx, 0, z0 - MODULE_LEN / 2, 16, MODULE_LEN)
	local count = (ctx.difficulty > 0.5) and 3 or 2
	for i = 1, count do
		local z = z0 - (MODULE_LEN / (count + 1)) * i
		hazard(ctx, Vector3.new(16, 0.6, 0.6), CFrame.new(0, TOP_Y + 1.0, z))
	end
end

-- Barras que barren el pasillo de lado a lado (GameManager las mueve solo en etapas cercanas)
MODULES.sweeper = function(ctx, z0)
	floorPad(ctx, 0, z0 - MODULE_LEN / 2, 18, MODULE_LEN)
	local count = (ctx.difficulty > 0.4) and 3 or 2
	for i = 1, count do
		local z = z0 - (MODULE_LEN / (count + 1)) * i
		local mover = createPart(Vector3.new(3, 4, 2), CFrame.new(0, TOP_Y + 2, z), ctx.biome.KillColor, Enum.Material.Neon, ctx.folder)
		mover.Name = "MovingKill"
		mover:SetAttribute("Stage", ctx.stage)
		mover:SetAttribute("BaseCF", mover.CFrame)
		mover:SetAttribute("Amp", 7)
		mover:SetAttribute("Speed", math.pi / (1.6 - ctx.biomeIndex * 0.12))
		mover:SetAttribute("Phase", i * 1.3)
		CollectionService:AddTag(mover, "KillBrick")
		CollectionService:AddTag(mover, "MovingKill")
	end
end

-- Filas de dos bloques: uno es mortal y SE VE (neón). Antes eran iguales y era pura suerte.
MODULES.checker = function(ctx, z0)
	local rows, depth = 3, 6
	local spacing = MODULE_LEN / rows
	for i = 1, rows do
		local z = z0 - spacing * (i - 0.5)
		local lethalLeft = ctx.rng:NextInteger(0, 1) == 0
		for _, side in ipairs({-1, 1}) do
			local cf = CFrame.new(side * 3.6, BASE_Y, z)
			local size = Vector3.new(6, THICK, depth)
			if (side == -1) == lethalLeft then
				local bad = createPart(size, cf, ctx.biome.KillColor, Enum.Material.Neon, ctx.folder)
				bad.Name = "Hazard"
				CollectionService:AddTag(bad, "KillBrick")
			else
				createPart(size, cf, ctx.biome.Color, ctx.biome.Material, ctx.folder)
			end
		end
	end
end

-- Sala segura con armario y dos vallas bajas
MODULES.locker_room = function(ctx, z0)
	floorPad(ctx, 0, z0 - MODULE_LEN / 2, 18, MODULE_LEN)
	createLocker(CFrame.new(6.5, TOP_Y + 4, z0 - MODULE_LEN / 2), ctx.folder)
	for _, k in ipairs({7, 24}) do
		hazard(ctx, Vector3.new(18, 2.5, 1.2), CFrame.new(0, TOP_Y + 1.25, z0 - k))
	end
end

local EASY = {"stairs", "zigzag", "slide_valley", "laser_hall"}
local MEDIUM = {"fade_bridge", "sweeper", "checker", "locker_room"}

local function pickModules(ctx)
	local pool = {}
	for _, n in ipairs(EASY) do
		table.insert(pool, n)
	end
	if ctx.stage > 3 then
		for _, n in ipairs(MEDIUM) do
			table.insert(pool, n)
		end
	end
	local picked = {}
	local last
	for m = 1, MODULES_PER_STAGE do
		local name
		repeat
			name = pool[ctx.rng:NextInteger(1, #pool)]
		until name ~= last
		last = name
		picked[m] = name
	end
	-- En las etapas con monstruo (múltiplos de 5) siempre hay un armario
	if ctx.stage % 5 == 0 then
		picked[3] = "locker_room"
	end
	return picked
end

---------------------------------------------------------------- ARENA DE JEFE (ancha para poder pelear)
local function buildBossArena(ctx, originZ)
	local length = STAGE_LENGTH - CP_HALF * 2
	local centerZ = originZ - CP_HALF - length / 2
	local arena = createPart(Vector3.new(BOSS_ARENA_WIDTH, 2, length), CFrame.new(0, BASE_Y, centerZ), ctx.biome.Color, ctx.biome.Material, ctx.folder)
	arena.Name = "BossArena_" .. ctx.stage
	local topY = BASE_Y + 1
	for _, dz in ipairs({-40, 40}) do
		for _, x in ipairs({-24, 24}) do
			createLocker(CFrame.new(x, topY + 4, centerZ + dz), ctx.folder)
		end
	end
	-- Pilares para cubrirse
	for _, x in ipairs({-13, 13}) do
		createPart(Vector3.new(4, 14, 4), CFrame.new(x, topY + 7, centerZ), ctx.biome.Color, ctx.biome.Material, ctx.folder)
	end
end

---------------------------------------------------------------- SPAWN INICIAL
-- (GameManager teletransporta al jugador a su checkpoint al cargar sus datos)
local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Name = "MainSpawn"
spawnLoc.Size = Vector3.new(8, 1, 8)
spawnLoc.CFrame = CFrame.new(0, 6.5, 0)
spawnLoc.Anchored = true
spawnLoc.Neutral = true
spawnLoc.Duration = 0
spawnLoc.Transparency = 1
spawnLoc.CanCollide = false
spawnLoc.Parent = workspace

---------------------------------------------------------------- GENERACIÓN DE ETAPAS
local currentZ = 0

local function makeVoid(parent, centerZ, length)
	local void = createPart(Vector3.new(500, 8, length), CFrame.new(0, VOID_Y, centerZ), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, parent)
	void.Name = "VoidKill"
	void.Transparency = 1
	CollectionService:AddTag(void, "KillBrick")
end

for stage = 1, TOTAL_STAGES do
	local biome, biomeIndex = getBiome(stage)
	local isBossStage = (stage % BOSS_EVERY == 0)
	workspace:SetAttribute("GenStage", stage)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage_" .. stage
	stageFolder.Parent = mapFolder

	local ctx = {
		stage = stage,
		biome = biome,
		biomeIndex = biomeIndex,
		folder = stageFolder,
		rng = Random.new(stage * 7919 + 17), -- mismo mapa en cada servidor
		difficulty = (stage - 1) / (TOTAL_STAGES - 1),
	}

	-- 1. Plataforma de checkpoint
	local cp = createPart(Vector3.new(CP_HALF * 2, 2, CP_HALF * 2), CFrame.new(0, BASE_Y, currentZ), Color3.fromRGB(35, 35, 40), Enum.Material.Concrete, checkpointsFolder)
	cp.Name = tostring(stage)

	local light = Instance.new("PointLight")
	light.Color = biome.KillColor
	light.Range = 24
	light.Brightness = 1.6
	light.Shadows = false
	light.Parent = cp

	local bgui = Instance.new("BillboardGui")
	bgui.Size = UDim2.fromScale(9, 3.4)
	bgui.StudsOffset = Vector3.new(0, 6.5, 0)
	bgui.MaxDistance = 70
	bgui.LightInfluence = 0
	bgui.Parent = cp

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = isBossStage and ("⚠️ JEFE ETAPA " .. stage .. "\n" .. biome.BossName) or ("ETAPA " .. stage .. "\n[" .. biome.Name .. "]")
	label.TextColor3 = isBossStage and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 235, 235)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bgui

	-- 2. Contenido de la etapa
	if isBossStage then
		local okBoss, errBoss = pcall(buildBossArena, ctx, currentZ)
		if not okBoss then
			warn("[LevelGenerator] Arena de jefe, etapa " .. stage .. ": " .. tostring(errBoss))
		end
	else
		local names = pickModules(ctx)
		for m = 1, MODULES_PER_STAGE do
			local z0 = currentZ - CP_HALF - (m - 1) * MODULE_LEN
			local okMod, errMod = pcall(MODULES[names[m]], ctx, z0)
			if not okMod then
				warn("[LevelGenerator] Módulo " .. names[m] .. ", etapa " .. stage .. ": " .. tostring(errMod))
				floorPad(ctx, 0, z0 - MODULE_LEN / 2, 16, MODULE_LEN) -- suelo de emergencia
			end
		end
	end

	-- 3. Vacío mortal de esta etapa (una parte por etapa: el límite de tamaño de una parte es 2048 studs)
	makeVoid(stageFolder, currentZ - STAGE_LENGTH / 2, STAGE_LENGTH + 2)

	currentZ = currentZ - STAGE_LENGTH
end

---------------------------------------------------------------- META
local winPod = createPart(Vector3.new(24, 2, 24), CFrame.new(0, BASE_Y, currentZ), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, checkpointsFolder)
winPod.Name = "150_WIN"
makeVoid(mapFolder, currentZ, 120)

local winGui = Instance.new("BillboardGui")
winGui.Size = UDim2.fromScale(10, 3)
winGui.StudsOffset = Vector3.new(0, 7, 0)
winGui.MaxDistance = 120
winGui.LightInfluence = 0
winGui.Parent = winPod

local winLabel = Instance.new("TextLabel")
winLabel.Size = UDim2.fromScale(1, 1)
winLabel.BackgroundTransparency = 1
winLabel.Text = "🏆 ¡META! ESCAPASTE"
winLabel.TextColor3 = Color3.fromRGB(255, 240, 150)
winLabel.TextStrokeTransparency = 0
winLabel.Font = Enum.Font.GothamBold
winLabel.TextScaled = true
winLabel.Parent = winGui

-- Señal para que GameManager sepa que el mapa está completo
workspace:SetAttribute("MapReady", true)
print("[LevelGenerator] Mapa listo: " .. TOTAL_STAGES .. " etapas")

end, function(e)
	return tostring(e) .. " | " .. debug.traceback()
end)

if not genOk then
	warn("[LevelGenerator] ERROR: " .. tostring(genErr))
	workspace:SetAttribute("GenError", string.sub(tostring(genErr), 1, 500))
end
