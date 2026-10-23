-- AudioManager.client.lua (Sistema de Audio de Terror Dinámico y Latidos)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Limpiar sonidos previos si existen
for _, s in ipairs(SoundService:GetChildren()) do
	if s:IsA("Sound") then
		s:Destroy()
	end
end

-- 1. AMBIENTE DE TERROR CONSTANTE (Viento frío / Drone de manicomio)
local ambientSound = Instance.new("Sound")
ambientSound.Name = "HorrorAmbience"
ambientSound.SoundId = "rbxassetid://9114221580" -- Ambiente oscuro oficial de Roblox
ambientSound.Volume = 0.45
ambientSound.PlaybackSpeed = 0.75
ambientSound.Looped = true
ambientSound.Parent = SoundService
ambientSound:Play()

-- 2. LATIDO DEL CORAZÓN (Se activa y acelera cuando un monstruo está cerca)
local heartbeatSound = Instance.new("Sound")
heartbeatSound.Name = "Heartbeat"
heartbeatSound.SoundId = "rbxassetid://9113652855" -- Latido profundo
heartbeatSound.Volume = 0
heartbeatSound.PlaybackSpeed = 1
heartbeatSound.Looped = true
heartbeatSound.Parent = SoundService
heartbeatSound:Play()

-- 3. SUSURROS / TENSIÓN DE PERSECUCIÓN
local chaseMusic = Instance.new("Sound")
chaseMusic.Name = "ChaseTension"
chaseMusic.SoundId = "rbxassetid://1839246711" -- Tensión de persecución
chaseMusic.Volume = 0
chaseMusic.PlaybackSpeed = 0.95
chaseMusic.Looped = true
chaseMusic.Parent = SoundService
chaseMusic:Play()

-- 4. SONIDO DE GRITO / JUMPSCARE AL MORIR
local jumpscareSound = Instance.new("Sound")
jumpscareSound.Name = "JumpscareScream"
jumpscareSound.SoundId = "rbxassetid://9114397505"
jumpscareSound.Volume = 1.2
jumpscareSound.PlaybackSpeed = 0.9
jumpscareSound.Parent = SoundService

local function connectCharacterSounds(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.Died:Connect(function()
			jumpscareSound:Play()
		end)
	end
end

if player.Character then
	task.spawn(connectCharacterSounds, player.Character)
end
player.CharacterAdded:Connect(connectCharacterSounds)

-- 5. RADAR DE PROXIMIDAD: Calcula qué tan cerca está el monstruo para acelerar el corazón
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local enemiesFolder = Workspace:FindFirstChild("Enemies")

	if not hrp or not enemiesFolder then
		heartbeatSound.Volume = 0
		chaseMusic.Volume = 0
		return
	end

	local closestDist = 999
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("BasePart") then
			local dist = (enemy.Position - hrp.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
			end
		end
	end

	-- Si hay un asesino o jefe a menos de 45 studs, sube el volumen del corazón y la tensión
	if closestDist < 45 then
		local intensity = math.clamp(1 - (closestDist / 45), 0, 1)
		heartbeatSound.Volume = intensity * 1.5
		heartbeatSound.PlaybackSpeed = 0.9 + (intensity * 0.9) -- Latido más rápido al acercarse
		chaseMusic.Volume = intensity * 0.7
	else
		heartbeatSound.Volume = math.max(0, heartbeatSound.Volume - dt)
		chaseMusic.Volume = math.max(0, chaseMusic.Volume - dt)
	end
end)
