-- LevelGenerator.server.lua
-- Ubicación: ServerScriptService.LevelGenerator
-- Elimina el aspecto de espacio exterior añadiendo Atmosphere, suelo abismal,
-- iluminación visible en todo el piso, 3 variantes de monstruos y 5 Jefes de Bioma.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- 1. PISO DE APARICIÓN INMEDIATO
local mainSpawn = Workspace:FindFirstChild("MainSafetySpawn")
if not mainSpawn then
	mainSpawn = Instance.new("SpawnLocation")
	mainSpawn.Name = "MainSafetySpawn"
	mainSpawn.Size = Vector3.new(54, 2, 54)
	mainSpawn.CFrame = CFrame.new(0, 9, 0)
	mainSpawn.Color = Color3.fromRGB(75, 65, 78)
	mainSpawn.Material = Enum.Material.Cobblestone
	mainSpawn.Anchored = true
	mainSpawn.CanCollide = true
	mainSpawn.Neutral = true
	mainSpawn.Duration = 0
	mainSpawn.Parent = Workspace
end

-- 2. ATMÓSFERA TERRESTRE DE TERROR (Elimina las estrellas debajo del mapa y aclara el piso)
pcall(function()
	Lighting.ClockTime = 21.2
	Lighting.Brightness = 2.0
	Lighting.Ambient = Color3.fromRGB(85, 72, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(105, 88, 115)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 190, 150)

	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.StarCount = 150
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(45, 28, 48)
	atmosphere.Decay = Color3.fromRGB(22, 14, 28)
	atmosphere.Glare = 0
	atmosphere.Haze = 2.2
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

-- Colores más vivos y contrastados para que los pisos nunca se vean negros
local BIOMES = {
	{Name = "Ciudad Apocalíptica de Otoño", MaxStage = 30, Color = Color3.fromRGB(150, 92, 55), Mat = Enum.Material.Cobblestone, BossName = "JEFE: El Carnicero del Cine"},
	{Name = "Alcantarillas Subterráneas", MaxStage = 60, Color = Color3.fromRGB(72, 110, 82), Mat = Enum.Material.Slate, BossName = "JEFE: La Bestia de la Cloaca"},
	{Name = "Bosque Maldito de Calabazas", MaxStage = 90, Color = Color3.fromRGB(115, 75, 130), Mat = Enum.Material.Grass, BossName = "JEFE: El Señor de las Calabazas"},
	{Name = "Laboratorio de Pesadilla", MaxStage = 120, Color = Color3.fromRGB(95, 118, 140), Mat = Enum.Material.DiamondPlate, BossName = "JEFE: Experimento 120"},
	{Name = "Abismo Carmesí", MaxStage = 150, Color = Color3.fromRGB(165, 45, 50), Mat = Enum.Material.Brick, BossName = "JEFE FINAL: El Rey del Abismo"}
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

		ProceduralModels.CreateCheckpoint(stage, checkpointCFrame, biome.Color, checkpointsFolder)

		-- Suelo neblinoso inferior por tramos para bloquear la vista de estrellas hacia abajo
		if stage % 6 == 1 then
			local abyssFloor = Instance.new("Part")
			abyssFloor.Name = "AbyssGround_" .. stage
			abyssFloor.Size = Vector3.new(420, 2, 380)
			abyssFloor.CFrame = CFrame.new(currentPos.X, currentPos.Y - 48, currentPos.Z - 150)
			abyssFloor.Color = Color3.fromRGB(24, 18, 28)
			abyssFloor.Material = Enum.Material.Slate
			abyssFloor.Anchored = true
			abyssFloor.CanCollide = false
			abyssFloor.Parent = mapFolder
		end

		if stage % 4 == 0 then
			local closetPlatform = Instance.new("Part")
			closetPlatform.Name = "ClosetSidePad_" .. stage
			closetPlatform.Size = Vector3.new(8, 1.2, 8)
			closetPlatform.CFrame = checkpointCFrame * CFrame.new(10, 0, 0)
			closetPlatform.Color = biome.Color
			closetPlatform.Material = biome.Mat
			closetPlatform.Anchored = true
			closetPlatform.CanCollide = true
			closetPlatform.Parent = mapFolder

			ProceduralModels.CreateHidingCloset(
				checkpointCFrame * CFrame.new(10, 0.6, 0) * CFrame.Angles(0, math.rad(-90), 0),
				closetsFolder
			)
		end

		-- Spawnear Jefe de Final de Bioma en las etapas 30, 60, 90, 120 y 150
		if stage % 30 == 0 then
			local arena = Instance.new("Part")
			arena.Name = "BossArena_" .. stage
			arena.Size = Vector3.new(28, 1.5, 28)
			arena.CFrame = CFrame.new(currentPos + Vector3.new(0, 0, -20))
			arena.Color = biome.Color
			arena.Material = biome.Mat
			arena.Anchored = true
			arena.CanCollide = true
			arena.Parent = mapFolder

			ProceduralModels.CreateR6Monster(
				biome.BossName,
				currentPos + Vector3.new(0, 5, -20),
				currentPos.Z - 34,
				currentPos.Z - 4,
				16,
				monstersFolder,
				"Boss",
				2.0
			)
		end

		if stage < 150 then
			local obstacleType = stage % 5

			if obstacleType == 1 then
				local bridge = Instance.new("Part")
				bridge.Name = "Corridor_" .. stage
				bridge.Size = Vector3.new(10, 1.2, 46)
				bridge.CFrame = CFrame.new(currentPos + Vector3.new(0, 0, -28))
				bridge.Color = biome.Color
				bridge.Material = biome.Mat
				bridge.Anchored = true
				bridge.CanCollide = true
				bridge.Parent = mapFolder

				-- Guías luminosas laterales para que el puente resalte en la oscuridad
				for _, sideX in ipairs({-4.8, 4.8}) do
					local strip = Instance.new("Part")
					strip.Name = "EdgeLight"
					strip.Size = Vector3.new(0.35, 0.25, 46)
					strip.CFrame = bridge.CFrame * CFrame.new(sideX, 0.65, 0)
					strip.Color = Color3.fromRGB(255, 140, 45)
					strip.Material = Enum.Material.Neon
					strip.Anchored = true
					strip.CanCollide = false
					strip.Parent = mapFolder
				end

				for i = 1, 2 do
					local laser = Instance.new("Part")
					laser.Name = "KillLaser"
					laser.Size = Vector3.new(10, 0.6, 0.6)
					laser.CFrame = CFrame.new(currentPos + Vector3.new(0, 2, -14 * i - 5))
					laser.Color = Color3.fromRGB(255, 20, 20)
					laser.Material = Enum.Material.Neon
					laser.Anchored = true
					laser.CanCollide = false
					laser:SetAttribute("IsHazard", true)
					laser.Parent = mapFolder
				end

				if stage % 5 == 1 then
					local variant = VARIANTS[((math.floor(stage / 5)) % #VARIANTS) + 1]
					local monsterSpeed = (variant == "Brute") and 13 or ((variant == "Wraith") and 18 or 16)
					local labelName = (variant == "Brute") and ("Carnicero_Nv" .. stage)
						or ((variant == "Wraith") and ("Espectro_Nv" .. stage) or ("Acechador_Nv" .. stage))

					ProceduralModels.CreateR6Monster(
						labelName,
						currentPos + Vector3.new(0, 4, -28),
						currentPos.Z - 48,
						currentPos.Z - 8,
						monsterSpeed,
						monstersFolder,
						variant
					)
				end

				currentPos = currentPos + Vector3.new(0, 0, -56)

			elseif obstacleType == 2 then
				for step = 1, 4 do
					local xOffset = (step % 2 == 0) and 3.5 or -3.5
					local pad = Instance.new("Part")
					pad.Name = "JumpPad_" .. stage .. "_" .. step
					pad.Size = Vector3.new(6, 1.2, 6)
					pad.CFrame = CFrame.new(currentPos + Vector3.new(xOffset, step * 0.4, -step * 10.5))
					pad.Color = biome.Color
					pad.Material = biome.Mat
					pad.Anchored = true
					pad.CanCollide = true
					pad.Parent = mapFolder
				end
				currentPos = currentPos + Vector3.new(0, 1.6, -52)

			elseif obstacleType == 3 then
				local slideLength = 36
				ProceduralModels.CreateSlide(CFrame.new(currentPos + Vector3.new(0, 0, -5)), slideLength, mapFolder)
				local dropY = -math.sin(math.rad(25)) * slideLength
				local advanceZ = -math.cos(math.rad(25)) * slideLength - 12
				currentPos = currentPos + Vector3.new(0, dropY, advanceZ)

			elseif obstacleType == 4 then
				local steps = 10
				ProceduralModels.CreateStaircase(CFrame.new(currentPos + Vector3.new(0, 0, -5)), steps, mapFolder)
				currentPos = currentPos + Vector3.new(0, steps * 1.2, -(steps * 2.5 + 12))

			else
				for _, xSide in ipairs({-3.5, 3.5}) do
					local plank = Instance.new("Part")
					plank.Name = "PathPlank_" .. stage
					plank.Size = Vector3.new(4.8, 1.2, 38)
					plank.CFrame = CFrame.new(currentPos + Vector3.new(xSide, 0, -24))
					plank.Color = biome.Color
					plank.Material = biome.Mat
					plank.Anchored = true
					plank.CanCollide = true
					plank.Parent = mapFolder
				end
				currentPos = currentPos + Vector3.new(0, 0, -48)
			end
		else
			local finishPlatform = Instance.new("Part")
			finishPlatform.Name = "VictoryPlatform"
			finishPlatform.Size = Vector3.new(26, 2, 26)
			finishPlatform.CFrame = CFrame.new(currentPos + Vector3.new(0, 0, -24))
			finishPlatform.Color = Color3.fromRGB(255, 195, 40)
			finishPlatform.Material = Enum.Material.Neon
			finishPlatform.Anchored = true
			finishPlatform.CanCollide = true
			finishPlatform.Parent = mapFolder
		end
	end

	print("[LevelGenerator] 150 etapas, atmósfera terrestre, 3 variantes de monstruos y 5 Jefes generados.")
end

generateMap()
