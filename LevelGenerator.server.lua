-- LevelGenerator.server.lua
-- Ubicación: ServerScriptService.LevelGenerator
-- Genera etapas largas con 10 diseños distintos, Grandes Arenas de Batalla con manadas de criaturas,
-- iluminación clara y agradable, y un Valle Escénico completo debajo del mapa.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- 1. PISO DE APARICIÓN INMEDIATO
local mainSpawn = Workspace:FindFirstChild("MainSafetySpawn")
if not mainSpawn then
	mainSpawn = Instance.new("SpawnLocation")
	mainSpawn.Name = "MainSafetySpawn"
	mainSpawn.Size = Vector3.new(58, 2, 58)
	mainSpawn.CFrame = CFrame.new(0, 9, 0)
	mainSpawn.Color = Color3.fromRGB(110, 88, 95)
	mainSpawn.Material = Enum.Material.Cobblestone
	mainSpawn.Anchored = true
	mainSpawn.CanCollide = true
	mainSpawn.Neutral = true
	mainSpawn.Duration = 0
	mainSpawn.Parent = Workspace
end

-- 2. ILUMINACIÓN CLARA Y AGRADABLE DE ATARDECER DE HALLOWEEN
pcall(function()
	Lighting.ClockTime = 17.6
	Lighting.Brightness = 3.2
	Lighting.Ambient = Color3.fromRGB(145, 130, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 150, 180)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 210, 165)

	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.StarCount = 60
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(195, 120, 95)
	atmosphere.Decay = Color3.fromRGB(95, 60, 110)
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
end)

local ProceduralModels = require(ReplicatedStorage:WaitForChild("ProceduralModels"))

local mapFolder = Workspace:FindFirstChild("ObbyMap") or Instance.new("Folder")
mapFolder.Name = "ObbyMap"
mapFolder.Parent = Workspace

local checkpointsFolder = Workspace:FindFirstChild("Checkpoints") or Instance.new("Folder")
checkpointsFolder.Name = "Checkpoints"
checkpointsFolder.Parent = Workspace

local monstersFolder = Workspace:FindFirstChild("Monsters") or Instance.new("Folder")
monstersFolder.Name = "Monsters"
monstersFolder.Parent = Workspace

local closetsFolder = Workspace:FindFirstChild("HidingClosets") or Instance.new("Folder")
closetsFolder.Name = "HidingClosets"
closetsFolder.Parent = Workspace

-- 5 Biomas bien diferenciados y luminosos
local BIOMES = {
	{
		Name = "Avenida de Otoño",
		MaxStage = 30,
		Color = Color3.fromRGB(175, 110, 70),
		ValleyColor = Color3.fromRGB(85, 55, 40),
		NeonColor = Color3.fromRGB(255, 150, 40),
		Mat = Enum.Material.Cobblestone,
		BossName = "JEFE: El Carnicero del Cine"
	},
	{
		Name = "Fortaleza Esmeralda",
		MaxStage = 60,
		Color = Color3.fromRGB(85, 135, 100),
		ValleyColor = Color3.fromRGB(45, 75, 55),
		NeonColor = Color3.fromRGB(70, 255, 130),
		Mat = Enum.Material.Slate,
		BossName = "JEFE: El Guardián Tóxico"
	},
	{
		Name = "Bosque de las Brujas",
		MaxStage = 90,
		Color = Color3.fromRGB(135, 90, 160),
		ValleyColor = Color3.fromRGB(70, 45, 90),
		NeonColor = Color3.fromRGB(205, 85, 255),
		Mat = Enum.Material.Grass,
		BossName = "JEFE: Señor de las Calabazas"
	},
	{
		Name = "Ciudadela Cibernética",
		MaxStage = 120,
		Color = Color3.fromRGB(110, 145, 175),
		ValleyColor = Color3.fromRGB(55, 75, 95),
		NeonColor = Color3.fromRGB(60, 210, 255),
		Mat = Enum.Material.DiamondPlate,
		BossName = "JEFE: Titán Mecánico 120"
	},
	{
		Name = "Volcán del Rey Demonio",
		MaxStage = 150,
		Color = Color3.fromRGB(185, 65, 65),
		ValleyColor = Color3.fromRGB(95, 30, 30),
		NeonColor = Color3.fromRGB(255, 60, 40),
		Mat = Enum.Material.Brick,
		BossName = "JEFE FINAL: Rey del Abismo"
	}
}

local VARIANTS = {"Stalker", "Brute", "Wraith"}

local function getBiomeForStage(stage)
	for _, biome in ipairs(BIOMES) do
		if stage <= biome.MaxStage then
			return biome
		end
	end
	return BIOMES[#BIOMES]
end

local function createStagePart(name, size, cframe, color, mat, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = mat
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawnMonsterPack(centerPos, count, stage, parent)
	for i = 1, count do
		local variant = VARIANTS[((stage + i) % #VARIANTS) + 1]
		local speed = (variant == "Brute") and 14.5 or ((variant == "Wraith") and 18.5 or 16.5)
		local prefix = (variant == "Brute") and "Carnicero" or ((variant == "Wraith") and "Espectro" or "Acechador")
		local xOff = (i - 1 - (count - 1) / 2) * 8
		local zOff = (i % 2 == 0) and -6 or 6
		local spawnPos = centerPos + Vector3.new(xOff, 4.5, zOff)

		ProceduralModels.CreateR6Monster(
			string.format("%s [Nv.%d]", prefix, stage),
			spawnPos,
			centerPos.Z - 42,
			centerPos.Z + 42,
			speed,
			parent,
			variant
		)
	end
end

local function generateMap()
	mapFolder:ClearAllChildren()
	checkpointsFolder:ClearAllChildren()
	monstersFolder:ClearAllChildren()
	closetsFolder:ClearAllChildren()

	local currentPos = Vector3.new(0, 10, 0)

	pcall(function()
		ProceduralModels.CreateCinemaFacade(CFrame.new(currentPos), mapFolder)
	end)

	for stage = 1, 150 do
		local biome = getBiomeForStage(stage)
		local checkpointCFrame = CFrame.new(currentPos)

		-- 1. Crear Checkpoint amplio con farola y cartel de Bioma
		ProceduralModels.CreateCheckpoint(stage, checkpointCFrame, biome, checkpointsFolder)

		-- 2. Generar Valle Escénico Inferior (Ríos brillantes, montañas, castillos)
		if stage % 2 == 1 then
			ProceduralModels.CreateValleyScenery(currentPos, biome, mapFolder)
		end

		-- 3. Colocar Armario de Supervivencia en plataforma lateral cada 3 etapas
		if stage % 3 == 0 then
			createStagePart(
				"ClosetSidePad_" .. stage,
				Vector3.new(10, 1.4, 10),
				checkpointCFrame * CFrame.new(13, 0, 0),
				biome.Color,
				biome.Mat,
				mapFolder
			)
			ProceduralModels.CreateHidingCloset(
				checkpointCFrame * CFrame.new(13, 0.7, 0) * CFrame.Angles(0, math.rad(-90), 0),
				closetsFolder
			)
		end

		-- 4. Construir Etapas Largas con 8 Arquetipos Distintos y Grandes Arenas de Batalla
		if stage < 150 then
			local stageType = (stage % 8) + 1

			if stage % 30 == 0 then
				-- ARENA GIGANTE DE JEFE DE BIOMA + GUARDIAS
				local arenaCenter = currentPos + Vector3.new(0, 0, -52)
				createStagePart("BossBridge_" .. stage, Vector3.new(14, 1.5, 28), CFrame.new(currentPos + Vector3.new(0, 0, -18)), biome.Color, biome.Mat, mapFolder)
				createStagePart("BossColiseum_" .. stage, Vector3.new(52, 2, 56), CFrame.new(arenaCenter), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(currentPos + Vector3.new(0, 0.75, -26)), biome.Color, biome.NeonColor, mapFolder)

				-- Pilares de cobertura en el coliseo
				for _, px in ipairs({-18, 18}) do
					for _, pz in ipairs({-16, 16}) do
						createStagePart("ArenaPillar", Vector3.new(4, 14, 4), CFrame.new(arenaCenter + Vector3.new(px, 7, pz)), Color3.fromRGB(60, 55, 68), Enum.Material.Slate, mapFolder)
					end
				end

				ProceduralModels.CreateR6Monster(biome.BossName, arenaCenter + Vector3.new(0, 5.5, 0), arenaCenter.Z - 26, arenaCenter.Z + 26, 16.5, monstersFolder, "Boss", 2.0)
				spawnMonsterPack(arenaCenter + Vector3.new(0, 0, -10), 2, stage, monstersFolder)

				currentPos = currentPos + Vector3.new(0, 0, -96)

			elseif stageType == 1 or stageType == 5 then
				-- ARQUETIPO A: GRAN ARENA DE COMBATE LIBRE (Manada de 3 criaturas + Pilares + Arco Gótico)
				createStagePart("EntryWalk_" .. stage, Vector3.new(12, 1.4, 24), CFrame.new(currentPos + Vector3.new(0, 0, -16)), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(currentPos + Vector3.new(0, 0.7, -26)), biome.Color, biome.NeonColor, mapFolder)

				local arenaCenter = currentPos + Vector3.new(0, 0, -56)
				createStagePart("BattleArena_" .. stage, Vector3.new(38, 1.6, 52), CFrame.new(arenaCenter), biome.Color, biome.Mat, mapFolder)

				-- Muros bajos laterales y árboles decorativos
				for _, side in ipairs({-1, 1}) do
					createStagePart("ArenaWall", Vector3.new(2, 4, 48), CFrame.new(arenaCenter + Vector3.new(side * 18, 2, 0)), Color3.fromRGB(65, 58, 72), Enum.Material.Brick, mapFolder)
					ProceduralModels.CreateSpookyTree(CFrame.new(arenaCenter + Vector3.new(side * 15, 0.8, -15)), biome.NeonColor, mapFolder)
				end

				-- Spawnear 3 criaturas en la Arena para pelear libremente
				spawnMonsterPack(arenaCenter, 3, stage, monstersFolder)

				createStagePart("ExitWalk_" .. stage, Vector3.new(12, 1.4, 22), CFrame.new(currentPos + Vector3.new(0, 0, -90)), biome.Color, biome.Mat, mapFolder)
				currentPos = currentPos + Vector3.new(0, 0, -108)

			elseif stageType == 2 then
				-- ARQUETIPO B: BULEVAR ASEDIADO (Calle larga con fachadas de edificios, farolas, láseres y 2 monstruos)
				local streetCenter = currentPos + Vector3.new(0, 0, -52)
				createStagePart("Boulevard_" .. stage, Vector3.new(18, 1.5, 88), CFrame.new(streetCenter), biome.Color, biome.Mat, mapFolder)

				for _, side in ipairs({-1, 1}) do
					createStagePart("BuildingFacade", Vector3.new(6, 22, 36), CFrame.new(streetCenter + Vector3.new(side * 14, 11, 0)), Color3.fromRGB(55, 45, 58), Enum.Material.Brick, mapFolder)
					ProceduralModels.CreateStreetLamp(CFrame.new(streetCenter + Vector3.new(side * 7.5, 0.75, -20)), biome.NeonColor, mapFolder)
				end

				for i = 1, 3 do
					local laser = createStagePart("KillLaser", Vector3.new(18, 0.7, 0.7), CFrame.new(currentPos + Vector3.new(0, 2.2, -22 * i)), Color3.fromRGB(255, 25, 25), Enum.Material.Neon, mapFolder)
					laser.CanCollide = false
					laser:SetAttribute("IsHazard", true)
				end

				spawnMonsterPack(streetCenter, 2, stage, monstersFolder)
				currentPos = currentPos + Vector3.new(0, 0, -104)

			elseif stageType == 3 then
				-- ARQUETIPO C: CAÑÓN DE SALTOS Y PLATAFORMA DE COMBATE INTERMEDIA
				for step = 1, 3 do
					local xOff = (step % 2 == 0) and 4.5 or -4.5
					createStagePart("JumpStone_" .. step, Vector3.new(8, 1.4, 8), CFrame.new(currentPos + Vector3.new(xOff, step * 0.6, -step * 12)), biome.Color, biome.Mat, mapFolder)
				end

				local midArena = currentPos + Vector3.new(0, 2, -64)
				createStagePart("MidCombatDeck_" .. stage, Vector3.new(28, 1.5, 36), CFrame.new(midArena), biome.Color, biome.Mat, mapFolder)
				spawnMonsterPack(midArena, 2, stage, monstersFolder)

				for step = 1, 2 do
					createStagePart("ExitStone_" .. step, Vector3.new(8, 1.4, 8), CFrame.new(midArena + Vector3.new(0, 0, -18 - step * 12)), biome.Color, biome.Mat, mapFolder)
				end
				currentPos = currentPos + Vector3.new(0, 2, -116)

			elseif stageType == 4 then
				-- ARQUETIPO D: TOBOGÁN GIGANTE + FOSO DE EMBOSCADA AL FINAL
				local slideLen = 48
				ProceduralModels.CreateSlide(CFrame.new(currentPos + Vector3.new(0, 0, -6)), slideLen, mapFolder)
				local dropY = -math.sin(math.rad(22)) * slideLen
				local advanceZ = -math.cos(math.rad(22)) * slideLen - 6

				local pitCenter = currentPos + Vector3.new(0, dropY, advanceZ - 26)
				createStagePart("AmbushPit_" .. stage, Vector3.new(32, 1.6, 44), CFrame.new(pitCenter), biome.Color, biome.Mat, mapFolder)
				spawnMonsterPack(pitCenter, 3, stage, monstersFolder)

				currentPos = pitCenter + Vector3.new(0, 0, -30)

			elseif stageType == 6 then
				-- ARQUETIPO E: ESCALINATA AL TEMPLO MALDITO + PLAZA EN LA CIMA
				local steps = 12
				ProceduralModels.CreateStaircase(CFrame.new(currentPos + Vector3.new(0, 0, -6)), steps, biome.Color, mapFolder)
				local topPos = currentPos + Vector3.new(0, steps * 1.2, -(steps * 3 + 6))

				local templeCenter = topPos + Vector3.new(0, 0, -26)
				createStagePart("TemplePlaza_" .. stage, Vector3.new(34, 1.6, 42), CFrame.new(templeCenter), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(templeCenter + Vector3.new(0, 0.8, 16)), biome.Color, biome.NeonColor, mapFolder)
				spawnMonsterPack(templeCenter, 3, stage, monstersFolder)

				currentPos = templeCenter + Vector3.new(0, 0, -30)

			elseif stageType == 7 then
				-- ARQUETIPO F: PUENTE GEMELO SOBRE FOSO DE LAVA + FORTALEZA CENTRAL
				for _, xSide in ipairs({-6, 6}) do
					createStagePart("TwinBridge", Vector3.new(6, 1.2, 42), CFrame.new(currentPos + Vector3.new(xSide, 0, -26)), biome.Color, biome.Mat, mapFolder)
				end
				local fortCenter = currentPos + Vector3.new(0, 0, -68)
				createStagePart("CentralFort_" .. stage, Vector3.new(32, 1.6, 38), CFrame.new(fortCenter), biome.Color, biome.Mat, mapFolder)
				spawnMonsterPack(fortCenter, 2, stage, monstersFolder)

				currentPos = fortCenter + Vector3.new(0, 0, -28)

			else
				-- ARQUETIPO G: SENDERO DEL PANTANO CON ÁRBOLES Y EMBOSCADA
				local marshCenter = currentPos + Vector3.new(0, 0, -48)
				createStagePart("MarshBoardwalk_" .. stage, Vector3.new(24, 1.4, 80), CFrame.new(marshCenter), Color3.fromRGB(95, 65, 42), Enum.Material.WoodPlanks, mapFolder)
				for _, side in ipairs({-1, 1}) do
					ProceduralModels.CreateSpookyTree(CFrame.new(marshCenter + Vector3.new(side * 10, 0.7, -18)), biome.NeonColor, mapFolder)
					ProceduralModels.CreateSpookyTree(CFrame.new(marshCenter + Vector3.new(side * 10, 0.7, 18)), biome.NeonColor, mapFolder)
				end
				spawnMonsterPack(marshCenter, 3, stage, monstersFolder)
				currentPos = currentPos + Vector3.new(0, 0, -96)
			end
		else
			-- GRAN COLISEO DE VICTORIA EN ETAPA 150
			local finishPlatform = createStagePart(
				"VictoryPlatform",
				Vector3.new(40, 2, 40),
				CFrame.new(currentPos + Vector3.new(0, 0, -28)),
				Color3.fromRGB(255, 200, 45),
				Enum.Material.Neon,
				mapFolder
			)
		end

		if stage % 30 == 0 then
			task.wait()
		end
	end

	print("[LevelGenerator] 150 etapas largas, Arenas de Batalla, manadas de monstruos y Valle Escénico generados.")
end

generateMap()
