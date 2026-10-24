-- ProceduralModels.lua
-- Ubicación: ReplicatedStorage.ProceduralModels
-- Incluye monstruos articulados con Motor6D (RequiresNeck = false), barra de vida 3D,
-- Arenas de Batalla, edificios laterales, torres, montañas y ríos inferiores.

local ProceduralModels = {}

local function createPart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Name = props.Name or "Part"
	part.Size = props.Size or Vector3.new(4, 1, 4)
	part.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	part.Color = props.Color or Color3.fromRGB(120, 120, 120)
	part.Material = props.Material or Enum.Material.Concrete
	part.Anchored = (props.Anchored ~= nil) and props.Anchored or true
	part.CanCollide = (props.CanCollide ~= nil) and props.CanCollide or true
	part.Massless = (props.Massless ~= nil) and props.Massless or false
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

-- Farola Gótica de alta luminosidad
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
	pointLight.Brightness = 3.2
	pointLight.Range = 45
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

	local glowCore = createPart({
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

-- Decoración de Valle Inferior y Laterales (Castillos, Montañas y Ríos Brillantes)
function ProceduralModels.CreateValleyScenery(centerPos, biome, parent)
	local scenery = Instance.new("Model")
	scenery.Name = "ValleyScenery"

	-- Suelo rico con pasto/roca del bioma debajo del puente
	createPart({
		Name = "ValleyFloor",
		Size = Vector3.new(520, 4, 260),
		CFrame = CFrame.new(centerPos.X, centerPos.Y - 42, centerPos.Z - 90),
		Color = biome.ValleyColor,
		Material = biome.Mat,
		CanCollide = false,
		Parent = scenery
	})

	-- Río luminoso de lava / energía cruzando el valle inferior
	createPart({
		Name = "GlowingRiver",
		Size = Vector3.new(520, 1.5, 28),
		CFrame = CFrame.new(centerPos.X, centerPos.Y - 39.8, centerPos.Z - 90),
		Color = biome.NeonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = scenery
	})

	-- Montañas y Torres Góticas a ambos lados para llenar el horizonte
	for _, side in ipairs({-1, 1}) do
		createPart({
			ClassName = "WedgePart",
			Name = "MountainPeak",
			Size = Vector3.new(65, 85, 95),
			CFrame = CFrame.new(centerPos.X + side * 125, centerPos.Y + 2, centerPos.Z - 70)
				* CFrame.Angles(0, math.rad(side * 90), 0),
			Color = biome.Color,
			Material = Enum.Material.Slate,
			CanCollide = false,
			Parent = scenery
		})

		-- Torre de Fortaleza con ventanas iluminadas
		local towerX = centerPos.X + side * 48
		createPart({
			Name = "CastleTower",
			Size = Vector3.new(18, 52, 18),
			CFrame = CFrame.new(towerX, centerPos.Y + 4, centerPos.Z - 45),
			Color = Color3.fromRGB(52, 46, 58),
			Material = Enum.Material.Brick,
			CanCollide = false,
			Parent = scenery
		})

		createPart({
			Name = "TowerWindow",
			Size = Vector3.new(4, 10, 19),
			CFrame = CFrame.new(towerX, centerPos.Y + 16, centerPos.Z - 45),
			Color = biome.NeonColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = scenery
		})
	end

	scenery.Parent = parent
	return scenery
end

-- Arco Gótico con antorchas para enmarcar entradas de zonas largas
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
		CFrame = originCFrame * CFrame.new(0, 13, -22),
		Color = Color3.fromRGB(62, 44, 52),
		Material = Enum.Material.Brick,
		Parent = model
	})

	local marquee = createPart({
		Name = "Marquee",
		Size = Vector3.new(32, 6, 3),
		CFrame = originCFrame * CFrame.new(0, 18, -19),
		Color = Color3.fromRGB(220, 35, 45),
		Material = Enum.Material.Neon,
		Parent = model
	})

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
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
			CFrame = originCFrame * CFrame.new(side, 4, -8),
			Color = Color3.fromRGB(225, 110, 32),
			Material = Enum.Material.Fabric,
			Parent = model
		})
		ProceduralModels.CreateStreetLamp(originCFrame * CFrame.new(side * 0.75, 0, 8), Color3.fromRGB(255, 195, 110), model)
		ProceduralModels.CreateJackOLantern(originCFrame * CFrame.new(side * 0.55, 0, -2), model)
		ProceduralModels.CreateSpookyTree(originCFrame * CFrame.new(side * 1.35, 0, 2), Color3.fromRGB(215, 90, 25), model)
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
	billboard.Size = UDim2.fromOffset(180, 52)
	billboard.StudsOffset = Vector3.new(0, 6.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 110
	billboard.Parent = pad

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = string.format("ETAPA %d\n[%s]", stageNumber, biome.Name)
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

function ProceduralModels.CreateSlide(startCFrame, length, parent)
	local model = Instance.new("Model")
	model.Name = "HorrorSlide"

	local angle = math.rad(-22)
	local slideCFrame = startCFrame * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, -length / 2)

	createPart({
		Name = "SlideRamp",
		Size = Vector3.new(12, 1.2, length),
		CFrame = slideCFrame,
		Color = Color3.fromRGB(135, 42, 48),
		Material = Enum.Material.SmoothPlastic,
		Parent = model
	})

	for _, offset in ipairs({-6.2, 6.2}) do
		createPart({
			Name = "SlideRail",
			Size = Vector3.new(0.8, 2.6, length),
			CFrame = slideCFrame * CFrame.new(offset, 1.3, 0),
			Color = Color3.fromRGB(255, 110, 35),
			Material = Enum.Material.Neon,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

function ProceduralModels.CreateStaircase(startCFrame, stepsCount, biomeColor, parent)
	local model = Instance.new("Model")
	model.Name = "TerrorStaircase"

	for i = 1, stepsCount do
		createPart({
			Name = "Step_" .. i,
			Size = Vector3.new(12, 1.2, 3),
			CFrame = startCFrame * CFrame.new(0, i * 1.2, -i * 3),
			Color = biomeColor or Color3.fromRGB(105, 95, 115),
			Material = Enum.Material.Cobblestone,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

-- ============================================================================
-- CRIATURAS DE TERROR ARTICULADAS (RequiresNeck = false + Motor6D Animables)
-- ============================================================================
function ProceduralModels.CreateR6Monster(name, spawnPos, minZ, maxZ, walkSpeed, parent, variant, customScale)
	local monsterVariant = variant or "Stalker"
	local scale = customScale or ((monsterVariant == "Boss") and 2.1 or ((monsterVariant == "Brute") and 1.35 or 1.05))

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
	monster:SetAttribute("BaseSpeed", walkSpeed or 16)
	monster:SetAttribute("StunnedUntil", 0)
	monster:SetAttribute("MonsterVariant", monsterVariant)
	monster:SetAttribute("IsBoss", monsterVariant == "Boss")
	monster:SetAttribute("Scale", scale)

	local hrp = createPart({
		Name = "HumanoidRootPart",
		Size = Vector3.new(2.2 * scale, 2.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(spawnPos),
		Transparency = 1,
		Anchored = false,
		CanCollide = true,
		Parent = monster
	})

	local torso = createPart({
		Name = "Torso",
		Size = Vector3.new(2.4 * scale, 2.8 * scale, 1.5 * scale),
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

	-- Corazón corrupto luminoso
	local core = createPart({
		Name = "CorruptedHeart",
		Size = Vector3.new(1.0 * scale, 1.2 * scale, 0.6 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 0.25 * scale, -0.58 * scale),
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

	-- Costillas y espinas dorsales
	for i = -1, 1 do
		local rib = createPart({
			Name = "BoneRib",
			Size = Vector3.new(2.65 * scale, 0.3 * scale, 1.6 * scale),
			CFrame = torso.CFrame * CFrame.new(0, i * 0.65 * scale, -0.05 * scale),
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
			Size = Vector3.new(0.4 * scale, 1.3 * scale, 1.0 * scale),
			CFrame = torso.CFrame * CFrame.new(0, i * 0.75 * scale, 0.9 * scale) * CFrame.Angles(math.rad(25), 0, 0),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(torso, spike)
	end

	-- Cráneo Demoníaco
	local head = createPart({
		Name = "Head",
		Size = Vector3.new(2.1 * scale, 2.3 * scale, 2.2 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 2.2 * scale, -0.25 * scale),
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

	-- Fauces con colmillos brillantes
	local maw = createPart({
		Name = "OpenMaw",
		Size = Vector3.new(1.45 * scale, 1.0 * scale, 0.65 * scale),
		CFrame = head.CFrame * CFrame.new(0, -0.45 * scale, -0.85 * scale),
		Color = Color3.fromRGB(12, 6, 10),
		Material = Enum.Material.SmoothPlastic,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	weldParts(head, maw)

	for _, xTooth in ipairs({-0.45, -0.15, 0.15, 0.45}) do
		local fang = createPart({
			ClassName = "WedgePart",
			Name = "Fang",
			Size = Vector3.new(0.2 * scale, 0.48 * scale, 0.2 * scale),
			CFrame = maw.CFrame * CFrame.new(xTooth * scale, 0.28 * scale, -0.22 * scale) * CFrame.Angles(math.rad(180), 0, 0),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, fang)
	end

	-- Ojos brillantes y cuernos largos
	for _, side in ipairs({-1, 1}) do
		local eye = createPart({
			Name = "HorrorEye",
			Size = Vector3.new(0.42 * scale, 0.35 * scale, 0.25 * scale),
			CFrame = head.CFrame * CFrame.new(side * 0.45 * scale, 0.32 * scale, -0.95 * scale),
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
			Size = Vector3.new(0.45 * scale, 1.8 * scale, 0.55 * scale),
			CFrame = head.CFrame * CFrame.new(side * 0.8 * scale, 1.25 * scale, 0) * CFrame.Angles(math.rad(-25), 0, math.rad(side * -30)),
			Color = Color3.fromRGB(28, 20, 22),
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, horn)
	end

	-- Brazos Articulados con Motor6D para animar zarpazos y corrida
	for _, side in ipairs({-1, 1}) do
		local armName = (side == -1) and "LeftClawArm" or "RightClawArm"
		local arm = createPart({
			Name = armName,
			Size = Vector3.new(0.85 * scale, 3.4 * scale, 0.85 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 1.65 * scale, -0.3 * scale, 0),
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
		shoulderMotor.C0 = CFrame.new(side * 1.55 * scale, 0.9 * scale, 0)
		shoulderMotor.C1 = CFrame.new(0, 1.2 * scale, 0)
		shoulderMotor.Parent = torso

		for c = -1, 1 do
			local claw = createPart({
				ClassName = "WedgePart",
				Name = "RazorClaw",
				Size = Vector3.new(0.18 * scale, 1.25 * scale, 0.32 * scale),
				CFrame = arm.CFrame * CFrame.new(c * 0.24 * scale, -1.95 * scale, -0.18 * scale) * CFrame.Angles(math.rad(165), 0, 0),
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

	-- Piernas Articuladas con Motor6D para animar pasos al perseguir
	for _, side in ipairs({-1, 1}) do
		local leg = createPart({
			Name = (side == -1) and "LeftLeg" or "RightLeg",
			Size = Vector3.new(0.9 * scale, 2.6 * scale, 0.9 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 0.68 * scale, -2.2 * scale, 0),
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
		hipMotor.C0 = CFrame.new(side * 0.68 * scale, -1.1 * scale, 0)
		hipMotor.C1 = CFrame.new(0, 1.1 * scale, 0)
		hipMotor.Parent = torso
	end

	-- Humanoid con RequiresNeck = false (¡Crucial para que no muera al aparecer!)
	local maxHp = (monsterVariant == "Boss") and 350 or ((monsterVariant == "Brute") and 140 or 90)
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = walkSpeed or 16
	humanoid.MaxHealth = maxHp
	humanoid.Health = maxHp
	humanoid.HipHeight = 2.35 * scale
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = monster

	-- Barra de Vida 3D Flotante sobre cada criatura
	local hpBillboard = Instance.new("BillboardGui")
	hpBillboard.Name = "MonsterHPBar"
	hpBillboard.Size = UDim2.fromOffset(130, 34)
	hpBillboard.StudsOffset = Vector3.new(0, 3.8 * scale, 0)
	hpBillboard.AlwaysOnTop = true
	hpBillboard.MaxDistance = 75
	hpBillboard.Parent = head

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 16)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = monster.Name
	nameLbl.TextColor3 = Color3.fromRGB(255, 220, 220)
	nameLbl.TextStrokeTransparency = 0.1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = true
	nameLbl.Parent = hpBillboard

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0, 10)
	barBg.Position = UDim2.fromOffset(0, 18)
	barBg.BackgroundColor3 = Color3.fromRGB(45, 15, 15)
	barBg.Parent = hpBillboard

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = glowColor
	barFill.Parent = barBg

	humanoid.HealthChanged:Connect(function(newHp)
		barFill.Size = UDim2.fromScale(math.clamp(newHp / maxHp, 0, 1), 1)
	end)

	monster.PrimaryPart = hrp
	monster.Parent = parent
	return monster
end

return ProceduralModels
