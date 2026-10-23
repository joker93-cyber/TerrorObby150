-- LevelGenerator.server.lua (Toboganes, Escaleras, Laterales, Subidas/Bajadas y Screamers de Meme y Terror)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local VIP_GAMEPASS_ID = 2052196520

-- ==========================================
-- 1. SUELO DE INICIO INDESTRUCTIBLE
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
safeLobby.Color = Color3.fromRGB(115, 65, 55)
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
-- 2. ATMÓSFERA Y EFECTOS VISUALES
-- ==========================================
pcall(function()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") or child:IsA("BloomEffect") then
			child:Destroy()
		end
	end

	Lighting.ClockTime = 18.5
	Lighting.Brightness = 1.9
	Lighting.Ambient = Color3.fromRGB(100, 60, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 70, 50)
	Lighting.FogStart = 50
	Lighting.FogEnd = 380
	Lighting.FogColor = Color3.fromRGB(40, 20, 25)

	local sky = Instance.new("Sky", Lighting)
	sky.StarCount = 0

	local atmo = Instance.new("Atmosphere", Lighting)
	atmo.Density = 0.38
	atmo.Color = Color3.fromRGB(110, 50, 35)

	local bloom = Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.9
	bloom.Size = 24
end)

-- ==========================================
-- 3. CARPETAS Y CONSTRUCTORES
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
-- 4. SCREAMERS DINÁMICOS EN PANTALLA (MEME / TERROR)
-- ==========================================
local function triggerScreenScreamer(player, isDeathMeme)
	local pGui = player:FindFirstChild("PlayerGui")
	if not pGui or pGui:FindFirstChild("ActiveScreamer") then return end

	local sg = Instance.new("ScreenGui")
	sg.Name = "ActiveScreamer"
	sg.IgnoreGuiInset = true
	sg.Parent = pGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.2
	bg.Parent = sg

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(0, 480, 0, 480)
	img.Position = UDim2.new(0.5, -240, 0.5, -240)
	img.BackgroundTransparency = 1
	-- ID de imagen de screamer / meme asustador de Roblox
	img.Image = isDeathMeme and "rbxassetid://6023426915" or "rbxassetid://108088840" 
	img.Parent = sg

	local soundId = isDeathMeme and 9114397505 or 9114221735
	add3DSound(sg, soundId, 2.0, 1.1, false, 100):Play()

	task.delay(1.8, function()
		if sg then sg:Destroy() end
	end)
end

-- ==========================================
-- 5. MONSTRUOS AVATAR R6 CON CARAS DE TERROR
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

	add3DSound(torso, 9114397505, isBoss and 1.0 or 0.7, isBoss and 0.45 or 0.65, true, 65)
	local roar = add3DSound(torso, 9114221735, 1.2, 0.65, false, 80)

	local function onHit(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local plr = Players:GetPlayerFromCharacter(char)
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
			if plr then triggerScreenScreamer(plr, false) end -- Screamer de terror al ser atrapado por monstruo
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
-- 6. GENERACIÓN DINÁMICA DE 150 NIVELES (SUBIDAS, BAJADAS, LATERALES, TOBOGANES Y ESCALERAS)
-- ==========================================
local currentZ = -24
local STAGE_LEN = 62

for stage = 1, 150 do
	local bIdx = math.clamp(math.ceil(stage / 30), 1, 5)
	local biome = BIOMES[bIdx]
	local zCenter = currentZ - (STAGE_LEN / 2)

	-- Checkpoint base
	local cp = makePart(Vector3.new(20, 2, 14), Vector3.new(0, 0, currentZ), biome.Mat, biome.Col, checkpointsFolder)
	cp.Name = tostring(stage)

	local pad = makePart(Vector3.new(6, 0.3, 6), cp.Position + Vector3.new(0, 1.1, 0), Enum.Material.Neon, Color3.fromRGB(0, 230, 115), cp)
	pad.CanCollide = false

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

	createLocker(cp.Position + Vector3.new(-7, 1, -2))

	-- Patrones dinámicos cambiantes por cada etapa (Toboganes, Escaleras, Subidas, Laterales)
	local pattern = (stage - 1) % 5

	if stage % 30 == 0 then
		-- Arena de Jefe
		local arena = makePart(Vector3.new(30, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), biome.Mat, biome.Col)
		createAvatarMonster(arena.Position, 11, true, biome, 15.5)
	elseif pattern == 0 then
		-- Subida empinada y desvío lateral
		local ramp = makePart(Vector3.new(14, 2, STAGE_LEN - 16), Vector3.new(5, 4, zCenter), biome.Mat, biome.Col)
		ramp.Orientation = Vector3.new(-15, 0, 0)
		createAvatarMonster(ramp.Position + Vector3.new(0, 3, 0), 5, false, biome, 13.5)
	elseif pattern == 1 then
		-- Tobogán de alta velocidad en bajada
		local slide = makePart(Vector3.new(12, 1.5, STAGE_LEN - 12), Vector3.new(-4, -3, zCenter), Enum.Material.Ice, Color3.fromRGB(200, 150, 120))
		slide.Orientation = Vector3.new(22, 0, 0)
		for s = 1, 2 do
			local saw = makePart(Vector3.new(4, 4, 0.8), Vector3.new(-4, 0, currentZ - (s * 20)), Enum.Material.Neon, biome.Accent)
			saw.CanCollide = false
			saw.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if hum and not hit.Parent:GetAttribute("HasShield") then
					if plr then triggerScreenScreamer(plr, true) end
					hum.Health = 0
				end
			end)
			table.insert(movingHazards, {Part = saw, Origin = saw.Position, Amp = 5, Speed = 3, Phase = s})
		end
	elseif pattern == 2 then
		-- Escaleras escalonadas hacia arriba
		for stp = 1, 5 do
			makePart(Vector3.new(12, 1.5, 8), Vector3.new(0, stp * 2, currentZ - (stp * 9)), biome.Mat, biome.Col)
		end
	elseif pattern == 3 then
		-- Zigzag lateral (ir saltando hacia los costados)
		for zc = 1, 4 do
			local xOffset = (zc % 2 == 0) and 6 or -6
			makePart(Vector3.new(8, 1.5, 8), Vector3.new(xOffset, zc * 1.2, currentZ - (zc * 12)), biome.Mat, biome.Col)
		end
	else
		-- Pasillo de trampas móviles y válvulas de escape
		local hall = makePart(Vector3.new(16, 2, STAGE_LEN - 16), Vector3.new(0, 0, zCenter), biome.Mat, biome.Col)
		local gate = makePart(Vector3.new(16, 10, 1.5), Vector3.new(0, 6, currentZ - STAGE_LEN + 10), Enum.Material.CorrodedMetal, Color3.fromRGB(65, 50, 50))
		local valve = makePart(Vector3.new(2.5, 4.5, 2.5), hall.Position + Vector3.new(-5.5, 3.2, 4), Enum.Material.Neon, Color3.fromRGB(255, 65, 30))
		local gp = Instance.new("ProximityPrompt", valve)
		gp.ActionText = "Abrir Paso"
		gp.HoldDuration = 0.3
		gp.Triggered:Connect(function()
			gate.CanCollide = false
			gate.Transparency = 0.75
			valve.Color = Color3.fromRGB(60, 240, 90)
			task.delay(6, function() if gate then gate.CanCollide = true gate.Transparency = 0 valve.Color = Color3.fromRGB(255, 65, 30) end end)
		end)
		createAvatarMonster(hall.Position + Vector3.new(0, 0, -6), 5, false, biome, 13)
	end

	currentZ = currentZ - STAGE_LEN
end

-- ==========================================
-- 7. SÚPER TIENDA Y CRUCIFIJO
-- ==========================================
local function giveCrucifix(player)
	local bp = player:FindFirstChildOfClass("Backpack")
	if not bp or bp:FindFirstChild("Crucifijo Sagrado") then return end
	local tool = Instance.new("Tool")
	tool.Name = "Crucifijo Sagrado"
	local handle = makePart(Vector3.new(0.8, 3, 0.4), Vector3.new(0,0,0), Enum.Material.Neon, Color3.fromRGB(255, 200, 60), tool)
	handle.Name = "Handle"
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
-- 8. SPAWN Y DETECCIÓN DE CAÍDA AL VACÍO (SCREAMER DE MEME)
-- ==========================================
local function onCharAdded(player, char)
	task.wait(0.1)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hrp or not hum then return end

	local st = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
	local cp = checkpointsFolder:FindFirstChild(tostring((st and st.Value) or 1))
	if st and st.Value > 1 and cp then
		hrp.CFrame = cp.CFrame + Vector3.new(0, 4.5, 0)
	else
		hrp.CFrame = CFrame.new(0, 4, 8)
	end
	giveCrucifix(player)

	-- Detectar muerte por caída al vacío para activar el Screamer de meme
	hum.Died:Connect(function()
		if hrp.Position.Y < -5 then
			triggerScreenScreamer(player, true)
		end
	end)
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
