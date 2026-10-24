-- ProceduralModels.lua
-- Ubicación: ReplicatedStorage.ProceduralModels
-- Corrige el anclaje de los monstruos (Anchored = false real), añade barra de vida chiquita
-- sobre la cabeza, Katana esculpida con Trail, láseres giratorios, trampolines y toboganes.

local TweenService = game:GetService("TweenService")
local ProceduralModels = {}

local function createPart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Name = props.Name or "Part"
	part.Size = props.Size or Vector3.new(4, 1, 4)
	part.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	part.Color = props.Color or Color3.fromRGB(120, 120, 120)
	part.Material = props.Material or Enum.Material.Concrete

	-- Corrección crítica: asignación booleana explícita para que Anchored = false funcione siempre
	if props.Anchored == nil then
		part.Anchored = true
	else
		part.Anchored = props.Anchored
	end

	if props.CanCollide == nil then
		part.CanCollide = true
	else
		part.CanCollide = props.CanCollide
	end

	if props.Massless == nil then
		part.Massless = false
	else
		part.Massless = props.Massless
	end

	part.Transparency = props.Transparency or 0
	if part:IsA("Part") and props.Shape then
		part.Shape = props.Shape
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Parent then
		part.Parent = props.Parent
	end
	return part
end

local function weldParts(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
	return weld
end

function ProceduralModels.CreateStreetLamp(cframe, lightColor, parent)
	local lamp = Instance.new("Model")
	lamp.Name = "StreetLamp"

	createPart({
		Name = "Pole",
		Size = Vector3.new(0.7, 11, 0.7),
		CFrame = cframe * CFrame.new(0, 5.5, 0),
		Color = Color3.fromRGB(35, 35, 42),
		Material = Enum.Material.Metal,
		Parent = lamp
	})

	local bulb = createPart({
		Name = "LanternBulb",
		Size = Vector3.new(1.8, 2.2, 1.8),
		CFrame = cframe * CFrame.new(0, 11.5, 0),
		Color = lightColor or Color3.fromRGB(255, 195, 110),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = lamp
	})

	local pointLight = Instance.new("PointLight")
	pointLight.Color = lightColor or Color3.fromRGB(255, 200, 125)
	pointLight.Brightness = 3.0
	pointLight.Range = 42
	pointLight.Parent = bulb

	lamp.Parent = parent
	return lamp
end

function ProceduralModels.CreateJackOLantern(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "JackOLantern"

	local body = createPart({
		Name = "PumpkinBody",
		Size = Vector3.new(2.8, 2.4, 2.8),
		CFrame = cframe * CFrame.new(0, 1.2, 0),
		Color = Color3.fromRGB(235, 115, 25),
		Material = Enum.Material.SmoothPlastic,
		Parent = model
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body

	createPart({
		Name = "PumpkinEyes",
		Size = Vector3.new(1.9, 1.0, 0.4),
		CFrame = cframe * CFrame.new(0, 1.3, -1.2),
		Color = Color3.fromRGB(255, 220, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model
	})

	model.Parent = parent
	return model
end

function ProceduralModels.CreateSpookyTree(cframe, leafColor, parent)
	local tree = Instance.new("Model")
	tree.Name = "SpookyTree"

	createPart({
		Name = "Trunk",
		Size = Vector3.new(3, 15, 3),
		CFrame = cframe * CFrame.new(0, 7.5, 0) * CFrame.Angles(math.rad(5), 0, math.rad(-4)),
		Color = Color3.fromRGB(55, 38, 28),
		Material = Enum.Material.Wood,
		Parent = tree
	})

	local canopy = createPart({
		Name = "Foliage",
		Size = Vector3.new(13, 7, 13),
		CFrame = cframe * CFrame.new(0, 16, 0),
		Color = leafColor or Color3.fromRGB(205, 85, 30),
		Material = Enum.Material.Grass,
		CanCollide = false,
		Parent = tree
	})
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = canopy

	tree.Parent = parent
	return tree
end

function ProceduralModels.CreateValleyScenery(centerPos, biome, parent)
	local scenery = Instance.new("Model")
	scenery.Name = "ValleyScenery"

	createPart({
		Name = "ValleyFloor",
		Size = Vector3.new(540, 4, 280),
		CFrame = CFrame.new(centerPos.X, centerPos.Y - 55, centerPos.Z - 90),
		Color = biome.ValleyColor,
		Material = biome.Mat,
		CanCollide = false,
		Parent = scenery
	})

	createPart({
		Name = "GlowingRiver",
		Size = Vector3.new(540, 1.5, 30),
		CFrame = CFrame.new(centerPos.X, centerPos.Y - 52.8, centerPos.Z - 90),
		Color = biome.NeonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = scenery
	})

	for _, side in ipairs({-1, 1}) do
		createPart({
			ClassName = "WedgePart",
			Name = "MountainPeak",
			Size = Vector3.new(65, 95, 95),
			CFrame = CFrame.new(centerPos.X + side * 130, centerPos.Y - 5, centerPos.Z - 70)
				* CFrame.Angles(0, math.rad(side * 90), 0),
			Color = biome.Color,
			Material = Enum.Material.Slate,
			CanCollide = false,
			Parent = scenery
		})

		local towerX = centerPos.X + side * 52
		createPart({
			Name = "CastleTower",
			Size = Vector3.new(18, 56, 18),
			CFrame = CFrame.new(towerX, centerPos.Y, centerPos.Z - 45),
			Color = Color3.fromRGB(52, 46, 58),
			Material = Enum.Material.Brick,
			CanCollide = false,
			Parent = scenery
		})

		createPart({
			Name = "TowerWindow",
			Size = Vector3.new(4, 12, 19),
			CFrame = CFrame.new(towerX, centerPos.Y + 14, centerPos.Z - 45),
			Color = biome.NeonColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = scenery
		})
	end

	scenery.Parent = parent
	return scenery
end

function ProceduralModels.CreateGothicArch(cframe, biomeColor, neonColor, parent)
	local arch = Instance.new("Model")
	arch.Name = "GothicArch"

	for _, side in ipairs({-1, 1}) do
		createPart({
			Name = "ArchPillar",
			Size = Vector3.new(2.5, 16, 2.5),
			CFrame = cframe * CFrame.new(side * 7.5, 8, 0),
			Color = biomeColor,
			Material = Enum.Material.Cobblestone,
			Parent = arch
		})
		createPart({
			Name = "TorchFlame",
			Size = Vector3.new(1.2, 2.2, 1.2),
			CFrame = cframe * CFrame.new(side * 6, 10, 0),
			Color = neonColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = arch
		})
	end

	createPart({
		Name = "ArchTopBeam",
		Size = Vector3.new(19, 2.5, 3),
		CFrame = cframe * CFrame.new(0, 16.5, 0),
		Color = biomeColor,
		Material = Enum.Material.Slate,
		Parent = arch
	})

	arch.Parent = parent
	return arch
end

function ProceduralModels.CreateCinemaFacade(originCFrame, parent)
	local model = Instance.new("Model")
	model.Name = "CinemaFacade"

	createPart({
		Name = "CinemaWall",
		Size = Vector3.new(46, 26, 4),
		CFrame = originCFrame * CFrame.new(0, 13, 22),
		Color = Color3.fromRGB(62, 44, 52),
		Material = Enum.Material.Brick,
		Parent = model
	})

	local marquee = createPart({
		Name = "Marquee",
		Size = Vector3.new(32, 6, 3),
		CFrame = originCFrame * CFrame.new(0, 18, 19),
		Color = Color3.fromRGB(220, 35, 45),
		Material = Enum.Material.Neon,
		Parent = model
	})

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.Parent = marquee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🎬 CINE TERROR 150 🎃"
	label.TextColor3 = Color3.fromRGB(255, 245, 210)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	for _, side in ipairs({-18, 18}) do
		createPart({
			Name = "AutumnTent",
			Size = Vector3.new(10, 8, 10),
			CFrame = originCFrame * CFrame.new(side, 4, 8),
			Color = Color3.fromRGB(225, 110, 32),
			Material = Enum.Material.Fabric,
			Parent = model
		})
		ProceduralModels.CreateStreetLamp(originCFrame * CFrame.new(side * 0.75, 0, -6), Color3.fromRGB(255, 195, 110), model)
		ProceduralModels.CreateJackOLantern(originCFrame * CFrame.new(side * 0.55, 0, 2), model)
	end

	model.Parent = parent
	return model
end

function ProceduralModels.CreateCheckpoint(stageNumber, cframe, biome, parent)
	local pad = createPart({
		Name = "Checkpoint_" .. tostring(stageNumber),
		Size = Vector3.new(16, 1.5, 16),
		CFrame = cframe,
		Color = biome.Color,
		Material = Enum.Material.Slate,
		Parent = parent
	})
	pad:SetAttribute("StageNumber", stageNumber)
	pad:SetAttribute("BiomeName", biome.Name)

	createPart({
		Name = "NeonIndicator",
		Size = Vector3.new(16.5, 0.4, 16.5),
		CFrame = cframe * CFrame.new(0, 0.6, 0),
		Color = biome.NeonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pad
	})

	ProceduralModels.CreateStreetLamp(cframe * CFrame.new(-6.8, 0.75, -6.8), biome.NeonColor, pad)
	ProceduralModels.CreateJackOLantern(cframe * CFrame.new(6.5, 0.75, -6.5), pad)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StageSign"
	billboard.Size = UDim2.fromOffset(150, 42)
	billboard.StudsOffset = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 95
	billboard.Parent = pad

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = string.format("ETAPA %d • %s", stageNumber, biome.Name)
	text.TextColor3 = Color3.fromRGB(255, 240, 200)
	text.TextStrokeTransparency = 0.15
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = billboard

	return pad
end

function ProceduralModels.CreateHidingCloset(cframe, parent)
	local closet = Instance.new("Model")
	closet.Name = "HidingCloset"

	local body = createPart({
		Name = "ClosetBody",
		Size = Vector3.new(4.8, 8.5, 3.8),
		CFrame = cframe * CFrame.new(0, 4.25, 0),
		Color = Color3.fromRGB(95, 58, 36),
		Material = Enum.Material.WoodPlanks,
		Parent = closet
	})

	createPart({
		Name = "ClosetVents",
		Size = Vector3.new(3.6, 1.6, 0.2),
		CFrame = cframe * CFrame.new(0, 6.2, 1.85),
		Color = Color3.fromRGB(28, 20, 14),
		Material = Enum.Material.Wood,
		Parent = closet
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HidePrompt"
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Armario de Supervivencia"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	closet.PrimaryPart = body
	closet.Parent = parent
	return closet
end

-- Tobogán Gigante con Rampa de Salto al final y obstáculos esquivables
function ProceduralModels.CreateSlide(startCFrame, length, neonColor, parent)
	local model = Instance.new("Model")
	model.Name = "HorrorSlide"

	local angle = math.rad(-26)
	local slideCFrame = startCFrame * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, -length / 2)

	local ramp = createPart({
		Name = "SlideRamp",
		Size = Vector3.new(14, 1.2, length),
		CFrame = slideCFrame,
		Color = Color3.fromRGB(75, 30, 42),
		Material = Enum.Material.Ice,
		Parent = model
	})

	for _, offset in ipairs({-7.2, 7.2}) do
		createPart({
			Name = "SlideRail",
			Size = Vector3.new(0.9, 3.0, length),
			CFrame = slideCFrame * CFrame.new(offset, 1.4, 0),
			Color = neonColor or Color3.fromRGB(255, 110, 35),
			Material = Enum.Material.Neon,
			Parent = model
		})
	end

	-- Obstáculos de láser a mitad del tobogán (para saltar o esquivar de lado)
	for i = 1, 2 do
		local sideX = (i % 2 == 0) and 3.2 or -3.2
		local barrier = createPart({
			Name = "KillLaser",
			Size = Vector3.new(6.5, 2.5, 0.8),
			CFrame = slideCFrame * CFrame.new(sideX, 1.8, (i == 1) and (length * 0.2) or (-length * 0.2)),
			Color = Color3.fromRGB(255, 25, 40),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = model
		})
		barrier:SetAttribute("IsHazard", true)
	end

	-- Rampa de lanzamiento al final del tobogán (¡Para volar hacia la arena!)
	local dropY = -math.sin(math.rad(26)) * length
	local advanceZ = -math.cos(math.rad(26)) * length
	local launchPad = createPart({
		Name = "BouncePad",
		Size = Vector3.new(14, 1.4, 8),
		CFrame = startCFrame * CFrame.new(0, dropY, advanceZ - 3) * CFrame.Angles(math.rad(18), 0, 0),
		Color = Color3.fromRGB(60, 255, 130),
		Material = Enum.Material.Neon,
		Parent = model
	})
	launchPad:SetAttribute("BouncePower", 78)

	model.Parent = parent
	return model, dropY, advanceZ
end

-- Escalinata Empinada con barandillas iluminadas
function ProceduralModels.CreateStaircase(startCFrame, stepsCount, biomeColor, neonColor, parent)
	local model = Instance.new("Model")
	model.Name = "TerrorStaircase"

	for i = 1, stepsCount do
		createPart({
			Name = "Step_" .. i,
			Size = Vector3.new(12, 1.2, 3.2),
			CFrame = startCFrame * CFrame.new(0, i * 1.4, -i * 3.0),
			Color = biomeColor or Color3.fromRGB(105, 95, 115),
			Material = Enum.Material.Cobblestone,
			Parent = model
		})
		if i % 4 == 0 then
			for _, side in ipairs({-6.2, 6.2}) do
				createPart({
					Name = "StepPost",
					Size = Vector3.new(0.8, 3.5, 0.8),
					CFrame = startCFrame * CFrame.new(side, i * 1.4 + 1.8, -i * 3.0),
					Color = neonColor or Color3.fromRGB(255, 140, 40),
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = model
				})
			end
		end
	end

	model.Parent = parent
	return model
end

-- Trampolín de Súper Salto (BouncePad)
function ProceduralModels.CreateBouncePad(cframe, power, parent)
	local pad = createPart({
		Name = "BouncePad",
		Size = Vector3.new(7.5, 1.2, 7.5),
		CFrame = cframe,
		Color = Color3.fromRGB(50, 255, 140),
		Material = Enum.Material.Neon,
		Parent = parent
	})
	pad:SetAttribute("BouncePower", power or 85)
	return pad
end

-- Obstáculo de Láser Giratorio Animado
function ProceduralModels.CreateSpinningLaser(cframe, length, parent)
	local hub = createPart({
		Name = "SpinnerHub",
		Size = Vector3.new(2.5, 3.5, 2.5),
		CFrame = cframe * CFrame.new(0, 1.75, 0),
		Color = Color3.fromRGB(40, 40, 48),
		Material = Enum.Material.Metal,
		Parent = parent
	})

	local beam = createPart({
		Name = "KillLaser",
		Size = Vector3.new(length or 16, 0.7, 0.7),
		CFrame = cframe * CFrame.new(0, 2.0, 0),
		Color = Color3.fromRGB(255, 20, 50),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = hub
	})
	beam:SetAttribute("IsHazard", true)

	-- Giro continuo suave
	task.spawn(function()
		local angle = 0
		while beam and beam.Parent do
			angle = angle + math.rad(6)
			beam.CFrame = (cframe * CFrame.new(0, 2.0, 0)) * CFrame.Angles(0, angle, 0)
			task.wait(0.04)
		end
	end)

	return hub
end

-- Plataforma Móvil Elevadora (Sube y baja o se mueve de lado a lado)
function ProceduralModels.CreateMovingPlatform(startCF, endCF, duration, color, mat, parent)
	local plat = createPart({
		Name = "MovingPlatform",
		Size = Vector3.new(9, 1.4, 9),
		CFrame = startCF,
		Color = color,
		Material = mat,
		Parent = parent
	})

	local info = TweenInfo.new(duration or 3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(plat, info, {CFrame = endCF}):Play()
	return plat
end

-- ============================================================================
-- CRIATURAS DE TERROR DESBLOQUEADAS (Anchored = false + Barra Chiquita)
-- ============================================================================
function ProceduralModels.CreateR6Monster(name, spawnPos, minZ, maxZ, walkSpeed, parent, variant, customScale)
	local monsterVariant = variant or "Stalker"
	local scale = customScale or ((monsterVariant == "Boss") and 1.9 or ((monsterVariant == "Brute") and 1.3 or 1.05))

	local skinColor = Color3.fromRGB(45, 32, 38)
	local boneColor = Color3.fromRGB(230, 215, 195)
	local glowColor = Color3.fromRGB(255, 30, 30)

	if monsterVariant == "Brute" then
		skinColor = Color3.fromRGB(75, 28, 25)
		glowColor = Color3.fromRGB(255, 115, 20)
	elseif monsterVariant == "Wraith" then
		skinColor = Color3.fromRGB(32, 22, 58)
		glowColor = Color3.fromRGB(195, 55, 255)
	elseif monsterVariant == "Boss" then
		skinColor = Color3.fromRGB(35, 12, 16)
		glowColor = Color3.fromRGB(255, 15, 65)
	end

	local monster = Instance.new("Model")
	monster.Name = name or "Criatura"
	monster:SetAttribute("SpawnPosition", spawnPos)
	monster:SetAttribute("MinZ", minZ)
	monster:SetAttribute("MaxZ", maxZ)
	monster:SetAttribute("BaseSpeed", walkSpeed or 17)
	monster:SetAttribute("StunnedUntil", 0)
	monster:SetAttribute("MonsterVariant", monsterVariant)
	monster:SetAttribute("IsBoss", monsterVariant == "Boss")
	monster:SetAttribute("Scale", scale)

	local hrp = createPart({
		Name = "HumanoidRootPart",
		Size = Vector3.new(2.0 * scale, 2.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(spawnPos),
		Transparency = 1,
		Anchored = false,
		CanCollide = true,
		Parent = monster
	})

	local torso = createPart({
		Name = "Torso",
		Size = Vector3.new(2.3 * scale, 2.7 * scale, 1.4 * scale),
		CFrame = CFrame.new(spawnPos),
		Color = skinColor,
		Material = Enum.Material.Slate,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	local torsoMesh = Instance.new("SpecialMesh")
	torsoMesh.MeshType = Enum.MeshType.Sphere
	torsoMesh.Scale = Vector3.new(1.05, 1.15, 0.9)
	torsoMesh.Parent = torso
	weldParts(hrp, torso)

	local core = createPart({
		Name = "CorruptedHeart",
		Size = Vector3.new(0.95 * scale, 1.1 * scale, 0.55 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 0.25 * scale, -0.55 * scale),
		Color = glowColor,
		Material = Enum.Material.Neon,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	local coreMesh = Instance.new("SpecialMesh")
	coreMesh.MeshType = Enum.MeshType.Sphere
	coreMesh.Parent = core
	weldParts(torso, core)

	for i = -1, 1 do
		local rib = createPart({
			Name = "BoneRib",
			Size = Vector3.new(2.55 * scale, 0.28 * scale, 1.55 * scale),
			CFrame = torso.CFrame * CFrame.new(0, i * 0.62 * scale, -0.05 * scale),
			Color = boneColor,
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local ribMesh = Instance.new("SpecialMesh")
		ribMesh.MeshType = Enum.MeshType.Sphere
		ribMesh.Parent = rib
		weldParts(torso, rib)

		local spike = createPart({
			ClassName = "WedgePart",
			Name = "SpineSpike",
			Size = Vector3.new(0.38 * scale, 1.2 * scale, 0.95 * scale),
			CFrame = torso.CFrame * CFrame.new(0, i * 0.72 * scale, 0.85 * scale) * CFrame.Angles(math.rad(25), 0, 0),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(torso, spike)
	end

	local head = createPart({
		Name = "Head",
		Size = Vector3.new(2.0 * scale, 2.2 * scale, 2.1 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 2.15 * scale, -0.22 * scale),
		Color = boneColor,
		Material = Enum.Material.Slate,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Sphere
	headMesh.Parent = head
	weldParts(torso, head)

	local maw = createPart({
		Name = "OpenMaw",
		Size = Vector3.new(1.4 * scale, 0.95 * scale, 0.6 * scale),
		CFrame = head.CFrame * CFrame.new(0, -0.42 * scale, -0.82 * scale),
		Color = Color3.fromRGB(12, 6, 10),
		Material = Enum.Material.SmoothPlastic,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	weldParts(head, maw)

	for _, xTooth in ipairs({-0.42, -0.14, 0.14, 0.42}) do
		local fang = createPart({
			ClassName = "WedgePart",
			Name = "Fang",
			Size = Vector3.new(0.18 * scale, 0.45 * scale, 0.18 * scale),
			CFrame = maw.CFrame * CFrame.new(xTooth * scale, 0.25 * scale, -0.2 * scale) * CFrame.Angles(math.rad(180), 0, 0),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, fang)
	end

	for _, side in ipairs({-1, 1}) do
		local eye = createPart({
			Name = "HorrorEye",
			Size = Vector3.new(0.4 * scale, 0.34 * scale, 0.24 * scale),
			CFrame = head.CFrame * CFrame.new(side * 0.42 * scale, 0.3 * scale, -0.92 * scale),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, eye)

		local horn = createPart({
			ClassName = "WedgePart",
			Name = "DemonHorn",
			Size = Vector3.new(0.42 * scale, 1.7 * scale, 0.5 * scale),
			CFrame = head.CFrame * CFrame.new(side * 0.78 * scale, 1.2 * scale, 0) * CFrame.Angles(math.rad(-25), 0, math.rad(side * -30)),
			Color = Color3.fromRGB(28, 20, 22),
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, horn)
	end

	-- Brazos articulados con Motor6D (libres de anclaje)
	for _, side in ipairs({-1, 1}) do
		local armName = (side == -1) and "LeftClawArm" or "RightClawArm"
		local arm = createPart({
			Name = armName,
			Size = Vector3.new(0.8 * scale, 3.2 * scale, 0.8 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 1.6 * scale, -0.3 * scale, 0),
			Color = skinColor,
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local armMesh = Instance.new("SpecialMesh")
		armMesh.MeshType = Enum.MeshType.Sphere
		armMesh.Scale = Vector3.new(0.95, 1.1, 0.95)
		armMesh.Parent = arm

		local shoulderMotor = Instance.new("Motor6D")
		shoulderMotor.Name = (side == -1) and "LeftShoulderMotor" or "RightShoulderMotor"
		shoulderMotor.Part0 = torso
		shoulderMotor.Part1 = arm
		shoulderMotor.C0 = CFrame.new(side * 1.5 * scale, 0.85 * scale, 0)
		shoulderMotor.C1 = CFrame.new(0, 1.1 * scale, 0)
		shoulderMotor.Parent = torso

		for c = -1, 1 do
			local claw = createPart({
				ClassName = "WedgePart",
				Name = "RazorClaw",
				Size = Vector3.new(0.16 * scale, 1.15 * scale, 0.28 * scale),
				CFrame = arm.CFrame * CFrame.new(c * 0.22 * scale, -1.85 * scale, -0.16 * scale) * CFrame.Angles(math.rad(165), 0, 0),
				Color = glowColor,
				Material = Enum.Material.Neon,
				Anchored = false,
				CanCollide = false,
				Massless = true,
				Parent = monster
			})
			weldParts(arm, claw)
		end
	end

	-- Piernas articuladas con Motor6D (libres de anclaje)
	for _, side in ipairs({-1, 1}) do
		local leg = createPart({
			Name = (side == -1) and "LeftLeg" or "RightLeg",
			Size = Vector3.new(0.85 * scale, 2.5 * scale, 0.85 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 0.65 * scale, -2.1 * scale, 0),
			Color = skinColor,
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local legMesh = Instance.new("SpecialMesh")
		legMesh.MeshType = Enum.MeshType.Sphere
		legMesh.Parent = leg

		local hipMotor = Instance.new("Motor6D")
		hipMotor.Name = (side == -1) and "LeftHipMotor" or "RightHipMotor"
		hipMotor.Part0 = torso
		hipMotor.Part1 = leg
		hipMotor.C0 = CFrame.new(side * 0.65 * scale, -1.05 * scale, 0)
		hipMotor.C1 = CFrame.new(0, 1.05 * scale, 0)
		hipMotor.Parent = torso
	end

	local maxHp = (monsterVariant == "Boss") and 350 or ((monsterVariant == "Brute") and 140 or 90)
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = walkSpeed or 17
	humanoid.MaxHealth = maxHp
	humanoid.Health = maxHp
	humanoid.HipHeight = 2.1 * scale
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = monster

	-- BARRA DE VIDA CHIQUITA Y COMPACTA SOBRE LA CABEZA (72x16 px)
	local hpBillboard = Instance.new("BillboardGui")
	hpBillboard.Name = "MonsterHPBar"
	hpBillboard.Size = UDim2.fromOffset(72, 16)
	hpBillboard.StudsOffset = Vector3.new(0, 2.4 * scale, 0)
	hpBillboard.AlwaysOnTop = false
	hpBillboard.MaxDistance = 60
	hpBillboard.Parent = head

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 9)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = monster.Name
	nameLbl.TextColor3 = Color3.fromRGB(255, 230, 230)
	nameLbl.TextStrokeTransparency = 0.2
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 9
	nameLbl.Parent = hpBillboard

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0, 5)
	barBg.Position = UDim2.fromOffset(0, 10)
	barBg.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
	barBg.BorderSizePixel = 0
	barBg.Parent = hpBillboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = glowColor
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	humanoid.HealthChanged:Connect(function(newHp)
		barFill.Size = UDim2.fromScale(math.clamp(newHp / maxHp, 0, 1), 1)
	end)

	monster.PrimaryPart = hrp
	monster.Parent = parent
	return monster
end

return ProceduralModels
