-- LevelGenerator.server.lua
-- Ubicación: ServerScriptService.LevelGenerator
-- Crea un SpawnLocation indestructible en el milisegundo 0, configura la noche de terror
-- y genera las 150 etapas con materiales 100% seguros para bloques.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- 1. PISO DE APARICIÓN INMEDIATO (Evita caer al vacío mientras carga el resto del mapa)
local mainSpawn = Workspace:FindFirstChild("MainSafetySpawn")
if not mainSpawn then
	mainSpawn = Instance.new("SpawnLocation")
	mainSpawn.Name = "MainSafetySpawn"
	mainSpawn.Size = Vector3.new(50, 2, 50)
	mainSpawn.CFrame = CFrame.new(0, 9, 0)
	mainSpawn.Color = Color3.fromRGB(50, 45, 50)
	mainSpawn.Material = Enum.Material.Cobblestone
	mainSpawn.Anchored = true
	mainSpawn.CanCollide = true
	mainSpawn.Neutral = true
	mainSpawn.Duration = 0
	mainSpawn.Parent = Workspace
end

-- 2. ATMÓSFERA NOCTURNA DE TERROR
pcall(function()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0.6
	Lighting.Ambient = Color3.fromRGB(28, 22, 32)
	Lighting.OutdoorAmbient = Color3.fromRGB(35, 25, 35)
	Lighting.FogColor = Color3.fromRGB(15, 10, 18)
	Lighting.FogStart = 35
	Lighting.FogEnd = 260
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

-- 5 Biomas usando exclusivamente materiales clásicos 100% válidos en Part
local BIOMES = {
	{Name = "Ciudad Apocalíptica de Otoño", MaxStage = 30, Color = Color3.fromRGB(115, 65, 35), Mat = Enum.Material.Cobblestone},
	{Name = "Alcantarillas Subterráneas", MaxStage = 60, Color = Color3.fromRGB(45, 70, 50), Mat = Enum.Material.Slate},
	{Name = "Bosque Maldito de Calabazas", MaxStage = 90, Color = Color3.fromRGB(75, 45, 85), Mat = Enum.Material.Grass},
	{Name = "Laboratorio de Pesadilla", MaxStage = 120, Color = Color3.fromRGB(60, 75, 90), Mat = Enum.Material.DiamondPlate},
	{Name = "Abismo Carmesí", MaxStage = 150, Color = Color3.fromRGB(130, 20, 25), Mat = Enum.Material.Brick}
}

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

		if stage % 4 == 0 then
			local closetPlatform = Instance.new("Part")
			closetPlatform.Name = "ClosetSidePad_" .. stage
			closetPlatform.Size = Vector3.new(8, 1.2, 8)
			closetPlatform.CFrame = checkpointCFrame * CFrame.new(9, 0, 0)
			closetPlatform.Color = biome.Color
			closetPlatform.Material = biome.Mat
			closetPlatform.Anchored = true
			closetPlatform.CanCollide = true
			closetPlatform.Parent = mapFolder

			ProceduralModels.CreateHidingCloset(
				checkpointCFrame * CFrame.new(9, 0.6, 0) * CFrame.Angles(0, math.rad(-90), 0),
				closetsFolder
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
					local monsterSpeed = math.clamp(14 + math.floor(stage / 25), 14, 20)
					ProceduralModels.CreateR6Monster(
						"Acechador_Etapa_" .. stage,
						currentPos + Vector3.new(0, 4, -28),
						currentPos.Z - 48,
						currentPos.Z - 8,
						monsterSpeed,
						monstersFolder
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
			finishPlatform.Size = Vector3.new(24, 2, 24)
			finishPlatform.CFrame = CFrame.new(currentPos + Vector3.new(0, 0, -18))
			finishPlatform.Color = Color3.fromRGB(255, 195, 40)
			finishPlatform.Material = Enum.Material.Neon
			finishPlatform.Anchored = true
			finishPlatform.CanCollide = true
			finishPlatform.Parent = mapFolder
		end
	end

	print("[LevelGenerator] Mapa de 150 etapas generado correctamente.")
end

generateMap()
