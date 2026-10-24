-- ProceduralModels.lua
-- Ubicación: ReplicatedStorage.ProceduralModels
-- Incluye escenografía terrestre iluminada (farolas, calabazas, árboles retorcidos)
-- y anatomía esculpida de terror para 3 variantes de monstruos y Jefes de Bioma.

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

-- Crea una Farola Gótica con luz cálida real para iluminar el piso
function ProceduralModels.CreateStreetLamp(cframe, lightColor, parent)
	local lamp = Instance.new("Model")
	lamp.Name = "StreetLamp"

	createPart({
		Name = "PostBase",
		Size = Vector3.new(1.4, 1.2, 1.4),
		CFrame = cframe * CFrame.new(0, 0.6, 0),
		Color = Color3.fromRGB(35, 35, 40),
		Material = Enum.Material.Metal,
		Parent = lamp
	})

	createPart({
		Name = "Pole",
		Size = Vector3.new(0.6, 10, 0.6),
		CFrame = cframe * CFrame.new(0, 6, 0),
		Color = Color3.fromRGB(25, 25, 30),
		Material = Enum.Material.Metal,
		Parent = lamp
	})

	local bulb = createPart({
		Name = "LanternBulb",
		Size = Vector3.new(1.6, 2, 1.6),
		CFrame = cframe * CFrame.new(0, 11.5, 0),
		Color = lightColor or Color3.fromRGB(255, 175, 85),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = lamp
	})

	local pointLight = Instance.new("PointLight")
	pointLight.Color = lightColor or Color3.fromRGB(255, 185, 100)
	pointLight.Brightness = 2.5
	pointLight.Range = 38
	pointLight.Shadows = false
	pointLight.Parent = bulb

	lamp.Parent = parent
	return lamp
end

-- Crea una Calabaza de Halloween iluminada
function ProceduralModels.CreateJackOLantern(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "JackOLantern"

	local body = createPart({
		Name = "PumpkinBody",
		Size = Vector3.new(2.6, 2.2, 2.6),
		CFrame = cframe * CFrame.new(0, 1.1, 0),
		Color = Color3.fromRGB(225, 105, 20),
		Material = Enum.Material.SmoothPlastic,
		Parent = model
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body

	local glowCore = createPart({
		Name = "PumpkinEyes",
		Size = Vector3.new(1.8, 0.9, 0.4),
		CFrame = cframe * CFrame.new(0, 1.2, -1.15),
		Color = Color3.fromRGB(255, 210, 50),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model
	})

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 30)
	light.Brightness = 1.5
	light.Range = 16
	light.Parent = glowCore

	model.Parent = parent
	return model
end

-- Crea un Árbol Retorcido de Terror para dar ambiente terrestre alrededor del camino
function ProceduralModels.CreateSpookyTree(cframe, leafColor, parent)
	local tree = Instance.new("Model")
	tree.Name = "SpookyTree"

	createPart({
		Name = "Trunk",
		Size = Vector3.new(2.8, 14, 2.8),
		CFrame = cframe * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(6), 0, math.rad(-5)),
		Color = Color3.fromRGB(45, 32, 24),
		Material = Enum.Material.Wood,
		Parent = tree
	})

	createPart({
		Name = "BranchLeft",
		Size = Vector3.new(1.2, 7, 1.2),
		CFrame = cframe * CFrame.new(-2.5, 12, 0) * CFrame.Angles(0, 0, math.rad(42)),
		Color = Color3.fromRGB(45, 32, 24),
		Material = Enum.Material.Wood,
		Parent = tree
	})

	createPart({
		Name = "BranchRight",
		Size = Vector3.new(1.2, 6, 1.2),
		CFrame = cframe * CFrame.new(2.4, 11, 0) * CFrame.Angles(0, 0, math.rad(-38)),
		Color = Color3.fromRGB(45, 32, 24),
		Material = Enum.Material.Wood,
		Parent = tree
	})

	if leafColor then
		local canopy = createPart({
			Name = "Foliage",
			Size = Vector3.new(11, 6, 11),
			CFrame = cframe * CFrame.new(0, 15, 0),
			Color = leafColor,
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = tree
		})
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = canopy
	end

	tree.Parent = parent
	return tree
end

-- Fachada del Cine en la Avenida de Otoño con iluminación cálida y decoración
function ProceduralModels.CreateCinemaFacade(originCFrame, parent)
	local model = Instance.new("Model")
	model.Name = "CinemaFacade"

	createPart({
		Name = "CinemaWall",
		Size = Vector3.new(42, 24, 4),
		CFrame = originCFrame * CFrame.new(0, 12, -20),
		Color = Color3.fromRGB(48, 34, 42),
		Material = Enum.Material.Brick,
		Parent = model
	})

	local marquee = createPart({
		Name = "Marquee",
		Size = Vector3.new(30, 5.5, 3),
		CFrame = originCFrame * CFrame.new(0, 17, -17),
		Color = Color3.fromRGB(200, 25, 35),
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

	for _, side in ipairs({-16, 16}) do
		createPart({
			Name = "AutumnTent",
			Size = Vector3.new(9, 8, 9),
			CFrame = originCFrame * CFrame.new(side, 4, -8),
			Color = Color3.fromRGB(215, 100, 28),
			Material = Enum.Material.Fabric,
			Parent = model
		})
		ProceduralModels.CreateStreetLamp(originCFrame * CFrame.new(side * 0.75, 0, 8), Color3.fromRGB(255, 180, 90), model)
		ProceduralModels.CreateJackOLantern(originCFrame * CFrame.new(side * 0.55, 0, -3), model)
		ProceduralModels.CreateSpookyTree(originCFrame * CFrame.new(side * 1.35, 0, 2), Color3.fromRGB(195, 75, 20), model)
	end

	model.Parent = parent
	return model
end

-- Checkpoint iluminado con farolas y decoración de bioma
function ProceduralModels.CreateCheckpoint(stageNumber, cframe, biomeColor, parent)
	local pad = createPart({
		Name = "Checkpoint_" .. tostring(stageNumber),
		Size = Vector3.new(12, 1.4, 12),
		CFrame = cframe,
		Color = biomeColor or Color3.fromRGB(85, 75, 90),
		Material = Enum.Material.Slate,
		Parent = parent
	})
	pad:SetAttribute("StageNumber", stageNumber)

	local neonBorder = createPart({
		Name = "NeonIndicator",
		Size = Vector3.new(12.4, 0.35, 12.4),
		CFrame = cframe * CFrame.new(0, 0.55, 0),
		Color = (stageNumber % 30 == 0) and Color3.fromRGB(255, 170, 20) or Color3.fromRGB(235, 50, 50),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pad
	})

	-- Luz propia en cada checkpoint para que nunca se vea oscuro el piso
	local cpLight = Instance.new("PointLight")
	cpLight.Color = Color3.fromRGB(255, 190, 130)
	cpLight.Brightness = 2
	cpLight.Range = 32
	cpLight.Parent = pad

	-- Farola en el borde derecho del checkpoint
	ProceduralModels.CreateStreetLamp(cframe * CFrame.new(-5.2, 0.7, -5.2), Color3.fromRGB(255, 175, 95), pad)

	-- Calabaza o árbol decorativo cada 2 etapas para dar sensación de mundo real
	if stageNumber % 2 == 0 then
		ProceduralModels.CreateJackOLantern(cframe * CFrame.new(4.8, 0.7, -4.8), pad)
	end
	if stageNumber % 3 == 0 then
		local sideBase = createPart({
			Name = "SceneryIsland",
			Size = Vector3.new(10, 2, 10),
			CFrame = cframe * CFrame.new(-16, -1, -12),
			Color = biomeColor,
			Material = Enum.Material.Cobblestone,
			Parent = pad
		})
		ProceduralModels.CreateSpookyTree(sideBase.CFrame * CFrame.new(0, 1, 0), Color3.fromRGB(165, 55, 25), pad)
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StageSign"
	billboard.Size = UDim2.fromOffset(140, 44)
	billboard.StudsOffset = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 90
	billboard.Parent = pad

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = (stageNumber % 30 == 0) and ("💀 JEFE ETAPA " .. tostring(stageNumber)) or ("ETAPA " .. tostring(stageNumber))
	text.TextColor3 = Color3.fromRGB(255, 230, 180)
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
		Size = Vector3.new(4.5, 8, 3.5),
		CFrame = cframe * CFrame.new(0, 4, 0),
		Color = Color3.fromRGB(85, 52, 32),
		Material = Enum.Material.WoodPlanks,
		Parent = closet
	})

	createPart({
		Name = "ClosetVents",
		Size = Vector3.new(3.5, 1.5, 0.2),
		CFrame = cframe * CFrame.new(0, 6, 1.75),
		Color = Color3.fromRGB(25, 18, 12),
		Material = Enum.Material.Wood,
		Parent = closet
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HidePrompt"
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Armario de Supervivencia"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	closet.PrimaryPart = body
	closet.Parent = parent
	return closet
end

function ProceduralModels.CreateSlide(startCFrame, length, parent)
	local model = Instance.new("Model")
	model.Name = "HorrorSlide"

	local angle = math.rad(-25)
	local slideCFrame = startCFrame * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, -length / 2)

	createPart({
		Name = "SlideRamp",
		Size = Vector3.new(8, 1, length),
		CFrame = slideCFrame,
		Color = Color3.fromRGB(120, 35, 40),
		Material = Enum.Material.SmoothPlastic,
		Parent = model
	})

	for _, offset in ipairs({-4.2, 4.2}) do
		createPart({
			Name = "SlideRail",
			Size = Vector3.new(0.6, 2.2, length),
			CFrame = slideCFrame * CFrame.new(offset, 1.1, 0),
			Color = Color3.fromRGB(220, 60, 30),
			Material = Enum.Material.Neon,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

function ProceduralModels.CreateStaircase(startCFrame, stepsCount, parent)
	local model = Instance.new("Model")
	model.Name = "TerrorStaircase"

	for i = 1, stepsCount do
		createPart({
			Name = "Step_" .. i,
			Size = Vector3.new(8, 1, 2.5),
			CFrame = startCFrame * CFrame.new(0, i * 1.2, -i * 2.5),
			Color = Color3.fromRGB(95, 85, 105),
			Material = Enum.Material.Cobblestone,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

-- ============================================================================
-- GENERADOR DE MONSTRUOS ESCULPIDOS Y JEFES CON GARRAS, COLMILLOS Y CUERNOS
-- Variantes: "Stalker" (Acechador), "Brute" (Carnicero), "Wraith" (Espectro), "Boss" (Jefe)
-- ============================================================================
function ProceduralModels.CreateR6Monster(name, spawnPos, minZ, maxZ, walkSpeed, parent, variant, customScale)
	local monsterVariant = variant or "Stalker"
	local scale = customScale or ((monsterVariant == "Boss") and 2.1 or ((monsterVariant == "Brute") and 1.35 or 1.0))

	local skinColor = Color3.fromRGB(32, 24, 28)
	local boneColor = Color3.fromRGB(215, 200, 185)
	local glowColor = Color3.fromRGB(255, 20, 20)

	if monsterVariant == "Brute" then
		skinColor = Color3.fromRGB(48, 20, 20)
		glowColor = Color3.fromRGB(255, 95, 15)
	elseif monsterVariant == "Wraith" then
		skinColor = Color3.fromRGB(20, 15, 38)
		glowColor = Color3.fromRGB(185, 35, 255)
	elseif monsterVariant == "Boss" then
		skinColor = Color3.fromRGB(25, 10, 12)
		glowColor = Color3.fromRGB(255, 0, 45)
	end

	local monster = Instance.new("Model")
	monster.Name = name or "HorrorCreature"
	monster:SetAttribute("SpawnPosition", spawnPos)
	monster:SetAttribute("MinZ", minZ)
	monster:SetAttribute("MaxZ", maxZ)
	monster:SetAttribute("BaseSpeed", walkSpeed or 15)
	monster:SetAttribute("StunnedUntil", 0)
	monster:SetAttribute("MonsterVariant", monsterVariant)
	monster:SetAttribute("IsBoss", monsterVariant == "Boss")

	local hrp = createPart({
		Name = "HumanoidRootPart",
		Size = Vector3.new(2.2 * scale, 2.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(spawnPos),
		Transparency = 1,
		Anchored = false,
		CanCollide = true,
		Parent = monster
	})

	-- Torso orgánico esculpido con costillas expuestas y núcleo brillante
	local torso = createPart({
		Name = "Torso",
		Size = Vector3.new(2.3 * scale, 2.8 * scale, 1.4 * scale),
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
	torsoMesh.Scale = Vector3.new(1, 1.15, 0.85)
	torsoMesh.Parent = torso
	weldParts(hrp, torso)

	-- Núcleo corrupto brillante en el pecho
	local core = createPart({
		Name = "CorruptedHeart",
		Size = Vector3.new(0.9 * scale, 1.1 * scale, 0.5 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 0.2 * scale, -0.55 * scale),
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

	local auraLight = Instance.new("PointLight")
	auraLight.Color = glowColor
	auraLight.Brightness = (monsterVariant == "Boss") and 3.5 or 1.8
	auraLight.Range = (monsterVariant == "Boss") and 32 or 16
	auraLight.Parent = core

	-- Costillas óseas salientes (3 pares) y espinas dorsales
	for i = -1, 1 do
		local rib = createPart({
			Name = "BoneRib",
			Size = Vector3.new(2.55 * scale, 0.28 * scale, 1.55 * scale),
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

		-- Espina dorsal puntiaguda en la espalda
		local spineSpike = createPart({
			ClassName = "WedgePart",
			Name = "SpineSpike",
			Size = Vector3.new(0.35 * scale, 1.1 * scale, 0.9 * scale),
			CFrame = torso.CFrame * CFrame.new(0, i * 0.75 * scale, 0.85 * scale) * CFrame.Angles(math.rad(25), 0, 0),
			Color = boneColor,
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(torso, spineSpike)
	end

	-- Cráneo esculpido aterrador
	local head = createPart({
		Name = "Head",
		Size = Vector3.new(2.0 * scale, 2.2 * scale, 2.1 * scale),
		CFrame = torso.CFrame * CFrame.new(0, 2.15 * scale, -0.25 * scale),
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

	-- Cavidad bucal abierta (Fauces)
	local maw = createPart({
		Name = "OpenMaw",
		Size = Vector3.new(1.35 * scale, 0.95 * scale, 0.6 * scale),
		CFrame = head.CFrame * CFrame.new(0, -0.45 * scale, -0.82 * scale),
		Color = Color3.fromRGB(10, 5, 8),
		Material = Enum.Material.SmoothPlastic,
		Anchored = false,
		CanCollide = false,
		Massless = true,
		Parent = monster
	})
	weldParts(head, maw)

	-- Colmillos afilados superiores e inferiores
	for _, xTooth in ipairs({-0.45, -0.15, 0.15, 0.45}) do
		local upperFang = createPart({
			ClassName = "WedgePart",
			Name = "Fang",
			Size = Vector3.new(0.18 * scale, 0.42 * scale, 0.18 * scale),
			CFrame = maw.CFrame * CFrame.new(xTooth * scale, 0.25 * scale, -0.2 * scale) * CFrame.Angles(math.rad(180), 0, 0),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, upperFang)
	end

	-- Ojos hundidos brillantes
	for _, xEye in ipairs({-0.42, 0.42}) do
		local socket = createPart({
			Name = "EyeSocket",
			Size = Vector3.new(0.55 * scale, 0.45 * scale, 0.3 * scale),
			CFrame = head.CFrame * CFrame.new(xEye * scale, 0.3 * scale, -0.88 * scale),
			Color = Color3.fromRGB(10, 10, 12),
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local sMesh = Instance.new("SpecialMesh")
		sMesh.MeshType = Enum.MeshType.Sphere
		sMesh.Parent = socket
		weldParts(head, socket)

		local pupil = createPart({
			Name = "HorrorEye",
			Size = Vector3.new(0.28 * scale, 0.28 * scale, 0.2 * scale),
			CFrame = socket.CFrame * CFrame.new(0, 0, -0.08 * scale),
			Color = glowColor,
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local pMesh = Instance.new("SpecialMesh")
		pMesh.MeshType = Enum.MeshType.Sphere
		pMesh.Parent = pupil
		weldParts(head, pupil)
	end

	-- Cuernos demoníacos retorcidos
	for _, side in ipairs({-1, 1}) do
		local horn1 = createPart({
			ClassName = "WedgePart",
			Name = "HornBase",
			Size = Vector3.new(0.4 * scale, 1.4 * scale, 0.45 * scale),
			CFrame = head.CFrame * CFrame.new(side * 0.75 * scale, 1.1 * scale, 0) * CFrame.Angles(math.rad(-20), 0, math.rad(side * -28)),
			Color = Color3.fromRGB(30, 22, 22),
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		weldParts(head, horn1)
	end

	-- Brazos largos articulados con Garras de 3 Cuchillas
	for _, side in ipairs({-1, 1}) do
		local armName = (side == -1) and "LeftClawArm" or "RightClawArm"
		local arm = createPart({
			Name = armName,
			Size = Vector3.new(0.75 * scale, 3.4 * scale, 0.75 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 1.65 * scale, -0.2 * scale, -0.45 * scale) * CFrame.Angles(math.rad(35), 0, math.rad(side * 12)),
			Color = skinColor,
			Material = Enum.Material.Slate,
			Anchored = false,
			CanCollide = false,
			Massless = true,
			Parent = monster
		})
		local armMesh = Instance.new("SpecialMesh")
		armMesh.MeshType = Enum.MeshType.Sphere
		armMesh.Scale = Vector3.new(0.9, 1.1, 0.9)
		armMesh.Parent = arm
		weldParts(torso, arm)

		-- 3 Garras afiladas en cada mano
		for c = -1, 1 do
			local claw = createPart({
				ClassName = "WedgePart",
				Name = "RazorClaw",
				Size = Vector3.new(0.16 * scale, 1.15 * scale, 0.28 * scale),
				CFrame = arm.CFrame * CFrame.new(c * 0.22 * scale, -1.95 * scale, -0.15 * scale) * CFrame.Angles(math.rad(160), 0, 0),
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

	-- Piernas orgánicas (o cola espectral si es Wraith)
	for _, side in ipairs({-1, 1}) do
		local leg = createPart({
			Name = (side == -1) and "LeftLeg" or "RightLeg",
			Size = Vector3.new(0.85 * scale, 2.6 * scale, 0.85 * scale),
			CFrame = torso.CFrame * CFrame.new(side * 0.65 * scale, -2.2 * scale, 0),
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
		weldParts(torso, leg)
	end

	local maxHp = (monsterVariant == "Boss") and 350 or ((monsterVariant == "Brute") and 160 or 100)
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = walkSpeed or 15
	humanoid.MaxHealth = maxHp
	humanoid.Health = maxHp
	humanoid.HipHeight = (scale - 1) * 2.2
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.Parent = monster

	monster.PrimaryPart = hrp
	monster.Parent = parent
	return monster
end

return ProceduralModels
