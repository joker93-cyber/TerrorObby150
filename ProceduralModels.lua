-- ReplicatedStorage/ProceduralModels (ModuleScript)
local ProceduralModels = {}

local V3, CF, C3, M, rad = Vector3.new, CFrame.new, Color3.fromRGB, Enum.Material, math.rad
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local SMOKE = "rbxasset://textures/particles/smoke_main.dng"
local SPARK = "rbxasset://textures/particles/sparkles_main.dng"
local FIRE = "rbxasset://textures/particles/fire_main.dng"

local THEMES = {
	[1] = {Aura = C3(190, 0, 0), Mist = C3(80, 85, 80), Eye = C3(255, 40, 40), Cloth = C3(60, 65, 62)},
	[2] = {Aura = C3(60, 230, 40), Mist = C3(35, 60, 30), Eye = C3(190, 255, 60), Cloth = C3(35, 50, 35)},
	[3] = {Aura = C3(150, 90, 255), Mist = C3(45, 30, 65), Eye = C3(225, 175, 255), Cloth = C3(55, 35, 50)},
	[4] = {Aura = C3(210, 25, 25), Mist = C3(150, 155, 160), Eye = C3(255, 70, 40), Cloth = C3(45, 38, 32)},
	[5] = {Aura = C3(255, 80, 0), Mist = C3(30, 15, 25), Eye = C3(255, 200, 40), Cloth = C3(30, 22, 28)},
}
local BOSS_NAMES = {"El Cirujano Demente", "La Aberración Tóxica", "La Dama Espectral", "El Carnicero de la Niebla", "El Monarca del Abismo"}

local function getTheme(i)
	return THEMES[math.clamp(math.floor(tonumber(i) or 1), 1, 5)]
end

---------------------------------------------------------------- HELPERS
local function newModel(name)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Transparency = 1
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	return model, root
end

-- Parte decorativa soldada a la raíz (sin colisión, sin Touched, sin masa)
local function part(model, root, name, size, offset, color, material, transparency, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	return p
end

-- Cilindro vertical (el eje del Cylinder es X, se gira 90° en Z)
local function pillar(model, root, name, height, diameter, offset, color, material, transparency)
	return part(model, root, name, V3(height, diameter, diameter), offset * CFrame.Angles(0, 0, rad(90)), color, material, transparency, CYL)
end

local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
	return l
end

local function attach(parent, name, offset)
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = offset
	a.Parent = parent
	return a
end

local function emitter(parent, o)
	local life = o.Life or 1.5
	local e = Instance.new("ParticleEmitter")
	e.Name = o.Name or "Aura"
	e.Texture = o.Texture or SMOKE
	e.Color = ColorSequence.new(o.Color)
	e.LightEmission = o.Glow or 0
	e.Rate = o.Rate or 10
	e.Lifetime = NumberRange.new(life, life * 1.6)
	e.Speed = NumberRange.new(o.SpeedMin or 0.5, o.SpeedMax or 2)
	e.SpreadAngle = Vector2.new(o.Spread or 180, o.Spread or 180)
	e.Acceleration = o.Accel or V3(0, 1, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.Size = NumberSequence.new(o.Size0 or 1, o.Size1 or 3)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, o.Alpha or 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Parent = parent
	return e
end

local function trail(a0, a1, color, lifetime)
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(color)
	t.Transparency = NumberSequence.new(0.25, 1)
	t.LightEmission = 1
	t.Lifetime = lifetime
	t.MinLength = 0.05
	t.FaceCamera = true
	t.Parent = a0.Parent
	return t
end

local function finalize(model, kind, footOffset, hoverHeight)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("FootOffset", footOffset)
	model:SetAttribute("HoverHeight", hoverHeight or 0)
	return model
end

---------------------------------------------------------------- FANTASMA
function ProceduralModels.BuildGhost(biomeIndex)
	local theme = getTheme(biomeIndex)
	local model, root = newModel("Ghost")
	root.Size = V3(3.4, 6, 2.6)
	local pale, black = C3(175, 215, 255), C3(5, 5, 8)

	local head = part(model, root, "Head", V3(2.8, 2.8, 2.8), CF(0, 1.9, 0), pale, M.Neon, 0.45, BALL)
	part(model, root, "Torso", V3(3.2, 3.2, 3.2), CF(0, 0.1, 0), pale, M.Neon, 0.5, BALL)
	pillar(model, root, "Tail1", 1.6, 2.6, CF(0, -1.3, 0), pale, M.Neon, 0.55)
	pillar(model, root, "Tail2", 1.4, 1.8, CF(0, -2.5, 0), pale, M.Neon, 0.6)
	local tail3 = pillar(model, root, "Tail3", 1.2, 1.0, CF(0, -3.5, 0), pale, M.Neon, 0.65)

	for _, side in ipairs({-1, 1}) do
		part(model, root, "Arm", V3(0.5, 3.4, 0.5), CF(side * 2.0, 0.1, 0) * CFrame.Angles(0, 0, side * rad(15)), pale, M.Neon, 0.5)
		part(model, root, "Claw", V3(0.7, 0.9, 0.5), CF(side * 2.45, -1.75, 0), black, M.SmoothPlastic, 0.2)
		part(model, root, "EyeSocket", V3(0.7, 0.9, 0.3), CF(side * 0.6, 2.0, -1.2), black, M.SmoothPlastic)
		part(model, root, "EyeGlow", V3(0.3, 0.4, 0.2), CF(side * 0.6, 2.0, -1.34), theme.Eye, M.Neon)
	end
	part(model, root, "Mouth", V3(0.8, 1.2, 0.3), CF(0, 1.2, -1.2), black, M.SmoothPlastic)

	light(head, theme.Eye, 12, 1.2)
	emitter(tail3, {Name = "DarkMist", Color = theme.Mist, Rate = 14, Size0 = 2, Size1 = 4.5, Life = 1.6, SpeedMax = 1.5, Accel = V3(0, 0.5, 0), Alpha = 0.5})
	emitter(head, {Name = "Wisps", Texture = SPARK, Color = theme.Aura, Rate = 6, Size0 = 0.5, Size1 = 0.1, Life = 1.2, Glow = 0.6, Alpha = 0.2})
	trail(attach(root, "Trail0", CF(0, 2.5, 0.2)), attach(root, "Trail1", CF(0, -3.8, 0.2)), theme.Aura, 0.7)

	return finalize(model, "GHOST", 4.1, 2.5)
end

---------------------------------------------------------------- ASESINO
function ProceduralModels.BuildKiller(biomeIndex)
	local theme = getTheme(biomeIndex)
	local model, root = newModel("Killer")
	root.Size = V3(3.4, 6, 2)
	local pants, skin, black, crimson = C3(18, 16, 18), C3(70, 55, 52), C3(4, 4, 4), C3(220, 0, 30)

	local legL = part(model, root, "LegL", V3(1.1, 2.9, 1.2), CF(-0.6, -1.55, 0), pants, M.Fabric)
	part(model, root, "LegR", V3(1.1, 2.9, 1.2), CF(0.6, -1.55, 0), pants, M.Fabric)
	part(model, root, "Torso", V3(3, 2.8, 1.6), CF(0, 0.6, 0), theme.Cloth, M.Fabric)
	part(model, root, "BloodStain", V3(2.2, 1.5, 0.1), CF(0, 0.3, -0.83), C3(95, 0, 8))
	part(model, root, "Head", V3(1.6, 1.7, 1.6), CF(0, 2.85, 0), skin)
	part(model, root, "Hood", V3(1.9, 0.7, 1.9), CF(0, 3.5, 0.05), C3(12, 12, 14), M.Fabric)
	part(model, root, "Mask", V3(1.7, 1.8, 0.2), CF(0, 2.85, -0.85), C3(238, 236, 228))
	part(model, root, "Mouth", V3(0.9, 0.12, 0.05), CF(0, 2.4, -0.97), black)
	for _, side in ipairs({-1, 1}) do
		part(model, root, "EyeHole", V3(0.4, 0.3, 0.05), CF(side * 0.4, 3.0, -0.97), black)
		part(model, root, "EyePupil", V3(0.16, 0.12, 0.05), CF(side * 0.4, 3.0, -1.0), crimson, M.Neon)
	end

	-- Brazo izquierdo colgando
	part(model, root, "ArmL", V3(0.9, 2.6, 0.9), CF(-2.0, 0.7, 0) * CFrame.Angles(0, 0, rad(-8)), theme.Cloth, M.Fabric)
	part(model, root, "HandL", V3(0.9, 0.9, 0.9), CF(-2.2, -0.85, 0), skin)

	-- Brazo derecho extendido con cuchillo
	part(model, root, "ArmR", V3(0.9, 2.6, 0.9), CF(2.0, 1.84, -1.22) * CFrame.Angles(rad(-70), 0, 0), theme.Cloth, M.Fabric)
	part(model, root, "HandR", V3(0.9, 0.9, 0.9), CF(2.0, 2.29, -2.44), skin)
	part(model, root, "KnifeHandle", V3(0.25, 0.25, 0.9), CF(2.0, 2.3, -2.95), C3(20, 15, 12), M.Wood)
	local blade = part(model, root, "KnifeBlade", V3(0.08, 0.55, 2.1), CF(2.0, 2.3, -4.45), C3(205, 205, 210), M.Metal)
	part(model, root, "KnifeEdgeGlow", V3(0.1, 0.12, 2.0), CF(2.0, 2.07, -4.45), crimson, M.Neon)
	light(blade, crimson, 9, 2)
	trail(attach(blade, "TrailTop", CF(0, 0.7, -1.05)), attach(blade, "TrailBottom", CF(0, -0.7, -1.05)), crimson, 0.35)
	emitter(blade, {Name = "BloodDrip", Texture = SPARK, Color = crimson, Rate = 5, Size0 = 0.2, Size1 = 0.1, Life = 0.6, SpeedMin = 0, SpeedMax = 1, Spread = 20, Accel = V3(0, -40, 0), Glow = 0.5, Alpha = 0.1})

	emitter(legL, {Name = "FootMist", Color = theme.Mist, Rate = 8, Size0 = 2.5, Size1 = 4.5, Life = 1.5, Accel = V3(0, 0.3, 0), Alpha = 0.7})

	return finalize(model, "KILLER", 3.0, 0)
end

---------------------------------------------------------------- JEFES
local function giantBase(model, root, theme, skin, cloth, clothMat, skinMat, skipEyes)
	root.Size = V3(7.5, 13, 4.5)
	local b = {}
	b.LegL = part(model, root, "LegL", V3(2.4, 5.2, 2.4), CF(-1.7, -5.4, 0), cloth, clothMat)
	b.LegR = part(model, root, "LegR", V3(2.4, 5.2, 2.4), CF(1.7, -5.4, 0), cloth, clothMat)
	b.Torso = part(model, root, "Torso", V3(6.4, 6, 3.6), CF(0, 0.2, 0), cloth, clothMat)
	b.Head = part(model, root, "Head", V3(3.2, 3.4, 3.2), CF(0, 4.9, 0), skin, skinMat)
	b.ArmL = part(model, root, "ArmL", V3(2, 6, 2), CF(-4.4, 0.7, 0), skin, skinMat)
	b.ArmR = part(model, root, "ArmR", V3(2, 6, 2), CF(4.4, 0.7, 0), skin, skinMat)
	b.HandL = part(model, root, "HandL", V3(2.2, 2.2, 2.2), CF(-4.4, -3.2, 0), skin, skinMat)
	b.HandR = part(model, root, "HandR", V3(2.2, 2.2, 2.2), CF(4.4, -3.2, 0), skin, skinMat)
	if not skipEyes then
		for _, side in ipairs({-1, 1}) do
			part(model, root, "Eye", V3(0.8, 0.5, 0.2), CF(side * 0.9, 5.2, -1.65), theme.Eye, M.Neon)
		end
	end
	return b
end

local function bossAura(torso, ground, theme, k)
	light(torso, theme.Aura, 45, 3)
	emitter(torso, {Name = "Embers", Texture = SPARK, Color = theme.Aura, Rate = 24 * k, Size0 = 0.9, Size1 = 0.1, Life = 1.6, SpeedMin = 3, SpeedMax = 8, Accel = V3(0, 6, 0), Glow = 1, Alpha = 0.1})
	emitter(torso, {Name = "Mist", Color = theme.Mist, Rate = 12, Size0 = 5, Size1 = 11, Life = 2.2, SpeedMax = 2.5, Accel = V3(0, 0.8, 0), Alpha = 0.55})
	emitter(ground, {Name = "GroundFog", Color = theme.Mist, Rate = 16, Size0 = 6, Size1 = 13, Life = 2.5, SpeedMax = 4, Accel = V3(0, 0.2, 0), Alpha = 0.65})
end

local BOSS_BUILDERS = {}

-- 1) EL CIRUJANO DEMENTE
BOSS_BUILDERS[1] = function(model, root, theme)
	local b = giantBase(model, root, theme, C3(205, 198, 190), C3(70, 120, 110), M.Fabric, M.SmoothPlastic)
	part(model, root, "SurgicalMask", V3(3.3, 1.5, 0.3), CF(0, 4.3, -1.7), C3(120, 185, 165), M.Fabric)
	part(model, root, "Apron", V3(5.4, 5.4, 0.3), CF(0, -0.2, -1.95), C3(225, 222, 215), M.Fabric)
	for i, pos in ipairs({V3(-1.4, 0.8, -2.12), V3(1.2, -1.2, -2.12), V3(-0.3, -2.0, -2.12)}) do
		part(model, root, "Stain" .. i, V3(1.6, 1.2, 0.1), CF(pos), C3(110, 0, 10))
	end
	local lamp = part(model, root, "HeadLamp", V3(1.6, 1.6, 1.6), CF(0, 6.5, -0.9), C3(255, 255, 255), M.Neon, 0, BALL)
	light(lamp, C3(255, 230, 230), 30, 2.5)

	part(model, root, "SawRod", V3(0.7, 0.7, 2.4), CF(5.0, -2.8, -1.2), C3(90, 90, 95), M.Metal)
	local saw = part(model, root, "SawBlade", V3(0.4, 5.6, 5.6), CF(5.6, -2.4, -2.2), C3(170, 170, 175), M.Metal, 0, CYL)
	part(model, root, "SawTeeth", V3(0.3, 5.9, 5.9), CF(5.6, -2.4, -2.2), theme.Aura, M.Neon, 0.5, CYL)
	part(model, root, "SawHub", V3(0.8, 1.4, 1.4), CF(5.6, -2.4, -2.2), C3(40, 40, 45), M.Metal, 0, CYL)
	trail(attach(saw, "SawT0", CF(0, 2.8, 0)), attach(saw, "SawT1", CF(0, -2.8, 0)), theme.Aura, 0.4)

	for i = 1, 4 do
		local side = (i % 2 == 0) and 1 or -1
		local tier = math.ceil(i / 2)
		local armCF = CF(side * 2.4, 3.5 + tier * 0.9, 2.3) * CFrame.Angles(rad(-25), 0, -side * rad(25 + tier * 18))
		part(model, root, "SurgArm" .. i, V3(0.5, 6.5, 0.5), armCF, C3(150, 150, 155), M.Metal)
		part(model, root, "SurgTip" .. i, V3(0.35, 1.4, 0.35), armCF * CF(0, 3.9, 0), theme.Aura, M.Neon)
	end
	bossAura(b.Torso, b.LegL, theme, 1)
end

-- 2) LA ABERRACIÓN TÓXICA
BOSS_BUILDERS[2] = function(model, root, theme)
	root.Size = V3(9, 12, 9)
	local body = part(model, root, "Body", V3(11, 11, 11), CF(0, 0.5, 0), C3(40, 78, 35), M.SmoothPlastic, 0.35, BALL)
	part(model, root, "Core", V3(7, 7, 7), CF(0, 0.5, 0), theme.Aura, M.Neon, 0.35, BALL)

	local eyes = {
		{-2.2, 2.5, -4.9, 1.5}, {2.4, 3.1, -4.7, 1.2}, {0, 0.8, -5.5, 2.2}, {-3.4, -0.8, -4.2, 1.0},
		{3.5, -0.5, -4.3, 1.3}, {-1.2, 4.2, -4.3, 0.9}, {1.6, -2.4, -4.6, 1.1},
	}
	for i, e in ipairs(eyes) do
		part(model, root, "Eye" .. i, V3(e[4], e[4], e[4]), CF(e[1], e[2], e[3]), theme.Eye, M.Neon, 0, BALL)
		part(model, root, "Pupil" .. i, V3(e[4] * 0.45, e[4] * 0.45, e[4] * 0.45), CF(e[1], e[2], e[3] - e[4] * 0.38), C3(0, 0, 0), M.SmoothPlastic, 0, BALL)
	end
	part(model, root, "Maw", V3(4.2, 1.4, 0.5), CF(0, -2.2, -4.9), C3(5, 12, 5))
	for t = -2, 2 do
		part(model, root, "Tooth" .. t, V3(0.4, 0.9, 0.3), CF(t * 0.8, -1.7, -5.1), C3(230, 235, 215))
	end
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local s = 0.8 + (i % 3) * 0.4
		part(model, root, "Bubble" .. i, V3(s, s, s), CF(math.cos(a) * 3.5, 5.3 + (i % 3) * 0.3, math.sin(a) * 3.5), theme.Aura, M.Neon, 0.3, BALL)
	end
	local firstTentacle
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		local t = part(model, root, "Tentacle" .. i, V3(1.5, 6, 1.5), CF(math.cos(a) * 3.8, -5, math.sin(a) * 3.8) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, rad(20)), C3(30, 60, 28))
		firstTentacle = firstTentacle or t
	end
	emitter(body, {Name = "ToxicDrip", Texture = SPARK, Color = theme.Aura, Rate = 10, Size0 = 0.5, Size1 = 0.2, Life = 1, SpeedMax = 1, Accel = V3(0, -25, 0), Glow = 0.8, Alpha = 0.1})
	bossAura(body, firstTentacle, theme, 0.8)
end

-- 3) LA DAMA ESPECTRAL
BOSS_BUILDERS[3] = function(model, root, theme)
	root.Size = V3(6.5, 13, 5.5)
	local dress, black = C3(70, 50, 90), C3(4, 4, 8)
	local d1 = pillar(model, root, "Dress1", 3.6, 10, CF(0, -5.9, 0), dress, M.Fabric, 0.2)
	pillar(model, root, "Dress2", 3.2, 7.6, CF(0, -2.8, 0), dress, M.Fabric, 0.2)
	pillar(model, root, "Dress3", 3.2, 5.4, CF(0, 0.1, 0), dress, M.Fabric, 0.2)
	local torso = part(model, root, "Torso", V3(3.6, 3, 2.2), CF(0, 2.7, 0), C3(205, 195, 215), M.SmoothPlastic, 0.1)
	part(model, root, "Head", V3(3.2, 3.2, 3.2), CF(0, 5.4, 0), C3(215, 205, 225), M.SmoothPlastic, 0.05, BALL)
	part(model, root, "Hair", V3(3.6, 9.5, 0.8), CF(0, 2.2, 1.5), black, M.Fabric)
	for _, side in ipairs({-1, 1}) do
		part(model, root, "HairLock", V3(0.7, 6, 0.7), CF(side * 1.9, 3, 0.4), black, M.Fabric)
		part(model, root, "EyeSocket", V3(0.9, 1.2, 0.3), CF(side * 0.7, 5.6, -1.4), black)
		part(model, root, "EyeGlow", V3(0.4, 0.5, 0.2), CF(side * 0.7, 5.6, -1.52), theme.Eye, M.Neon)
		part(model, root, "Arm", V3(0.9, 8.5, 0.9), CF(side * 3.3, 2.98, -4.17) * CFrame.Angles(rad(-100), 0, 0), C3(205, 195, 215), M.SmoothPlastic, 0.1)
		for j = -1, 1 do
			part(model, root, "Claw", V3(0.25, 0.25, 1.8), CF(side * 3.3 + j * 0.45, 2.2, -9.0), theme.Eye, M.Neon)
		end
	end
	part(model, root, "Mouth", V3(1.1, 1.8, 0.3), CF(0, 4.5, -1.3), black)
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		part(model, root, "Thorn" .. i, V3(0.25, 1.4, 0.25), CF(math.cos(a) * 1.4, 7.1, math.sin(a) * 1.4) * CFrame.Angles(math.sin(a) * 0.35, 0, -math.cos(a) * 0.35), theme.Aura, M.Neon)
	end
	trail(attach(root, "DressT0", CF(0, 5, 0.5)), attach(root, "DressT1", CF(0, -7, 0.5)), theme.Aura, 1.0)
	bossAura(torso, d1, theme, 1.2)
end

-- 4) EL CARNICERO DE LA NIEBLA
BOSS_BUILDERS[4] = function(model, root, theme)
	local b = giantBase(model, root, theme, C3(160, 115, 105), C3(50, 42, 38), M.Fabric, M.SmoothPlastic, true)
	part(model, root, "Sack", V3(3.5, 3.7, 3.5), CF(0, 4.9, 0), C3(165, 140, 100), M.Fabric)
	for _, side in ipairs({-1, 1}) do
		part(model, root, "SackHole", V3(0.9, 0.7, 0.2), CF(side * 0.9, 5.2, -1.78), C3(4, 4, 4))
		part(model, root, "Eye", V3(0.8, 0.5, 0.2), CF(side * 0.9, 5.2, -1.88), theme.Eye, M.Neon)
	end
	part(model, root, "Apron", V3(5.6, 5.8, 0.3), CF(0, -0.1, -1.95), C3(105, 20, 20), M.Fabric)
	part(model, root, "Splatter1", V3(1.8, 1.2, 0.1), CF(-1.2, 0.8, -2.12), C3(60, 5, 5))
	part(model, root, "Splatter2", V3(1.4, 1.6, 0.1), CF(1.4, -1.4, -2.12), C3(60, 5, 5))

	part(model, root, "CleaverHandle", V3(0.6, 3, 0.6), CF(4.4, -2.2, -1.0), C3(40, 28, 20), M.Wood)
	local blade = part(model, root, "CleaverBlade", V3(0.35, 4.5, 3.2), CF(4.4, 1.6, -2.6), C3(170, 170, 175), M.Metal)
	part(model, root, "CleaverEdge", V3(0.4, 4.5, 0.25), CF(4.4, 1.6, -4.2), theme.Aura, M.Neon)
	trail(attach(blade, "CleaverT0", CF(0, 2.25, -1.6)), attach(blade, "CleaverT1", CF(0, -2.25, -1.6)), theme.Aura, 0.45)

	for i = -1, 1 do
		part(model, root, "HookChain", V3(0.25, 4, 0.25), CF(i * 2, 4.5, 2.4), C3(90, 90, 95), M.Metal)
		part(model, root, "HookBend", V3(1, 0.3, 0.3), CF(i * 2 + 0.5, 2.4, 2.4), C3(150, 150, 155), M.Metal)
		part(model, root, "HookTip", V3(0.3, 1, 0.3), CF(i * 2 + 1.0, 2.9, 2.4), C3(150, 150, 155), M.Metal)
	end
	emitter(b.Torso, {Name = "HeavyFog", Color = theme.Mist, Rate = 20, Size0 = 8, Size1 = 16, Life = 3, SpeedMax = 3, Accel = V3(0, 0.3, 0), Alpha = 0.6})
	bossAura(b.Torso, b.LegL, theme, 0.9)
end

-- 5) EL MONARCA DEL ABISMO
BOSS_BUILDERS[5] = function(model, root, theme)
	local b = giantBase(model, root, theme, C3(30, 24, 36), C3(18, 14, 22), M.Basalt, M.Slate)
	part(model, root, "Cape", V3(7.6, 11, 0.6), CF(0, -0.5, 2.4), C3(60, 8, 10), M.Fabric)
	for _, side in ipairs({-1, 1}) do
		for k = 1, 3 do
			part(model, root, "ShoulderSpike", V3(0.6, 3, 0.6), CF(side * (4.6 + k * 0.5), 3.6 + k * 0.6, 0) * CFrame.Angles(0, 0, -side * rad(35 + k * 15)), C3(15, 12, 18), M.Basalt)
		end
		part(model, root, "HornBase", V3(0.9, 2.6, 0.9), CF(side * 1.2, 7.4, 0.3) * CFrame.Angles(0, 0, -side * rad(25)), C3(20, 16, 22), M.Basalt)
		part(model, root, "HornTip", V3(0.7, 2.4, 0.7), CF(side * 2.1, 9.2, 0.3) * CFrame.Angles(0, 0, -side * rad(50)), theme.Aura, M.Neon)
	end
	pillar(model, root, "CrownBand", 0.6, 3.8, CF(0, 6.7, 0), theme.Eye, M.Neon)
	for i = 1, 7 do
		local a = (i / 7) * math.pi * 2
		part(model, root, "CrownSpike" .. i, V3(0.4, 2.2, 0.4), CF(math.cos(a) * 1.5, 7.6, math.sin(a) * 1.5) * CFrame.Angles(math.sin(a) * 0.27, 0, -math.cos(a) * 0.27), theme.Eye, M.Neon)
	end
	local core = part(model, root, "AbyssCore", V3(2.2, 2.2, 2.2), CF(0, 1.0, -1.9), theme.Eye, M.Neon, 0, BALL)
	light(core, theme.Eye, 25, 3)
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		part(model, root, "Shard" .. i, V3(0.9, 3.4, 0.9), CF(math.cos(a) * 8, 2 + (i % 2) * 5, math.sin(a) * 8) * CFrame.Angles(rad(30 * i), rad(40 * i), 0), theme.Aura, M.Neon, 0.15)
	end
	emitter(b.Torso, {Name = "AbyssFlames", Texture = FIRE, Color = theme.Aura, Rate = 30, Size0 = 3, Size1 = 1, Life = 1.2, SpeedMin = 2, SpeedMax = 6, Accel = V3(0, 12, 0), Glow = 1, Alpha = 0.2})
	bossAura(b.Torso, b.LegL, theme, 1.5)
end

function ProceduralModels.BuildBoss(stageNumber)
	local stage = math.clamp(math.floor(tonumber(stageNumber) or 30), 1, 150)
	local bossIndex = math.clamp(math.floor(stage / 30), 1, 5)
	local theme = getTheme(bossIndex)
	local model, root = newModel("Boss" .. bossIndex)
	BOSS_BUILDERS[bossIndex](model, root, theme)
	model:SetAttribute("BossName", BOSS_NAMES[bossIndex])
	return finalize(model, "BOSS", 8, bossIndex == 3 and 1 or 0)
end

---------------------------------------------------------------- API
-- Misma lógica que GameManager: %30 jefe, par fantasma, impar asesino
function ProceduralModels.Build(stageNumber)
	local stage = math.clamp(math.floor(tonumber(stageNumber) or 1), 1, 150)
	local biome = math.clamp(math.ceil(stage / 30), 1, 5)
	if stage % 30 == 0 then
		return ProceduralModels.BuildBoss(stage), "BOSS"
	elseif stage % 2 == 0 then
		return ProceduralModels.BuildGhost(biome), "GHOST"
	end
	return ProceduralModels.BuildKiller(biome), "KILLER"
end

-- Apaga/enciende partículas y trails (llámalo solo al cambiar de estado, p. ej. por distancia)
function ProceduralModels.SetEffectsEnabled(model, enabled)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Trail") then
			d.Enabled = enabled
		end
	end
end

return ProceduralModels
