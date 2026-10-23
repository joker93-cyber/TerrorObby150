local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local TOTAL_STAGES = 150
local STAGE_LENGTH = 84
local BOSS_EVERY = 30

Lighting.Brightness = 0.25
Lighting.ClockTime = 0
Lighting.FogEnd = 115
Lighting.FogColor = Color3.fromRGB(8, 8, 12)
Lighting.Ambient = Color3.fromRGB(18, 18, 24)
Lighting.OutdoorAmbient = Color3.fromRGB(12, 12, 18)

local function makeFolder(name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = workspace
	return f
end

local mapFolder = makeFolder("GeneratedMap")
local checkpointsFolder = makeFolder("Checkpoints")
makeFolder("ActiveKillers")

workspace:SetAttribute("StageLength", STAGE_LENGTH)
workspace:SetAttribute("TotalStages", TOTAL_STAGES)

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

local function createPart(size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Armario de escondite con ProximityPrompt (botón táctil nativo en móvil)
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

-- Spawn inicial (el servidor teletransporta al checkpoint guardado)
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

local currentZ = 0

for stage = 1, TOTAL_STAGES do
	local biome, biomeIndex = getBiome(stage)
	local isBossStage = (stage % BOSS_EVERY == 0)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage_" .. stage
	stageFolder.Parent = mapFolder

	-- 1. Plataforma de checkpoint
	local cp = createPart(Vector3.new(16, 2, 16), CFrame.new(0, 5, currentZ), Color3.fromRGB(35, 35, 40), Enum.Material.Concrete, checkpointsFolder)
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

	if isBossStage then
		-- 2. Arena de jefe
		local arenaCenterZ = currentZ - (STAGE_LENGTH * 0.5)
		local arenaFloor = createPart(Vector3.new(34, 2, STAGE_LENGTH - 12), CFrame.new(0, 5, arenaCenterZ), biome.Color, biome.Material, stageFolder)
		arenaFloor.Name = "BossArena_" .. stage

		createLocker(CFrame.new(-14, 9.5, arenaCenterZ + 12), stageFolder)
		createLocker(CFrame.new(14, 9.5, arenaCenterZ - 12), stageFolder)
	else
		-- 3. Etapas normales
		local pattern = (stage % 5) + 1
		local stepCount = 5
		local stepSpacing = STAGE_LENGTH / (stepCount + 1)

		for i = 1, stepCount do
			local stepZ = currentZ - (i * stepSpacing)

			if pattern == 1 then
				local offsetX = (i % 2 == 0) and 6 or -6
				createPart(Vector3.new(7, 1.5, 7), CFrame.new(offsetX, 5, stepZ), biome.Color, biome.Material, stageFolder)
				local laser = createPart(Vector3.new(18, 0.6, 0.6), CFrame.new(0, 6.2, stepZ + (stepSpacing * 0.5)), biome.KillColor, Enum.Material.Neon, stageFolder)
				CollectionService:AddTag(laser, "KillBrick")

			elseif pattern == 2 then
				local fadePart = createPart(Vector3.new(8, 1.5, 8), CFrame.new(0, 5, stepZ), biome.Color, Enum.Material.ForceField, stageFolder)
				CollectionService:AddTag(fadePart, "FadeBrick")

			elseif pattern == 3 then
				createPart(Vector3.new(4.5, 1.5, stepSpacing), CFrame.new(0, 5, stepZ), biome.Color, biome.Material, stageFolder)
				-- El movimiento lo ejecuta GameManager solo en etapas cercanas (sin Tweens globales)
				local mover = createPart(Vector3.new(3, 4, 2), CFrame.new(0, 7.5, stepZ), biome.KillColor, Enum.Material.Neon, stageFolder)
				mover.Name = "MovingKill"
				mover:SetAttribute("Stage", stage)
				mover:SetAttribute("BaseCF", mover.CFrame)
				mover:SetAttribute("Amp", 8)
				mover:SetAttribute("Speed", math.pi / (1.5 - (biomeIndex * 0.15)))
				mover:SetAttribute("Phase", i * 0.8)
				CollectionService:AddTag(mover, "KillBrick")
				CollectionService:AddTag(mover, "MovingKill")

			elseif pattern == 4 then
				local safeLeft = ((stage + i) % 2 == 0)
				local leftBlock = createPart(Vector3.new(6, 1.5, 8), CFrame.new(-4.5, 5, stepZ), biome.Color, biome.Material, stageFolder)
				local rightBlock = createPart(Vector3.new(6, 1.5, 8), CFrame.new(4.5, 5, stepZ), biome.Color, biome.Material, stageFolder)
				CollectionService:AddTag(safeLeft and rightBlock or leftBlock, "KillBrick")

			elseif pattern == 5 then
				createPart(Vector3.new(16, 1.5, stepSpacing + 2), CFrame.new(0, 5, stepZ), biome.Color, biome.Material, stageFolder)
				if i == 3 then
					createLocker(CFrame.new(6, 9.5, stepZ), stageFolder)
				elseif i % 2 == 0 then
					local hurdle = createPart(Vector3.new(16, 2.5, 1.2), CFrame.new(0, 7, stepZ), biome.KillColor, Enum.Material.Neon, stageFolder)
					CollectionService:AddTag(hurdle, "KillBrick")
				end
			end
		end
	end

	currentZ = currentZ - STAGE_LENGTH
end

-- Plataforma de victoria
local winPod = createPart(Vector3.new(24, 2, 24), CFrame.new(0, 5, currentZ), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, checkpointsFolder)
winPod.Name = "150_WIN"

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

-- Vacío mortal
local voidKill = createPart(Vector3.new(600, 8, math.abs(currentZ) + 500), CFrame.new(0, -35, currentZ / 2), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, mapFolder)
voidKill.Name = "VoidKill"
voidKill.Transparency = 1
CollectionService:AddTag(voidKill, "KillBrick")

-- Señal para que GameManager sepa que el mapa está completo
workspace:SetAttribute("MapReady", true)
