-- LevelGenerator.server.lua
-- Ubicación: ServerScriptService.LevelGenerator
-- Genera etapas con gran verticalidad (subidas, bajadas, saltos, trampolines, toboganes,
-- láseres giratorios, plataformas móviles) + Tormenta de Rayos y Truenos en vivo.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local mainSpawn = Workspace:FindFirstChild("MainSafetySpawn")
if not mainSpawn then
	mainSpawn = Instance.new("SpawnLocation")
	mainSpawn.Name = "MainSafetySpawn"
	mainSpawn.Size = Vector3.new(54, 2, 54)
	mainSpawn.CFrame = CFrame.new(0, 9, 0)
	mainSpawn.Color = Color3.fromRGB(110, 88, 95)
	mainSpawn.Material = Enum.Material.Cobblestone
	mainSpawn.Anchored = true
	mainSpawn.CanCollide = true
	mainSpawn.Neutral = true
	mainSpawn.Duration = 0
	mainSpawn.Parent = Workspace
end

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

local BIOMES = {
	{
		Name = "Avenida de Otoño",
		MaxStage = 30,
		Color = Color3.fromRGB(175, 110, 70),
		ValleyColor = Color3.fromRGB(85, 55, 40),
		NeonColor = Color3.fromRGB(255, 150, 40),
		Mat = Enum.Material.Cobblestone,
		BossName = "JEFE: Carnicero del Cine"
	},
	{
		Name = "Fortaleza Esmeralda",
		MaxStage = 60,
		Color = Color3.fromRGB(85, 135, 100),
		ValleyColor = Color3.fromRGB(45, 75, 55),
		NeonColor = Color3.fromRGB(70, 255, 130),
		Mat = Enum.Material.Slate,
		BossName = "JEFE: Guardián Tóxico"
	},
	{
		Name = "Bosque de las Brujas",
		MaxStage = 90,
		Color = Color3.fromRGB(135, 90, 160),
		ValleyColor = Color3.fromRGB(70, 45, 90),
		NeonColor = Color3.fromRGB(205, 85, 255),
		Mat = Enum.Material.Grass,
		BossName = "JEFE: Señor Calabaza"
	},
	{
		Name = "Ciudadela Cibernética",
		MaxStage = 120,
		Color = Color3.fromRGB(110, 145, 175),
		ValleyColor = Color3.fromRGB(55, 75, 95),
		NeonColor = Color3.fromRGB(60, 210, 255),
		Mat = Enum.Material.DiamondPlate,
		BossName = "JEFE: Titán Mecánico"
	},
	{
		Name = "Volcán del Rey Demonio",
		MaxStage = 150,
		Color = Color3.fromRGB(185, 65, 65),
		ValleyColor = Color3.fromRGB(95, 30, 30),
		NeonColor = Color3.fromRGB(255, 60, 40),
		Mat = Enum.Material.Brick,
		BossName = "JEFE FINAL: Rey Demonio"
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
		local speed = (variant == "Brute") and 15 or ((variant == "Wraith") and 19 or 17)
		local prefix = (variant == "Brute") and "Carnicero" or ((variant == "Wraith") and "Espectro" or "Acechador")
		local xOff = (i - 1 - (count - 1) / 2) * 8
		local zOff = (i % 2 == 0) and -6 or 6
		local spawnPos = centerPos + Vector3.new(xOff, 4.0, zOff)

		ProceduralModels.CreateR6Monster(
			string.format("%s Nv.%d", prefix, stage),
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

		ProceduralModels.CreateCheckpoint(stage, checkpointCFrame, biome, checkpointsFolder)

		if stage % 2 == 1 then
			ProceduralModels.CreateValleyScenery(currentPos, biome, mapFolder)
		end

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

		if stage < 150 then
			-- 6 Patrones de Etapa con Subidas, Bajadas, Toboganes, Saltos y Arenas de Horda
			local pattern = ((stage - 1) % 6) + 1

			if stage % 30 == 0 then
				-- GRAN COLISEO ELEVADO DE JEFE DE BIOMA
				ProceduralModels.CreateStaircase(CFrame.new(currentPos + Vector3.new(0, 0, -8)), 10, biome.Color, biome.NeonColor, mapFolder)
				local arenaCenter = currentPos + Vector3.new(0, 14, -68)
				createStagePart("BossColiseum_" .. stage, Vector3.new(50, 2, 54), CFrame.new(arenaCenter), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(arenaCenter + Vector3.new(0, 1, 24)), biome.Color, biome.NeonColor, mapFolder)

				ProceduralModels.CreateR6Monster(biome.BossName, arenaCenter + Vector3.new(0, 5, 0), arenaCenter.Z - 25, arenaCenter.Z + 25, 17, monstersFolder, "Boss", 1.9)
				spawnMonsterPack(arenaCenter + Vector3.new(0, 0, -10), 2, stage, monstersFolder)

				currentPos = arenaCenter + Vector3.new(0, 0, -38)

			elseif pattern == 1 then
				-- PATRÓN 1 (ETAPA 1): ESCALADA CON LÁSERES GIRATORIOS + TRAMPOLÍN + ARENA EN ALTURA + TOBOGÁN
				ProceduralModels.CreateStaircase(CFrame.new(currentPos + Vector3.new(0, 0, -8)), 8, biome.Color, biome.NeonColor, mapFolder)
				local midDeck = currentPos + Vector3.new(0, 11.2, -46)
				createStagePart("HighWalk_" .. stage, Vector3.new(14, 1.5, 26), CFrame.new(midDeck), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateSpinningLaser(CFrame.new(midDeck), 13, mapFolder)

				-- Trampolín de Súper Salto hacia la Arena Superior
				ProceduralModels.CreateBouncePad(CFrame.new(midDeck + Vector3.new(0, 0.8, -10)), 82, mapFolder)

				local highArena = midDeck + Vector3.new(0, 12, -44)
				createStagePart("SkyArena_" .. stage, Vector3.new(36, 1.6, 44), CFrame.new(highArena), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(highArena + Vector3.new(0, 0.8, 19)), biome.Color, biome.NeonColor, mapFolder)
				spawnMonsterPack(highArena, 3, stage, monstersFolder)

				currentPos = highArena + Vector3.new(0, 0, -32)

			elseif pattern == 2 then
				-- PATRÓN 2 (ETAPA 2): MEGA TOBOGÁN EXTREMO CON BARRERAS + RAMPA DE VUELO + FOSO DE COMBATE
				local _, dropY, advZ = ProceduralModels.CreateSlide(
					CFrame.new(currentPos + Vector3.new(0, 0, -8)),
					54,
					biome.NeonColor,
					mapFolder
				)

				local pitCenter = currentPos + Vector3.new(0, dropY + 4, advZ - 42)
				createStagePart("SlideLandingArena_" .. stage, Vector3.new(38, 1.8, 48), CFrame.new(pitCenter), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateSpinningLaser(CFrame.new(pitCenter + Vector3.new(0, 0, 12)), 16, mapFolder)
				spawnMonsterPack(pitCenter, 3, stage, monstersFolder)

				currentPos = pitCenter + Vector3.new(0, 0, -34)

			elseif pattern == 3 then
				-- PATRÓN 3 (ETAPA 3): SALTOS ASCENDENTES EN ZIG-ZAG + PLATAFORMA MÓVIL + TEMPLO
				for step = 1, 4 do
					local xSide = (step % 2 == 0) and 6 or -6
					local padPos = currentPos + Vector3.new(xSide, step * 3.2, -step * 11)
					createStagePart("ZigZagJump_" .. step, Vector3.new(8.5, 1.4, 8.5), CFrame.new(padPos), biome.Color, biome.Mat, mapFolder)
				end

				local moveStart = currentPos + Vector3.new(0, 14, -56)
				local moveEnd = currentPos + Vector3.new(0, 20, -76)
				ProceduralModels.CreateMovingPlatform(CFrame.new(moveStart), CFrame.new(moveEnd), 3.0, biome.NeonColor, Enum.Material.Neon, mapFolder)

				local templeArena = currentPos + Vector3.new(0, 20, -108)
				createStagePart("TempleArena_" .. stage, Vector3.new(36, 1.6, 44), CFrame.new(templeArena), biome.Color, biome.Mat, mapFolder)
				spawnMonsterPack(templeArena, 3, stage, monstersFolder)

				currentPos = templeArena + Vector3.new(0, 0, -32)

			elseif pattern == 4 then
				-- PATRÓN 4 (ETAPA 4): PUENTE DE CRISTALES INTERMITENTES + DESCENSO EN CASCADA + COLISEO
				for i = 1, 3 do
					local bridgePos = currentPos + Vector3.new((i % 2 == 0) and 4 or -4, -i * 2.5, -i * 13)
					local glass = createStagePart("FadingBridge_" .. i, Vector3.new(9, 1.2, 9), CFrame.new(bridgePos), biome.NeonColor, Enum.Material.Neon, mapFolder)
					glass:SetAttribute("FadingPlatform", true)
				end

				local lowerArena = currentPos + Vector3.new(0, -10, -72)
				createStagePart("LowerColiseum_" .. stage, Vector3.new(40, 1.8, 50), CFrame.new(lowerArena), biome.Color, biome.Mat, mapFolder)
				for _, side in ipairs({-1, 1}) do
					ProceduralModels.CreateSpookyTree(CFrame.new(lowerArena + Vector3.new(side * 16, 0.9, -12)), biome.NeonColor, mapFolder)
				end
				spawnMonsterPack(lowerArena, 4, stage, monstersFolder)

				currentPos = lowerArena + Vector3.new(0, 0, -35)

			elseif pattern == 5 then
				-- PATRÓN 5 (ETAPA 5): DOBLE TRAMPOLÍN AÉREO + ISLAS FLOTANTES + TOBOGÁN DE BAJADA
				ProceduralModels.CreateBouncePad(CFrame.new(currentPos + Vector3.new(0, 0.5, -10)), 88, mapFolder)

				local skyIsland1 = currentPos + Vector3.new(0, 16, -38)
				createStagePart("SkyIsland1_" .. stage, Vector3.new(22, 1.6, 24), CFrame.new(skyIsland1), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateSpinningLaser(CFrame.new(skyIsland1), 15, mapFolder)

				ProceduralModels.CreateBouncePad(CFrame.new(skyIsland1 + Vector3.new(0, 0.8, -9)), 88, mapFolder)

				local skyIsland2 = skyIsland1 + Vector3.new(0, 14, -38)
				createStagePart("SkyIsland2_" .. stage, Vector3.new(36, 1.8, 42), CFrame.new(skyIsland2), biome.Color, biome.Mat, mapFolder)
				spawnMonsterPack(skyIsland2, 3, stage, monstersFolder)

				local _, dropY, advZ = ProceduralModels.CreateSlide(CFrame.new(skyIsland2 + Vector3.new(0, 0, -22)), 42, biome.NeonColor, mapFolder)
				currentPos = skyIsland2 + Vector3.new(0, dropY, -22 + advZ - 14)

			else
				-- PATRÓN 6 (ETAPA 6): GRAN FORTALEZA CON RAMPAS LATERALES, LÁSERES Y HORDA
				local rampUp = createStagePart(
					"CastleRampUp_" .. stage,
					Vector3.new(14, 1.4, 34),
					CFrame.new(currentPos + Vector3.new(0, 5.5, -22)) * CFrame.Angles(math.rad(19), 0, 0),
					biome.Color,
					biome.Mat,
					mapFolder
				)

				local fortPos = currentPos + Vector3.new(0, 11, -64)
				createStagePart("FortressDeck_" .. stage, Vector3.new(42, 1.8, 52), CFrame.new(fortPos), biome.Color, biome.Mat, mapFolder)
				ProceduralModels.CreateGothicArch(CFrame.new(fortPos + Vector3.new(0, 0.9, 22)), biome.Color, biome.NeonColor, mapFolder)
				ProceduralModels.CreateSpinningLaser(CFrame.new(fortPos + Vector3.new(-10, 0, 0)), 14, mapFolder)
				ProceduralModels.CreateSpinningLaser(CFrame.new(fortPos + Vector3.new(10, 0, 0)), 14, mapFolder)

				spawnMonsterPack(fortPos, 4, stage, monstersFolder)
				currentPos = fortPos + Vector3.new(0, 0, -36)
			end
		else
			createStagePart(
				"VictoryPlatform",
				Vector3.new(44, 2, 44),
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

	print("[LevelGenerator] 150 etapas verticales con toboganes, trampolines, láseres giratorios y hordas listas.")
end

generateMap()

-- ============================================================================
-- SISTEMA DE TORMENTA ELÉCTRICA EN VIVO (RAYOS RAMIFICADOS 3D Y TRUENOS)
-- ============================================================================
local function spawnLightningBolt(targetPos)
	local boltModel = Instance.new("Model")
	boltModel.Name = "SkyLightningBolt"

	local currentPoint = targetPos + Vector3.new(math.random(-25, 25), 140, math.random(-25, 25))
	local segments = 8
	local stepY = -140 / segments

	for i = 1, segments do
		local nextPoint = Vector3.new(
			currentPoint.X + math.random(-9, 9),
			currentPoint.Y + stepY,
			currentPoint.Z + math.random(-9, 9)
		)
		local dist = (nextPoint - currentPoint).Magnitude
		local seg = Instance.new("Part")
		seg.Size = Vector3.new(1.4, 1.4, dist)
		seg.CFrame = CFrame.lookAt((currentPoint + nextPoint) / 2, nextPoint)
		seg.Color = Color3.fromRGB(200, 235, 255)
		seg.Material = Enum.Material.Neon
		seg.Anchored = true
		seg.CanCollide = false
		seg.Parent = boltModel
		currentPoint = nextPoint
	end

	-- Sonido de Trueno potente en 3D
	local soundHolder = Instance.new("Part")
	soundHolder.Size = Vector3.new(1, 1, 1)
	soundHolder.Position = targetPos
	soundHolder.Transparency = 1
	soundHolder.Anchored = true
	soundHolder.CanCollide = false
	soundHolder.Parent = boltModel

	local thunder = Instance.new("Sound")
	thunder.SoundId = "rbxassetid://9114221580"
	thunder.PlaybackSpeed = 0.65
	thunder.Volume = 1.0
	thunder.RollOffMaxDistance = 400
	thunder.Parent = soundHolder
	pcall(function()
		thunder:Play()
	end)

	boltModel.Parent = Workspace
	Debris:AddItem(boltModel, 0.35)

	-- Relámpago breve en el cielo
	local oldBrightness = Lighting.Brightness
	Lighting.Brightness = 6.0
	task.delay(0.12, function()
		Lighting.Brightness = oldBrightness
	end)
end

task.spawn(function()
	while true do
		task.wait(math.random(10, 16))
		local playersList = game:GetService("Players"):GetPlayers()
		if #playersList > 0 then
			local randomPlayer = playersList[math.random(1, #playersList)]
			local hrp = randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local strikePos = hrp.Position + Vector3.new(math.random(-55, 55), 0, math.random(-85, -30))
				spawnLightningBolt(strikePos)
			end
		end
	end
end)
