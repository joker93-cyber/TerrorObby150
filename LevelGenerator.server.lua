-- LevelGenerator.server.lua (Edición Ciudad Apocalíptica de Otoño + Cine + Monstruos R6 + Tienda)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local VIP_GAMEPASS_ID = 2052196520

-- ==========================================
-- 1. SUELO PRINCIPAL BLINDADO (ANTI-CAÍDA AL VACÍO)
-- ==========================================
local oldLobby = Workspace:FindFirstChild("SafeStartLobby")
if oldLobby then oldLobby:Destroy() end

local safeLobby = Instance.new("Part")
safeLobby.Name = "SafeStartLobby"
safeLobby.Size = Vector3.new(64, 4, 56)
safeLobby.Position = Vector3.new(0, -1, 0)
safeLobby.Anchored = true
safeLobby.CanCollide = true
safeLobby.Material = Enum.Material.Brick
safeLobby.Color = Color3.fromRGB(115, 65, 55) -- Ladrillo rojizo como en la plaza
safeLobby.Parent = Workspace

local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(12, 1, 12)
spawnLocation.Position = Vector3.new(0, 1.5, 10)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Transparency = 1
spawnLocation.Parent = Workspace

-- ==========================================
-- 2. ATMÓSFERA DE OTOÑO APOCALÍPTICO (CIELO TORMENTOSO + LUZ NARANJA/ROJA)
-- ==========================================
pcall(function()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") or child:IsA("BloomEffect") then
			child:Destroy()
		end
	end

	Lighting.ClockTime = 18.2
	Lighting.Brightness = 2.0
	Lighting.Ambient = Color3.fromRGB(110, 65, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 75, 55)
	Lighting.FogStart = 70
	Lighting.FogEnd = 420
	Lighting.FogColor = Color3.fromRGB(45, 25, 25)

	local sky = Instance.new("Sky")
	sky.StarCount = 0
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.36
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(120, 55, 40)
	atmo.Decay = Color3.fromRGB(40, 20, 25)
	atmo.Haze = 2.2
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.22
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(255, 215, 190)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 24
	bloom.Threshold = 0.85
	bloom.Parent = Lighting
end)

-- ==========================================
-- 3. CARPETAS Y CONSTRUCTORES BASE
-- ==========================================
local function getFolder(name)
	local f = Workspace:FindFirstChild(name)
	if f then f:ClearAllChildren() else
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = Workspace
	end
	return f
end

local mapFolder = getFolder("Map")
local checkpointsFolder = getFolder("Checkpoints")
local enemiesFolder = getFolder("Enemies")

local function makePart(size, pos, mat, col, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.Material = mat
	p.Color = col
	p.CastShadow = false
	p.Parent = parent or mapFolder
	return p
end

local function add3DSound(parent, id, vol, pitch, looped, maxDist)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = vol or 1
	s.PlaybackSpeed = pitch or 1
	s.Looped = looped or false
	s.RollOffMaxDistance = maxDist or 60
	s.RollOffMinDistance = 8
	s.RollOffMode = Enum.RollOffMode.Linear
	s.Parent = parent
	if looped then s:Play() end
	return s
end

-- ==========================================
-- 4. DECORACIÓN URBANA: CINE, EDIFICIOS CON VENTANAS ROJAS, CARPAS, ÁRBOLES Y HUELLAS
-- ==========================================
-- 4.1 Gran Fachada del Cine / Teatro en la Plaza de Inicio (Detrás del jugador)
local function buildCinemaFacade()
	local zBack = 26
	-- Muro principal del cine
	makePart(Vector3.new(62, 34, 6), Vector3.new(0, 16, zBack), Enum.Material.Brick, Color3.fromRGB(130, 85, 75))
	-- Torre central del cine
	makePart(Vector3.new(26, 44, 8), Vector3.new(0, 21, zBack - 1), Enum.Material.Concrete, Color3.fromRGB(145, 115, 105))

	-- Tiras de neón verticales estilo cine clásico
	makePart(Vector3.new(1.2, 18, 0.5), Vector3.new(-18, 20, zBack - 3.3), Enum.Material.Neon, Color3.fromRGB(255, 210, 170))
	makePart(Vector3.new(1.2, 18, 0.5), Vector3.new(18, 20, zBack - 3.3), Enum.Material.Neon, Color3.fromRGB(255, 210, 170))
	makePart(Vector3.new(1.2, 16, 0.5), Vector3.new(-8, 30, zBack - 5.2), Enum.Material.Neon, Color3.fromRGB(255, 210, 170))
	makePart(Vector3.new(1.2, 16, 0.5), Vector3.new(8, 30, zBack - 5.2), Enum.Material.Neon, Color3.fromRGB(255, 210, 170))

	-- Cartel rojo "NOW SHOWING" y Marquesina iluminada
	local redBanner = makePart(Vector3.new(22, 6, 0.6), Vector3.new(0, 17, zBack - 5.2), Enum.Material.Neon, Color3.fromRGB(210, 20, 25))
	local sGui = Instance.new("SurfaceGui", redBanner)
	sGui.Face = Enum.NormalId.Front
	local bTxt = Instance.new("TextLabel", sGui)
	bTxt.Size = UDim2.new(1, 0, 1, 0)
	bTxt.BackgroundTransparency = 1
	bTxt.Text = "EN CARTELERA:\nPESADILLA 150"
	bTxt.TextColor3 = Color3.fromRGB(255, 240, 220)
	bTxt.Font = Enum.Font.GothamBlack
	bTxt.TextScaled = true

	-- Marquesina saliente sobre la entrada
	makePart(Vector3.new(20, 3, 8), Vector3.new(0, 12, zBack - 8), Enum.Material.Concrete, Color3.fromRGB(60, 50, 50))
	makePart(Vector3.new(20.4, 0.6, 8.4), Vector3.new(0, 13.2, zBack - 8), Enum.Material.Neon, Color3.fromRGB(255, 170, 60))

	-- Pósters luminosos en la parte baja
	for i = -2, 2 do
		if i ~= 0 then
			local px = i * 9
			makePart(Vector3.new(3.5, 5, 0.4), Vector3.new(px, 5, zBack - 3.3), Enum.Material.Neon, Color3.fromRGB(220, 35, 35))
			makePart(Vector3.new(2.8, 4.2, 0.5), Vector3.new(px, 5, zBack - 3.4), Enum.Material.SmoothPlastic, Color3.fromRGB(25, 30, 55))
		end
	end
end
buildCinemaFacade()

-- 4.2 Árboles de Otoño Naranjas
local function createAutumnTree(pos)
	makePart(Vector3.new(2.2, 13, 2.2), pos + Vector3.new(0, 6.5, 0), Enum.Material.Wood, Color3.fromRGB(65, 42, 32))
	local leaves1 = makePart(Vector3.new(11, 8, 11), pos + Vector3.new(0, 14, 0), Enum.Material.Grass, Color3.fromRGB(215, 95, 30))
	local leaves2 = makePart(Vector3.new(8, 6, 8), pos + Vector3.new(1.5, 18, -1), Enum.Material.Grass, Color3.fromRGB(235, 125, 35))
	leaves1.CanCollide = false
	leaves2.CanCollide = false
end

-- 4.3 Carpas Blancas de Supervivencia con Mesa y Calabazas
local function createCampTent(pos)
	-- 4 postes finos
	for _, dx in ipairs({-4.5, 4.5}) do
		for _, dz in ipairs({-4.5, 4.5}) do
			makePart(Vector3.new(0.4, 8, 0.4), pos + Vector3.new(dx, 4, dz), Enum.Material.Metal, Color3.fromRGB(200, 200, 205))
		end
	end
	-- Techo blanco iluminado cálidamente
	local roof = makePart(Vector3.new(10.5, 1.2, 10.5), pos + Vector3.new(0, 8.5, 0), Enum.Material.Fabric, Color3.fromRGB(245, 235, 220))
	local roofTop = makePart(Vector3.new(6, 1.5, 6), pos + Vector3.new(0, 9.7, 0), Enum.Material.Fabric, Color3.fromRGB(245, 235, 220))
	roofTop.CanCollide = false
	local tLight = Instance.new("PointLight", roof)
	tLight.Color = Color3.fromRGB(255, 185, 100)
	tLight.Range = 28
	tLight.Brightness = 1.8

	-- Mesa con mantel naranja y calabaza
	makePart(Vector3.new(5, 2.6, 2.8), pos + Vector3.new(0, 1.3, 0), Enum.Material.Fabric, Color3.fromRGB(215, 130, 45))
	local pumpkin = makePart(Vector3.new(1.5, 1.4, 1.5), pos + Vector3.new(-1, 3.2, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(235, 105, 20))
	Instance.new("SpecialMesh", pumpkin).MeshType = Enum.MeshType.Sphere
end

-- 4.4 Edificios en Ruinas con Ventanas Rojas Brillantes (En los laterales lejanos)
local function createCityBuilding(pos, height)
	local bldg = makePart(Vector3.new(18, height, 22), pos + Vector3.new(0, height / 2, 0), Enum.Material.Brick, Color3.fromRGB(95, 65, 60))
	-- Ventanas rojas encendidas mirando hacia la avenida
	local faceX = (pos.X < 0) and (pos.X + 9.1) or (pos.X - 9.1)
	for row = 1, math.floor(height / 9) do
		for col = -1, 1, 2 do
			local win = makePart(Vector3.new(0.4, 4.5, 4.5), Vector3.new(faceX, row * 8, pos.Z + (col * 5)), Enum.Material.Neon, Color3.fromRGB(235, 55, 40))
			win.CanCollide = false
		end
	end
	return bldg
end

-- 4.5 Farola Alta de Calle y Huellas Brillantes en el Suelo
local function createStreetLamp(pos)
	makePart(Vector3.new(0.8, 16, 0.8), pos + Vector3.new(0, 8, 0), Enum.Material.Metal, Color3.fromRGB(180, 185, 195))
	local bulb = makePart(Vector3.new(3.5, 0.6, 1.4), pos + Vector3.new((pos.X < 0 and 1.5 or -1.5), 16, 0), Enum.Material.Neon, Color3.fromRGB(255, 245, 230))
	local l = Instance.new("PointLight", bulb)
	l.Color = Color3.fromRGB(255, 210, 160)
	l.Range = 52
	l.Brightness = 2.4
end

local function createGlowingFootprints(zPos)
	for i = 1, 2 do
		local fp = makePart(Vector3.new(0.9, 0.15, 1.8), Vector3.new((i == 1 and -1.2 or 1.2), 1.05, zPos - (i * 3)), Enum.Material.Neon, Color3.fromRGB(255, 95, 20))
		fp.CanCollide = false
	end
end

-- Decorar la Plaza de Inicio con carpas, árboles de otoño y farolas
createAutumnTree(Vector3.new(-24, 1, -8))
createAutumnTree(Vector3.new(24, 1, -8))
createCampTent(Vector3.new(-18, 1, 6))
createCampTent(Vector3.new(18, 1, 6))
createStreetLamp(Vector3.new(-14, 1, -14))
createStreetLamp(Vector3.new(14, 1, -14))

-- ==========================================
-- 5. DISTRITOS DE LA CIUDAD Y MONSTRUOS AVATAR R6
-- ==========================================
local BIOMES = {
	[1] = {Name = "Avenida del Cine Maldito", Mat = Enum.Material.Cobblestone, Col = Color3.fromRGB(105, 75, 65), Accent = Color3.fromRGB(255, 85, 25), Shirt = Color3.fromRGB(115, 25, 25), Face = "rbxassetid://7074764"},
	[2] = {Name = "Zona de Cuarentena", Mat = Enum.Material.Slate, Col = Color3.fromRGB(85, 80, 75), Accent = Color3.fromRGB(235, 120, 30), Shirt = Color3.fromRGB(45, 95, 45), Face = "rbxassetid://173789324"},
	[3] = {Name = "Plaza de Ladrillos Rojos", Mat = Enum.Material.Brick, Col = Color3.fromRGB(120, 60, 55), Accent = Color3.fromRGB(240, 40, 40), Shirt = Color3.fromRGB(80, 15, 25), Face = "rbxassetid://7074764"},
	[4] = {Name = "Parque de Otoño Oscuro", Mat = Enum.Material.Grass, Col = Color3.fromRGB(115, 70, 45), Accent = Color3.fromRGB(255, 110, 20), Shirt = Color3.fromRGB(60, 30, 80), Face = "rbxassetid://173789324"},
	[5] = {Name = "Cráter del Apocalipsis", Mat = Enum.Material.Basalt, Col = Color3.fromRGB(65, 50, 50), Accent = Color3.fromRGB(255, 70, 0), Shirt = Color3.fromRGB(170, 35, 0), Face = "rbxassetid://7074764"}
}

local movingHazards = {}
local activeEnemies = {}

local function createLocker(pos)
	local locker = makePart(Vector3.new(4.5, 8.5, 4), pos + Vector3.new(0, 4.25, 0), Enum.Material.Metal, Color3.fromRGB(60, 50, 55))
	makePart(Vector3.new(3.5, 1.4, 0.3), locker.Position + Vector3.new(0, 2, 2), Enum.Material.Neon, Color3.fromRGB(255, 140, 40))
	local doorSound = add3DSound(locker, 9114074523, 0.9, 0.9, false, 45)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Esconderse / Salir"
	prompt.ObjectText = "Refugio Urbano"
	prompt.HoldDuration = 0.1
	prompt.MaxActivationDistance = 10
	prompt.Parent = locker

	prompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		doorSound:Play()
		local hiding = not char:GetAttribute("IsHiding")
		char:SetAttribute("IsHiding", hiding)
		hrp.Anchored = hiding
		hrp.CFrame = hiding and locker.CFrame or (locker.CFrame * CFrame.new(0, 0, 5))
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") or p:IsA("Decal") then
				if hiding then
					p:SetAttribute("OrigT", p.Transparency)
					p.Transparency = 1
				else
					p.Transparency = p:GetAttribute("OrigT") or 0
				end
			end
		end
	end)
end

local function createAvatarMonster(centerPos, radius, isBoss, biome, speed)
	local s = isBoss and 2.1 or 1.15
	local torso = makePart(Vector3.new(2 * s, 2 * s, 1 * s), centerPos + Vector3.new(0, 3 * s, 0), Enum.Material.SmoothPlastic, biome.Shirt, enemiesFolder)
	torso.Name = isBoss and "BossMonster" or "StalkerMonster"
	torso.CanCollide = false

	local head = makePart(Vector3.new(2 * s, 1 * s, 1 * s), torso.Position + Vector3.new(0, 1.5 * s, 0), Enum.Material.SmoothPlastic, Color3.fromRGB(235, 225, 220), torso)
	head.CanCollide = false
	local mesh = Instance.new("SpecialMesh", head)
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)

	local face = Instance.new("Decal", head)
	face.Face = Enum.NormalId.Front
	face.Texture = biome.Face

	local eyeL = makePart(Vector3.new(0.26 * s, 0.22 * s, 0.2 * s), head.Position, Enum.Material.Neon, biome.Accent, torso)
	eyeL.CanCollide = false
	local eyeR = eyeL:Clone()
	eyeR.Parent = torso

	local armL = makePart(Vector3.new(1 * s, 2 * s, 1 * s), torso.Position, Enum.Material.SmoothPlastic, Color3.fromRGB(215, 205, 200), torso)
	armL.CanCollide = false
	local armR = armL:Clone()
	armR.Parent = torso

	local legL = makePart(Vector3.new(1 * s, 2 * s, 1 * s), torso.Position, Enum.Material.SmoothPlastic, Color3.fromRGB(30, 30, 35), torso)
	legL.CanCollide = false
	local legR = legL:Clone()
	legR.Parent = torso

	local blade = makePart(Vector3.new(0.35 * s, 3.8 * s, 0.9 * s), torso.Position, Enum.Material.Neon, biome.Accent, torso)
	blade.CanCollide = false

	local light = Instance.new("PointLight", torso)
	light.Color = biome.Accent
	light.Range = isBoss and 36 or 22
	light.Brightness = 2.5

	local bg = Instance.new("BillboardGui", head)
	bg.Size = UDim2.new(0, 130, 0, 34)
	bg.StudsOffset = Vector3.new(0, 3.2 * s, 0)
	bg.MaxDistance = 75

	local lbl = Instance.new("TextLabel", bg)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = isBoss and "💀 JEFE DEL DISTRITO 💀" or "🔪 ACECHADOR"
	lbl.TextColor3 = Color3.fromRGB(255, 90, 40)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBlack

	add3DSound(torso, 9114397505, isBoss and 1.0 or 0.7, isBoss and 0.45 or 0.65, true, 65)
	local roar = add3DSound(torso, 9114221735, 1.2, 0.65, false, 80)

	local function onHit(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not char:GetAttribute("IsHiding") and not torso:GetAttribute("Stunned") then
			if char:GetAttribute("HasShield") then
				char:SetAttribute("HasShield", false)
				local ff = char:FindFirstChildOfClass("ForceField")
				if ff then ff:Destroy() end
				torso:SetAttribute("Stunned", true)
				task.delay(3, function() if torso then torso:SetAttribute("Stunned", false) end end)
				return
			end
			roar:Play()
			hum.Health = 0
		end
	end
	torso.Touched:Connect(onHit)
	blade.Touched:Connect(onHit)

	table.insert(activeEnemies, {
		Torso = torso, Head = head, EyeL = eyeL, EyeR = eyeR,
		ArmL = armL, ArmR = armR, LegL = legL, LegR = legR, Blade = blade,
		Roar = roar, Scale = s, Origin = torso.Position, Radius = radius,
		Speed = speed or (isBoss and 15.5 or 13), LastRoar = tick()
	})
end

-- ==========================================
-- 6. GENERACIÓN DE LAS 150 ETAPAS EN LA CIUDAD EN RUINAS
-- ==========================================
local currentZ = -24
local STAGE_LEN = 68

-- Suelo de falla volcánica / grieta naranja brillante en el fondo para todo el mapa
for chunk = 1, 10 do
	local chunkLen = STAGE_LEN * 15
	local zCenter = -24 - ((chunk - 0.5) * chunkLen)
	local lavaCrack = makePart(Vector3.new(140, 2, chunkLen), Vector3.new(0, -16, zCenter), Enum.Material.Neon, Color3.fromRGB(255, 85, 20))
	lavaCrack.Transparency = 0.2
	lavaCrack.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end)
end

for stage = 1, 150 do
	local bIdx = math.clamp(math.ceil(stage / 30), 1, 5)
	local biome = BIOMES[bIdx]
	local zCenter = currentZ - (STAGE_LEN / 2)

	-- Escenografía de ciudad a los lados de la calle (sin encerrar al jugador)
	if stage % 2 == 1 then
		createCityBuilding(Vector3.new(-38, -6, zCenter), 32 + (stage % 3) * 8)
		createCityBuilding(Vector3.new(38, -6, zCenter), 36 + (stage % 2) * 10)
		createAutumnTree(Vector3.new(-15, 0, currentZ - 4))
		createStreetLamp(Vector3.new(11, 0, currentZ))
	else
		createAutumnTree(Vector3.new(15, 0, currentZ - 4))
		createStreetLamp(Vector3.new(-11, 0, currentZ))
	end

	-- Checkpoint de adoquín y ladrillo con líneas naranjas luminosas
	local cp = makePart(Vector3.new(22, 2, 16), Vector3.new(0, 0, currentZ), biome.Mat, biome.Col, checkpointsFolder)
	cp.Name = tostring(stage)

	-- Líneas brillantes en la calle como en las capturas
	local lineL = makePart(Vector3.new(0.4, 0.2, 16), cp.Position + Vector3.new(-7, 1.05, 0), Enum.Material.Neon, Color3.fromRGB(255, 150, 40), cp)
	local lineR = makePart(Vector3.new(0.4, 0.2, 16), cp.Position + Vector3.new(7, 1.05, 0), Enum.Material.Neon, Color3.fromRGB(255, 150, 40), cp)
	lineL.CanCollide = false
	lineR.CanCollide = false

	createGlowingFootprints(currentZ + 4)

	-- Carpa blanca decorativa en los checkpoints impares
	if stage % 3 == 1 then
		local sidePlot = makePart(Vector3.new(14, 2, 14), cp.Position + Vector3.new(16, 0, 0), Enum.Material.Cobblestone, biome.Col)
		createCampTent(sidePlot.Position + Vector3.new(0, 1, 0))
	end

	local bg = Instance.new("BillboardGui", cp)
	bg.Size = UDim2.new(0, 160, 0, 48)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.MaxDistance = 85

	local txt = Instance.new("TextLabel", bg)
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Text = "ETAPA " .. stage .. " / 150\n" .. biome.Name
	txt.TextColor3 = Color3.fromRGB(255, 230, 190)
	txt.TextStrokeTransparency = 0
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBlack

	createLocker(cp.Position + Vector3.new(-8, 1, -2))

	local cType = (stage - 1) % 4
	if stage % 30 == 0 then
		local arena = makePart(Vector3.new(30, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), biome.Mat, biome.Col)
		createLocker(arena.Position + Vector3.new(11, 1, 8))
		createLocker(arena.Position + Vector3.new(-11, 1, -8))
		createAvatarMonster(arena.Position, 11, true, biome, 15.5)
	elseif cType == 0 then
		-- Calle agrietada con barricadas, huellas brillantes y asesino patrullando
		local street = makePart(Vector3.new(16, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), biome.Mat, biome.Col)
		createGlowingFootprints(zCenter + 10)
		createGlowingFootprints(zCenter - 8)
		createLocker(street.Position + Vector3.new(5.5, 1, 0))
		makePart(Vector3.new(5.5, 3.5, 1.5), street.Position + Vector3.new(-3.5, 2.7, 11), Enum.Material.Metal, biome.Accent)
		makePart(Vector3.new(5.5, 3.5, 1.5), street.Position + Vector3.new(3.5, 2.7, -11), Enum.Material.Metal, biome.Accent)
		createAvatarMonster(street.Position, 5.5, false, biome, 13.5)
	elseif cType == 1 then
		-- Calzada rota con trampas oscilantes incandescentes
		makePart(Vector3.new(9, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), Enum.Material.Slate, Color3.fromRGB(95, 75, 65))
		for s = 1, 3 do
			local saw = makePart(Vector3.new(5, 5, 0.8), Vector3.new(0, 3.5, currentZ - 12 - (s * 12)), Enum.Material.Neon, biome.Accent)
			saw.CanCollide = false
			saw.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and not hit.Parent:GetAttribute("HasShield") then hum.Health = 0 end
			end)
			table.insert(movingHazards, {Part = saw, Origin = saw.Position, Amp = 6, Speed = 2.5 + (s * 0.4), Phase = s})
		end
	elseif cType == 2 then
		-- Escombros y losas agrietadas sobre el cráter (una firme y otra se hunde)
		for r = 1, 4 do
			local rZ = currentZ - 6 - (r * 10.5)
			local leftSafe = ((stage + r) % 2 == 0)
			local lPad = makePart(Vector3.new(6.8, 1.4, 8), Vector3.new(-4.5, 0, rZ), Enum.Material.Brick, leftSafe and Color3.fromRGB(130, 75, 60) or Color3.fromRGB(75, 45, 40))
			local rPad = makePart(Vector3.new(6.8, 1.4, 8), Vector3.new(4.5, 0, rZ), Enum.Material.Brick, (not leftSafe) and Color3.fromRGB(130, 75, 60) or Color3.fromRGB(75, 45, 40))
			local fake = leftSafe and rPad or lPad
			fake.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if hum and fake.CanCollide then
					fake.CanCollide = false
					fake.Transparency = 0.65
					task.delay(2.5, function() if fake then fake.CanCollide = true fake.Transparency = 0 end end)
				end
			end)
		end
	else
		-- Portal de Piedra / Reja Bloqueada con Válvula + Acechador
		local hall = makePart(Vector3.new(16, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), biome.Mat, biome.Col)
		local gate = makePart(Vector3.new(16, 10, 1.5), Vector3.new(0, 6, currentZ - STAGE_LEN + 10), Enum.Material.CorrodedMetal, Color3.fromRGB(65, 50, 50))
		local valve = makePart(Vector3.new(2.5, 4.5, 2.5), hall.Position + Vector3.new(-5.5, 3.2, 4), Enum.Material.Neon, Color3.fromRGB(255, 65, 30))
		local gp = Instance.new("ProximityPrompt", valve)
		gp.ActionText = "Activar Paso"
		gp.HoldDuration = 0.3
		gp.Triggered:Connect(function()
			gate.CanCollide = false
			gate.Transparency = 0.75
			valve.Color = Color3.fromRGB(60, 240, 90)
			task.delay(6, function() if gate then gate.CanCollide = true gate.Transparency = 0 valve.Color = Color3.fromRGB(255, 65, 30) end end)
		end)
		createLocker(hall.Position + Vector3.new(5.5, 1, -4))
		createAvatarMonster(hall.Position + Vector3.new(0, 0, -6), 5, false, biome, 13)
	end

	currentZ = currentZ - STAGE_LEN
end

-- ==========================================
-- 7. SÚPER TIENDA Y CRUCIFIJO CONGELADOR
-- ==========================================
local function giveCrucifix(player)
	local bp = player:FindFirstChildOfClass("Backpack")
	if not bp or bp:FindFirstChild("Crucifijo Sagrado") then return end
	local tool = Instance.new("Tool")
	tool.Name = "Crucifijo Sagrado"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 3, 0.4)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(255, 200, 60)
	handle.Parent = tool
	local snd = add3DSound(handle, 9114074523, 1.2, 1.5, false, 50)

	tool.Activated:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		snd:Play()
		for _, m in ipairs(activeEnemies) do
			if m.Torso and (m.Torso.Position - hrp.Position).Magnitude < 45 then
				m.Torso:SetAttribute("Stunned", true)
				task.delay(5, function() if m.Torso then m.Torso:SetAttribute("Stunned", false) end end)
			end
		end
	end)
	tool.Parent = bp
end

local function createShopGui(player)
	local pGui = player:WaitForChild("PlayerGui", 10)
	if not pGui or pGui:FindFirstChild("MegaHorrorShop") then return end
	local sg = Instance.new("ScreenGui")
	sg.Name = "MegaHorrorShop"
	sg.ResetOnSpawn = false
	sg.Parent = pGui

	local openBtn = Instance.new("TextButton")
	openBtn.Size = UDim2.new(0, 150, 0, 44)
	openBtn.Position = UDim2.new(0, 14, 0.42, 0)
	openBtn.BackgroundColor3 = Color3.fromRGB(215, 55, 30)
	openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	openBtn.Font = Enum.Font.GothamBlack
	openBtn.TextScaled = true
	openBtn.Text = "🔥 SÚPER TIENDA"
	openBtn.Parent = sg
	Instance.new("UICorner", openBtn)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 420, 0, 290)
	frame.Position = UDim2.new(0.5, -210, 0.5, -145)
	frame.BackgroundColor3 = Color3.fromRGB(25, 18, 20)
	frame.Visible = false
	frame.Parent = sg
	Instance.new("UICorner", frame)

	openBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

	local items = {
		{Txt = "👑 PASE VIP (250 R$)\nVelocidad + Escudo", Col = Color3.fromRGB(215, 140, 0), Act = "VIP"},
		{Txt = "✝️ CRUCIFIJO SAGRADO\nCongela Monstruos 5s", Col = Color3.fromRGB(160, 45, 220), Act = "CRUCIFIX"},
		{Txt = "⚡ SÚPER VELOCIDAD\nCorre el doble", Col = Color3.fromRGB(0, 170, 240), Act = "SPEED"},
		{Txt = "🌀 SÚPER GRAVEDAD\nSaltos Gigantes", Col = Color3.fromRGB(40, 195, 95), Act = "GRAV"},
		{Txt = "🛡️ ESCUDO FANTASMA\nResiste 1 golpe mortal", Col = Color3.fromRGB(60, 110, 220), Act = "SHIELD"},
		{Txt = "⏭️ SALTAR ETAPA\nAvanza al siguiente nivel", Col = Color3.fromRGB(225, 65, 40), Act = "SKIP"}
	}

	for i, it in ipairs(items) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 190, 0, 72)
		b.Position = UDim2.new(0, 14 + (((i - 1) % 2) * 200), 0, 20 + (math.floor((i - 1) / 2) * 84))
		b.BackgroundColor3 = it.Col
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.Text = it.Txt
		b.Parent = frame
		Instance.new("UICorner", b)

		b.MouseButton1Click:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			if it.Act == "VIP" then MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
			elseif it.Act == "CRUCIFIX" then giveCrucifix(player)
			elseif it.Act == "SPEED" then hum.WalkSpeed = 28
			elseif it.Act == "GRAV" then hum.UseJumpPower = true hum.JumpPower = 75
			elseif it.Act == "SHIELD" then
				char:SetAttribute("HasShield", true)
				if not char:FindFirstChildOfClass("ForceField") then Instance.new("ForceField", char) end
			elseif it.Act == "SKIP" then
				local st = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
				if st and st.Value < 150 then
					st.Value = st.Value + 1
					local nextCp = checkpointsFolder:FindFirstChild(tostring(st.Value))
					if nextCp and char:FindFirstChild("HumanoidRootPart") then
						char.HumanoidRootPart.CFrame = nextCp.CFrame + Vector3.new(0, 4.5, 0)
					end
				end
			end
		end)
	end
end

-- ==========================================
-- 8. SPAWN DE JUGADORES Y MOVIMIENTO 60 FPS
-- ==========================================
local function onCharAdded(player, char)
	task.wait(0.1)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	local st = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
	local cp = checkpointsFolder:FindFirstChild(tostring((st and st.Value) or 1))
	if st and st.Value > 1 and cp then
		hrp.CFrame = cp.CFrame + Vector3.new(0, 4.5, 0)
	else
		hrp.CFrame = CFrame.new(0, 4, 8)
	end
	giveCrucifix(player)
end

local function setupPlayer(player)
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder", player)
	ls.Name = "leaderstats"
	local st = ls:FindFirstChild("Stage") or Instance.new("IntValue", ls)
	st.Name = "Stage"
	if st.Value == 0 then st.Value = 1 end
	task.spawn(createShopGui, player)
	player.CharacterAdded:Connect(function(c) onCharAdded(player, c) end)
	if player.Character then task.spawn(onCharAdded, player, player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, p) end

for _, cp in ipairs(checkpointsFolder:GetChildren()) do
	local num = tonumber(cp.Name)
	if num then
		cp.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			local st = plr and plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Stage")
			if st and num > st.Value and num <= st.Value + 2 then st.Value = num end
		end)
	end
end

RunService.Heartbeat:Connect(function(dt)
	local now = tick()
	for _, h in ipairs(movingHazards) do
		if h.Part and h.Part.Parent then
			h.Part.Position = h.Origin + Vector3.new(math.sin(now * h.Speed + h.Phase) * h.Amp, 0, 0)
		end
	end
	for _, m in ipairs(activeEnemies) do
		local t = m.Torso
		if t and t.Parent and not t:GetAttribute("Stunned") then
			local target = nil
			local bestD = 35
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and not c:GetAttribute("IsHiding") then
					local d = (hrp.Position - m.Origin).Magnitude
					if d < bestD then bestD = d target = hrp.Position end
				end
			end
			local newPos = t.Position
			local look = newPos + Vector3.new(0, 0, 1)
			if target then
				local flat = Vector3.new(target.X, t.Position.Y, target.Z)
				if (flat - t.Position).Magnitude > 0.5 then
					newPos = t.Position + (flat - t.Position).Unit * m.Speed * dt
					look = flat
				end
			else
				newPos = m.Origin + Vector3.new(math.sin(now * 2.5) * m.Radius, 0, math.cos(now * 1.8) * (m.Radius * 2))
				look = newPos + Vector3.new(0, 0, (math.sin(now * 1.8) >= 0 and -1 or 1))
			end
			local cf = CFrame.lookAt(newPos, look)
			local s = m.Scale
			local sw = math.sin(now * 10) * 0.65
			t.CFrame = cf
			m.Head.CFrame = cf * CFrame.new(0, 1.5 * s, 0)
			m.EyeL.CFrame = cf * CFrame.new(-0.35 * s, 1.6 * s, -0.55 * s)
			m.EyeR.CFrame = cf * CFrame.new(0.35 * s, 1.6 * s, -0.55 * s)
			m.ArmL.CFrame = cf * CFrame.new(-1.5 * s, 0, 0) * CFrame.Angles(-sw, 0, 0)
			m.ArmR.CFrame = cf * CFrame.new(1.5 * s, 0, 0) * CFrame.Angles(sw + 0.5, 0, 0)
			m.LegL.CFrame = cf * CFrame.new(-0.5 * s, -2 * s, 0) * CFrame.Angles(sw, 0, 0)
			m.LegR.CFrame = cf * CFrame.new(0.5 * s, -2 * s, 0) * CFrame.Angles(-sw, 0, 0)
			m.Blade.CFrame = m.ArmR.CFrame * CFrame.new(0, -1.2 * s, -1.2 * s) * CFrame.Angles(math.rad(-75), 0, 0)
		end
	end
end)
