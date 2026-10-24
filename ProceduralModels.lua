-- ProceduralModels.lua
-- Ubicación: ReplicatedStorage.ProceduralModels
-- Modelos 3D procedurales 100% compatibles con materiales nativos de Part.

local ProceduralModels = {}

local function createPart(props)
	local part = Instance.new("Part")
	part.Name = props.Name or "Part"
	part.Size = props.Size or Vector3.new(4, 1, 4)
	part.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	part.Color = props.Color or Color3.fromRGB(120, 120, 120)
	part.Material = props.Material or Enum.Material.Concrete
	part.Anchored = (props.Anchored ~= nil) and props.Anchored or true
	part.CanCollide = (props.CanCollide ~= nil) and props.CanCollide or true
	part.Transparency = props.Transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Parent then
		part.Parent = props.Parent
	end
	return part
end

function ProceduralModels.CreateCinemaFacade(originCFrame, parent)
	local model = Instance.new("Model")
	model.Name = "CinemaFacade"

	createPart({
		Name = "CinemaWall",
		Size = Vector3.new(36, 22, 4),
		CFrame = originCFrame * CFrame.new(0, 11, -18),
		Color = Color3.fromRGB(35, 25, 30),
		Material = Enum.Material.Brick,
		Parent = model
	})

	local marquee = createPart({
		Name = "Marquee",
		Size = Vector3.new(26, 5, 3),
		CFrame = originCFrame * CFrame.new(0, 16, -15),
		Color = Color3.fromRGB(180, 20, 30),
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
	label.TextColor3 = Color3.fromRGB(255, 240, 200)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	for _, side in ipairs({-14, 14}) do
		createPart({
			Name = "AutumnTent",
			Size = Vector3.new(8, 7, 8),
			CFrame = originCFrame * CFrame.new(side, 3.5, -8),
			Color = Color3.fromRGB(210, 95, 25),
			Material = Enum.Material.Fabric,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

function ProceduralModels.CreateCheckpoint(stageNumber, cframe, biomeColor, parent)
	local pad = createPart({
		Name = "Checkpoint_" .. tostring(stageNumber),
		Size = Vector3.new(10, 1.2, 10),
		CFrame = cframe,
		Color = biomeColor or Color3.fromRGB(45, 45, 50),
		Material = Enum.Material.Slate,
		Parent = parent
	})
	pad:SetAttribute("StageNumber", stageNumber)

	createPart({
		Name = "NeonIndicator",
		Size = Vector3.new(10.4, 0.3, 10.4),
		CFrame = cframe * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(220, 40, 40),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pad
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StageSign"
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 80
	billboard.Parent = pad

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "ETAPA " .. tostring(stageNumber)
	text.TextColor3 = Color3.fromRGB(255, 220, 180)
	text.TextStrokeTransparency = 0.2
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
		Color = Color3.fromRGB(65, 40, 25),
		Material = Enum.Material.WoodPlanks,
		Parent = closet
	})

	createPart({
		Name = "ClosetVents",
		Size = Vector3.new(3.5, 1.5, 0.2),
		CFrame = cframe * CFrame.new(0, 6, 1.75),
		Color = Color3.fromRGB(20, 15, 10),
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
		Color = Color3.fromRGB(90, 25, 25),
		Material = Enum.Material.SmoothPlastic,
		Parent = model
	})

	for _, offset in ipairs({-4.2, 4.2}) do
		createPart({
			Name = "SlideRail",
			Size = Vector3.new(0.6, 2.5, length),
			CFrame = slideCFrame * CFrame.new(offset, 1.2, 0),
			Color = Color3.fromRGB(40, 40, 45),
			Material = Enum.Material.Metal,
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
			Color = Color3.fromRGB(70, 65, 75),
			Material = Enum.Material.Cobblestone,
			Parent = model
		})
	end

	model.Parent = parent
	return model
end

function ProceduralModels.CreateR6Monster(name, spawnPos, minZ, maxZ, walkSpeed, parent)
	local monster = Instance.new("Model")
	monster.Name = name or "StalkerR6"
	monster:SetAttribute("SpawnPosition", spawnPos)
	monster:SetAttribute("MinZ", minZ)
	monster:SetAttribute("MaxZ", maxZ)
	monster:SetAttribute("BaseSpeed", walkSpeed or 15)
	monster:SetAttribute("StunnedUntil", 0)

	local hrp = createPart({
		Name = "HumanoidRootPart",
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(spawnPos),
		Transparency = 1,
		Anchored = false,
		CanCollide = true,
		Parent = monster
	})

	local torso = createPart({
		Name = "Torso",
		Size = Vector3.new(2, 2, 1),
		CFrame = CFrame.new(spawnPos),
		Color = Color3.fromRGB(15, 15, 18),
		Material = Enum.Material.Fabric,
		Anchored = false,
		CanCollide = false,
		Parent = monster
	})

	local head = createPart({
		Name = "Head",
		Size = Vector3.new(1.6, 1.6, 1.6),
		CFrame = CFrame.new(spawnPos + Vector3.new(0, 1.8, 0)),
		Color = Color3.fromRGB(215, 205, 195),
		Material = Enum.Material.Slate,
		Anchored = false,
		CanCollide = false,
		Parent = monster
	})

	for _, xOffset in ipairs({-0.35, 0.35}) do
		local eye = createPart({
			Name = "HorrorEye",
			Size = Vector3.new(0.25, 0.25, 0.15),
			CFrame = head.CFrame * CFrame.new(xOffset, 0.2, -0.8),
			Color = Color3.fromRGB(255, 15, 15),
			Material = Enum.Material.Neon,
			Anchored = false,
			CanCollide = false,
			Parent = monster
		})
		local weldEye = Instance.new("WeldConstraint")
		weldEye.Part0 = head
		weldEye.Part1 = eye
		weldEye.Parent = head
	end

	local weldTorso = Instance.new("WeldConstraint")
	weldTorso.Part0 = hrp
	weldTorso.Part1 = torso
	weldTorso.Parent = hrp

	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = torso
	weldHead.Part1 = head
	weldHead.Parent = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = walkSpeed or 15
	humanoid.MaxHealth = 500
	humanoid.Health = 500
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.Parent = monster

	monster.PrimaryPart = hrp
	monster.Parent = parent
	return monster
end

return ProceduralModels
