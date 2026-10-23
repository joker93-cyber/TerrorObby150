-- ServerScriptService/LevelGenerator.server.lua
-- Compatible 100% con GameManager, HorrorClient, AudioManager y ShopClient.
workspace:SetAttribute("GenStarted", os.time())
local genOk, genErr = xpcall(function()

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

---------------------------------------------------------------- CONFIGURACIÓN
local TOTAL_STAGES = 150
local STAGE_LENGTH = 140
local BOSS_EVERY = 30
local THICK = 1.5
local CP_HALF = 8
local MODULES_PER_STAGE = 4
local MODULE_LEN = (STAGE_LENGTH - CP_HALF * 2) / MODULES_PER_STAGE -- 31 studs
local BOSS_ARENA_WIDTH = 60
local VOID_Y = -45

---------------------------------------------------------------- ILUMINACIÓN INICIAL (OTOÑO APOCALÍPTICO)
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
		child:Destroy()
	end
end

Lighting.Brightness = 1.8
Lighting.ClockTime = 18.1
Lighting.FogStart = 45
Lighting.FogEnd = 340
Lighting.FogColor = Color3.fromRGB(55, 30, 28)
Lighting.Ambient = Color3.fromRGB(95, 60, 50)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 70, 55)

local sky = Instance.new("Sky")
sky.StarCount = 0
sky.CelestialBodiesShown = false
sky.Parent = Lighting

local atmo = Instance.new("Atmosphere")
atmo.Density = 0.36
atmo.Color = Color3.fromRGB(115, 55, 40)
atmo.Decay = Color3.fromRGB(40, 20, 25)
atmo.Haze = 2.2
atmo.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.75
bloom.Size = 24
bloom.Threshold = 0.85
bloom.Parent = Lighting

---------------------------------------------------------------- CARPETAS
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

---------------------------------------------------------------- BIOMAS (MATERIALES 100% VÁLIDOS + CLIMA EVOLUTIVO)
local BIOMES = {
	[1] = {
		Name = "Avenida del Cine Maldito",
		BossName = "El Cirujano Demente",
		Color = Color3.fromRGB(115, 75, 65),
		Material = Enum.Material.Cobblestone,
		KillColor = Color3.fromRGB(255, 85, 20),
		LeafColor = Color3.fromRGB(225, 95, 25),
		FogColor = Color3.fromRGB(60, 30, 25),
		ClockTime = 18.1
	},
	[2] = {
		Name = "Las Alcantarillas Tóxicas",
		BossName = "La Aberración Tóxica",
		Color = Color3.fromRGB(60, 75, 60),
		Material = Enum.Material.CorrodedMetal,
		KillColor = Color3.fromRGB(55, 225, 40),
		LeafColor = Color3.fromRGB(140, 170, 45),
		FogColor = Color3.fromRGB(25, 45, 25),
		ClockTime = 19.2
	},
	[3] = {
		Name = "La Mansión Carmesí",
		BossName = "La Dama Espectral",
		Color = Color3.fromRGB(85, 45, 40),
		Material = Enum.Material.Brick,
		KillColor = Color3.fromRGB(235, 30, 60),
		LeafColor = Color3.fromRGB(190, 30, 40),
		FogColor = Color3.fromRGB(50, 15, 25),
		ClockTime = 20.0
	},
	[4] = {
		Name = "El Bosque de Halloween",
		BossName = "El Carnicero de la Niebla",
		Color = Color3.fromRGB(65, 55, 45),
		Material = Enum.Material.Slate,
		KillColor = Color3.fromRGB(170, 50, 255),
		LeafColor = Color3.fromRGB(240, 115, 20),
		FogColor = Color3.fromRGB(35, 20, 45),
		ClockTime = 21.5
	},
	[5] = {
		Name = "Cráter del Purgatorio",
		BossName = "El Monarca del Abismo",
		Color = Color3.fromRGB(45, 35, 40),
		Material = Enum.Material.Basalt,
		KillColor = Color3.fromRGB(255, 65, 0),
		LeafColor = Color3.fromRGB(255, 60, 0),
		FogColor = Color3.fromRGB(65, 20, 10),
		ClockTime = 17.6
	},
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

local function createLocker(cframe, parent)
	local locker = createPart(Vector3.new(4.5, 8, 4.5), cframe, Color3.fromRGB(55, 40, 35), Enum.Material.Metal, parent)
	locker.Name = "HideLocker"
	createPart(Vector3.new(3.4, 1.2, 0.3), cframe * CFrame.new(0, 2, -2.2), Color3.fromRGB(255, 150, 50), Enum.Material.Neon, parent).CanCollide = false

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

---------------------------------------------------------------- ESCENOGRAFÍA URBANA (CINE, EDIFICIOS, CARPAS, ÁRBOLES)
local function buildCinemaBackdrop()
	local zBack = 22
	createPart(Vector3.new(64, 34, 6), CFrame.new(0, 20, zBack), Color3.fromRGB(130, 80, 70), Enum.Material.Brick, mapFolder)
	createPart(Vector3.new(26, 44, 8), CFrame.new(0, 25, zBack - 1), Color3.fromRGB(145, 110, 100), Enum.Material.Concrete, mapFolder)
	createPart(Vector3.new(1.2, 18, 0.5), CFrame.new(-18, 24, zBack - 3.3), Color3.fromRGB(255, 210, 160), Enum.Material.Neon, mapFolder)
	createPart(Vector3.new(1.2, 18, 0.5), CFrame.new(18, 24, zBack - 3.3), Color3.fromRGB(255, 210, 160), Enum.Material.Neon, mapFolder)

	local banner = createPart(Vector3.new(22, 6, 0.6), CFrame.new(0, 21, zBack - 5.2), Color3.fromRGB(210, 20, 25), Enum.Material.Neon, mapFolder)
	local sGui = Instance.new("SurfaceGui", banner)
	sGui.Face = Enum.NormalId.Front
	local bTxt = Instance.new("TextLabel", sGui)
	bTxt.Size = UDim2.fromScale(1, 1)
	bTxt.BackgroundTransparency = 1
	bTxt.Text = "NOW SHOWING:\nPESADILLA 150"
	bTxt.TextColor3 = Color3.fromRGB(255, 240, 220)
	bTxt.Font = Enum.Font.GothamBlack
	bTxt.TextScaled = true

	createPart(Vector3.new(20, 3, 8), CFrame.new(0, 15, zBack - 8), Color3.fromRGB(55, 45, 45), Enum.Material.Concrete, mapFolder)
	createPart(Vector3.new(20.4, 0.6, 8.4), CFrame.new(0, 16.2, zBack - 8), Color3.fromRGB(255, 170, 50), Enum.Material.Neon, mapFolder)
end
buildCinemaBackdrop()

local function buildCityDecor(ctx, xCenter, yBase, zCenter)
	local folder = ctx.folder
	local side = (ctx.stage % 2 == 0) and 1 or -1

	-- Edificio en ruinas con ventanas luminosas
	local bX = xCenter + (side * 38)
	local bH = 30 + (ctx.stage % 3) * 8
	createPart(Vector3.new(16, bH, 22), CFrame.new(bX, yBase + bH / 2 - 6, zCenter), Color3.fromRGB(90, 60, 55), Enum.Material.Brick, folder)
	for r = 1, 3 do
		local win = createPart(Vector3.new(0.5, 4, 5), CFrame.new(bX - (side * 8.1), yBase + r * 8 - 4, zCenter), ctx.biome.KillColor, Enum.Material.Neon, folder)
		win.CanCollide = false
	end

	-- Árbol de otoño
	local tX = xCenter - (side * 15)
	createPart(Vector3.new(2, 11, 2), CFrame.new(tX, yBase + 5.5, zCenter + 18), Color3.fromRGB(65, 42, 32), Enum.Material.Wood, folder)
	local leaves = createPart(Vector3.new(9, 7, 9), CFrame.new(tX, yBase + 12, zCenter + 18), ctx.biome.LeafColor, Enum.Material.Grass, folder)
	leaves.CanCollide = false

	-- Farola de calle y carpa de campamento cada 2 etapas
	if ctx.stage % 2 == 1 then
		local lX = xCenter + (side * 11)
		createPart(Vector3.new(0.7, 14, 0.7), CFrame.new(lX, yBase + 7, zCenter - 15), Color3.fromRGB(180, 185, 195), Enum.Material.Metal, folder)
		local bulb = createPart(Vector3.new(3, 0.6, 1.2), CFrame.new(lX - side * 1.2, yBase + 14, zCenter - 15), Color3.fromRGB(255, 240, 210), Enum.Material.Neon, folder)
		local pl = Instance.new("PointLight", bulb)
		pl.Color = Color3.fromRGB(255, 200, 150)
		pl.Range = 38
		pl.Brightness = 1.8
		pl.Shadows = false
	end
end

local function floorPad(ctx, cx, cz, sx, sz, y)
	return createPart(Vector3.new(sx, THICK, sz), CFrame.new(cx, y or ctx.baseY, cz), ctx.biome.Color, ctx.biome.Material, ctx.folder)
end

local function hazard(ctx, size, cframe)
	local p = createPart(size, cframe, ctx.biome.KillColor, Enum.Material.Neon, ctx.folder)
	p.Name = "Hazard"
	CollectionService:AddTag(p, "KillBrick")
	return p
end

local function slab(ctx, a, b, width, material, color, friction)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -THICK / 2, 0)
	local p = createPart(Vector3.new(width, THICK, len), cf, color or ctx.biome.Color, material or ctx.biome.Material, ctx.folder)
	if friction then
		p.CustomPhysicalProperties = PhysicalProperties.new(0.7, friction, 0, 1, 1)
	end
	return p
end

local function endCaps(ctx, z0, capLen)
	floorPad(ctx, ctx.baseX, z0 - capLen / 2, 14, capLen, ctx.baseY)
	floorPad(ctx, ctx.baseX, z0 - MODULE_LEN + capLen / 2, 14, capLen, ctx.baseY)
end

---------------------------------------------------------------- MÓDULOS DINÁMICOS (ESCALERAS, TOBOGANES, LATERALES, SUBIDAS/BAJADAS)
local MODULES = {}

-- 1. Escalinata alta que sube y baja (+8.5 studs)
MODULES.stairs = function(ctx, z0)
	local rise = 2.6
	local depth = MODULE_LEN / 5
	local mult = {1, 2, 3, 2, 1}
	for i = 1, 5 do
		floorPad(ctx, ctx.baseX, z0 - depth * (i - 0.5), 12, depth, ctx.baseY + rise * mult[i])
	end
end

-- 2. Desvío lateral en Zigzag (salta de izquierda a derecha con diferente altura)
MODULES.zigzag = function(ctx, z0)
	local capLen = 2.5
	local n, depth = 3, 5.5
	local width = 8 - 2.5 * ctx.difficulty
	endCaps(ctx, z0, capLen)
	local gap = (MODULE_LEN - capLen * 2 - n * depth) / (n + 1)
	for i = 1, n do
		local x = ctx.baseX + ((i % 2 == 0) and 6.5 or -6.5)
		local y = ctx.baseY + ((i == 2) and 2.5 or 1.2)
		floorPad(ctx, x, z0 - capLen - gap * i - depth * (i - 0.5), width, depth, y)
	end
end

-- 3. Súper Tobogán en picada (-8 studs) y rampa de impulso para subir
MODULES.slide_valley = function(ctx, z0)
	local capLen, drop, slideLen, padLen = 2, 8, 13, 5
	endCaps(ctx, z0, capLen)
	local topY = ctx.baseY + THICK / 2
	local zA = z0 - capLen
	local zB = zA - slideLen
	local lowTop = topY - drop
	local slideCol = ctx.biome.Color:Lerp(Color3.fromRGB(255, 170, 90), 0.5)
	slab(ctx, Vector3.new(ctx.baseX, topY, zA), Vector3.new(ctx.baseX, lowTop, zB), 12, Enum.Material.Ice, slideCol, 0.03)
	floorPad(ctx, ctx.baseX, zB - padLen / 2, 12, padLen, lowTop - THICK / 2)
	slab(ctx, Vector3.new(ctx.baseX, lowTop, zB - padLen), Vector3.new(ctx.baseX, topY, z0 - MODULE_LEN + capLen), 12)
end

-- 4. Camino dividido por los laterales (Rodea un cráter central por izquierda o derecha)
MODULES.side_detour = function(ctx, z0)
	local capLen = 3
	endCaps(ctx, z0, capLen)
	local midLen = MODULE_LEN - capLen * 2
	local zMid = z0 - MODULE_LEN / 2
	-- Dos pasarelas laterales elevadas y un láser en medio
	floorPad(ctx, ctx.baseX - 7.5, zMid, 4.5, midLen, ctx.baseY + 2)
	floorPad(ctx, ctx.baseX + 7.5, zMid, 4.5, midLen, ctx.baseY + 2)
	hazard(ctx, Vector3.new(5, 0.8, 0.8), CFrame.new(ctx.baseX - 7.5, ctx.baseY + 3.4, zMid))
	hazard(ctx, Vector3.new(5, 0.8, 0.8), CFrame.new(ctx.baseX + 7.5, ctx.baseY + 3.4, zMid + 4))
end

-- 5. Puente de losas que desaparecen al pisarlas
MODULES.fade_bridge = function(ctx, z0)
	local capLen, n = 2.5, 4
	endCaps(ctx, z0, capLen)
	local depth = (MODULE_LEN - capLen * 2) / n
	for i = 1, n do
		local x = ctx.baseX + ((i % 2 == 0) and 3.2 or -3.2)
		local tile = createPart(Vector3.new(8, THICK, depth - 1.2), CFrame.new(x, ctx.baseY, z0 - capLen - depth * (i - 0.5)), ctx.biome.Color, Enum.Material.ForceField, ctx.folder)
		CollectionService:AddTag(tile, "FadeBrick")
	end
end

-- 6. Pasillo con láseres incandescentes
MODULES.laser_hall = function(ctx, z0)
	floorPad(ctx, ctx.baseX, z0 - MODULE_LEN / 2, 16, MODULE_LEN, ctx.baseY)
	local topY = ctx.baseY + THICK / 2
	local count = (ctx.difficulty > 0.5) and 3 or 2
	for i = 1, count do
		local z = z0 - (MODULE_LEN / (count + 1)) * i
		hazard(ctx, Vector3.new(16, 0.6, 0.6), CFrame.new(ctx.baseX, topY + 1.0, z))
	end
end

-- 7. Sierras/barras que barren de lado a lado
MODULES.sweeper = function(ctx, z0)
	floorPad(ctx, ctx.baseX, z0 - MODULE_LEN / 2, 18, MODULE_LEN, ctx.baseY)
	local topY = ctx.baseY + THICK / 2
	local count = (ctx.difficulty > 0.4) and 3 or 2
	for i = 1, count do
		local z = z0 - (MODULE_LEN / (count + 1)) * i
		local mover = createPart(Vector3.new(3, 4, 2), CFrame.new(ctx.baseX, topY + 2, z), ctx.biome.KillColor, Enum.Material.Neon, ctx.folder)
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

-- 8. Tablero mortal de escombros
MODULES.checker = function(ctx, z0)
	local rows, depth = 3, 6
	local spacing = MODULE_LEN / rows
	for i = 1, rows do
		local z = z0 - spacing * (i - 0.5)
		local lethalLeft = ctx.rng:NextInteger(0, 1) == 0
		for _, side in ipairs({-1, 1}) do
			local cf = CFrame.new(ctx.baseX + side * 3.6, ctx.baseY, z)
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

-- 9. Avenida con refugio de armario y huellas brillantes
MODULES.locker_room = function(ctx, z0)
	floorPad(ctx, ctx.baseX, z0 - MODULE_LEN / 2, 18, MODULE_LEN, ctx.baseY)
	local topY = ctx.baseY + THICK / 2
	createLocker(CFrame.new(ctx.baseX + 6.5, topY + 4, z0 - MODULE_LEN / 2), ctx.folder)
	for _, k in ipairs({7, 24}) do
		hazard(ctx, Vector3.new(18, 2.2, 1.2), CFrame.new(ctx.baseX, topY + 1.1, z0 - k))
	end
end

local ALL_MODULES = {"stairs", "slide_valley", "side_detour", "zigzag", "fade_bridge", "sweeper", "checker", "laser_hall", "locker_room"}

local function pickModules(ctx)
	local picked = {}
	local last
	for m = 1, MODULES_PER_STAGE do
		local name
		repeat
			name = ALL_MODULES[ctx.rng:NextInteger(1, #ALL_MODULES)]
		until name ~= last
		last = name
		picked[m] = name
	end
	-- En etapas con monstruo (múltiplos de 5), el módulo 2 (donde aparece el monstruo a Z-42) y el 3 tienen piso continuo y armario
	if ctx.stage % 5 == 0 then
		picked[2] = "locker_room"
		picked[3] = "laser_hall"
	end
	return picked
end

---------------------------------------------------------------- ARENA DE JEFE
local function buildBossArena(ctx, originZ)
	local length = STAGE_LENGTH - CP_HALF * 2
	local centerZ = originZ - CP_HALF - length / 2
	local arena = createPart(Vector3.new(BOSS_ARENA_WIDTH, 2, length), CFrame.new(0, 5, centerZ), ctx.biome.Color, ctx.biome.Material, ctx.folder)
	arena.Name = "BossArena_" .. ctx.stage
	local topY = 6
	for _, dz in ipairs({-40, 40}) do
		for _, x in ipairs({-24, 24}) do
			createLocker(CFrame.new(x, topY + 4, centerZ + dz), ctx.folder)
		end
	end
	for _, x in ipairs({-13, 13}) do
		createPart(Vector3.new(4, 14, 4), CFrame.new(x, topY + 7, centerZ), ctx.biome.Color, ctx.biome.Material, ctx.folder)
	end
end

---------------------------------------------------------------- SPAWN INICIAL
local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawnLoc.Name = "MainSpawn"
spawnLoc.Size = Vector3.new(8, 1, 8)
spawnLoc.CFrame = CFrame.new(0, 6.5, 0)
spawnLoc.Anchored = true
spawnLoc.Neutral = true
spawnLoc.Duration = 0
spawnLoc.Transparency = 1
spawnLoc.CanCollide = false
spawnLoc.Parent = workspace

---------------------------------------------------------------- GENERACIÓN DE LAS 150 ETAPAS CON ALTURA Y LATERALES DINÁMICOS
local currentZ = 0
local currentY = 5
local currentX = 0

local function makeVoid(parent, centerX, centerZ, length, yFloor)
	local void = createPart(Vector3.new(600, 8, length), CFrame.new(centerX, math.min(VOID_Y, yFloor - 32), centerZ), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, parent)
	void.Name = "VoidKill"
	void.Transparency = 1
	CollectionService:AddTag(void, "KillBrick")
end

for stage = 1, TOTAL_STAGES do
	local biome, biomeIndex = getBiome(stage)
	local isBossStage = (stage % BOSS_EVERY == 0)
	workspace:SetAttribute("GenStage", stage)

	-- En etapas de jefe centramos en X=0, Y=5 para que la onda expansiva de GameManager coincida exacto
	if isBossStage or stage == 1 then
		currentX = 0
		currentY = 5
	end

	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage_" .. stage
	stageFolder.Parent = mapFolder

	local ctx = {
		stage = stage,
		biome = biome,
		biomeIndex = biomeIndex,
		baseX = currentX,
		baseY = currentY,
		folder = stageFolder,
		rng = Random.new(stage * 7919 + 17),
		difficulty = (stage - 1) / (TOTAL_STAGES - 1),
	}

	-- 1. Plataforma de Checkpoint con líneas naranjas urbanas
	local cp = createPart(Vector3.new(CP_HALF * 2 + 4, 2, CP_HALF * 2), CFrame.new(currentX, currentY, currentZ), Color3.fromRGB(45, 38, 38), Enum.Material.Brick, checkpointsFolder)
	cp.Name = tostring(stage)

	createPart(Vector3.new(0.4, 0.2, CP_HALF * 2), CFrame.new(currentX - 7, currentY + 1.05, currentZ), biome.KillColor, Enum.Material.Neon, stageFolder).CanCollide = false
	createPart(Vector3.new(0.4, 0.2, CP_HALF * 2), CFrame.new(currentX + 7, currentY + 1.05, currentZ), biome.KillColor, Enum.Material.Neon, stageFolder).CanCollide = false
	createLocker(CFrame.new(currentX - 7, currentY + 5, currentZ), stageFolder)

	local light = Instance.new("PointLight")
	light.Color = biome.KillColor
	light.Range = 28
	light.Brightness = 1.8
	light.Shadows = false
	light.Parent = cp

	local bgui = Instance.new("BillboardGui")
	bgui.Size = UDim2.fromScale(9, 3.4)
	bgui.StudsOffset = Vector3.new(0, 6.5, 0)
	bgui.MaxDistance = 75
	bgui.LightInfluence = 0
	bgui.Parent = cp

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = isBossStage and ("⚠️ JEFE ETAPA " .. stage .. "\n" .. biome.BossName) or ("ETAPA " .. stage .. "\n[" .. biome.Name .. "]")
	label.TextColor3 = isBossStage and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 235, 210)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bgui

	-- Escenografía de ciudad a los lados de la etapa
	buildCityDecor(ctx, currentX, currentY, currentZ - STAGE_LENGTH / 2)

	-- 2. Contenido de la etapa + transición de subida/bajada/lateral hacia la siguiente etapa
	local nextX = currentX
	local nextY = currentY
	if not isBossStage and ((stage + 1) % BOSS_EVERY ~= 0) then
		local shift = (stage % 4)
		if shift == 1 then
			nextY = math.clamp(currentY + 6, 5, 29) -- Sube la calle
		elseif shift == 2 then
			nextX = math.clamp(currentX + 10, -20, 20) -- Desvío a la derecha
		elseif shift == 3 then
			nextY = math.clamp(currentY - 6, 5, 29) -- Baja por tobogán
		else
			nextX = math.clamp(currentX - 10, -20, 20) -- Desvío a la izquierda
		end
	else
		nextX = 0
		nextY = 5
	end

	if isBossStage then
		pcall(buildBossArena, ctx, currentZ)
	else
		local names = pickModules(ctx)
		for m = 1, MODULES_PER_STAGE - 1 do
			local z0 = currentZ - CP_HALF - (m - 1) * MODULE_LEN
			local okMod = pcall(MODULES[names[m]], ctx, z0)
			if not okMod then
				floorPad(ctx, currentX, z0 - MODULE_LEN / 2, 16, MODULE_LEN, currentY)
			end
		end
		-- El 4to módulo conecta suavemente con la nueva altura (nextY) y posición lateral (nextX) de la siguiente etapa
		local z3 = currentZ - CP_HALF - 3 * MODULE_LEN
		local zEnd = currentZ - STAGE_LENGTH + CP_HALF
		local startPt = Vector3.new(currentX, currentY + THICK / 2, z3)
		local endPt = Vector3.new(nextX, nextY + THICK / 2, zEnd)
		local isSlideDown = (nextY < currentY)
		slab(ctx, startPt, endPt, 13, isSlideDown and Enum.Material.Ice or biome.Material, isSlideDown and Color3.fromRGB(220, 140, 80) or biome.Color, isSlideDown and 0.04 or 0.7)
	end

	-- 3. Vacío mortal debajo de la etapa (activa el screamer de meme "FALL" en GameManager)
	makeVoid(stageFolder, currentX, currentZ - STAGE_LENGTH / 2, STAGE_LENGTH + 4, math.min(currentY, nextY))

	currentZ = currentZ - STAGE_LENGTH
	currentX = nextX
	currentY = nextY
end

---------------------------------------------------------------- META FINAL
local winPod = createPart(Vector3.new(24, 2, 24), CFrame.new(currentX, currentY, currentZ), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, checkpointsFolder)
winPod.Name = "150_WIN"
makeVoid(mapFolder, currentX, currentZ, 120, currentY)

local winGui = Instance.new("BillboardGui", winPod)
winGui.Size = UDim2.fromScale(10, 3)
winGui.StudsOffset = Vector3.new(0, 7, 0)
winGui.MaxDistance = 120
winGui.LightInfluence = 0

local winLabel = Instance.new("TextLabel", winGui)
winLabel.Size = UDim2.fromScale(1, 1)
winLabel.BackgroundTransparency = 1
winLabel.Text = "🏆 ¡META! ESCAPASTE"
winLabel.TextColor3 = Color3.fromRGB(255, 240, 150)
winLabel.TextStrokeTransparency = 0
winLabel.Font = Enum.Font.GothamBold
winLabel.TextScaled = true

-- Cambiar el ambiente del cielo automáticamente según la etapa del jugador
Players.PlayerAdded:Connect(function(plr)
	task.spawn(function()
		local ls = plr:WaitForChild("leaderstats", 15)
		local st = ls and ls:WaitForChild("Etapa", 15)
		if st then
			st.Changed:Connect(function(val)
				local b = getBiome(val)
				Lighting.FogColor = b.FogColor
				Lighting.ClockTime = b.ClockTime
			end)
		end
	end)
end)

workspace:SetAttribute("GenError", nil)
workspace:SetAttribute("MapReady", true)
print("[LevelGenerator] Mapa listo: " .. TOTAL_STAGES .. " etapas")

end, function(e)
	return tostring(e) .. " | " .. debug.traceback()
end)

if not genOk then
	warn("[LevelGenerator] ERROR: " .. tostring(genErr))
	workspace:SetAttribute("GenError", string.sub(tostring(genErr), 1, 500))
end
