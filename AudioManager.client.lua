local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local jumpscareEvent = ReplicatedStorage:WaitForChild("TriggerJumpscare")
local victoryEvent = ReplicatedStorage:WaitForChild("VictoryEvent")
local killersFolder = workspace:WaitForChild("ActiveKillers")

---------------------------------------------------------------- SONIDOS
-- IMPORTANTE: son marcadores temporales. Reemplázalos por IDs reales del Creator Store
-- (formato "rbxassetid://123456789"). Con "" el sonido simplemente no suena.
local SOUND_IDS = {
	Heartbeat = "rbxasset://sounds/bass.wav", -- latido (loop corto de ~1 s)
	Whisper = "rbxasset://sounds/swoosh.wav", -- susurro/respiración (loop)
	Scream = "rbxasset://sounds/impact_explosion_03.mp3", -- grito del jumpscare
	Sting = "rbxasset://sounds/impact_explosion_03.mp3", -- aviso 3D al detectar entidad
	Victory = "rbxasset://sounds/victory.wav",
	Hide = "rbxasset://sounds/switch.wav", -- puerta de armario
	Ambient = "", -- drone ambiental opcional (loop)
	-- Risa del screamer de meme al caer. Pega aquí un ID real: "rbxassetid://NUMERO" (vacío = sin sonido)
	Laugh = "",
}

---------------------------------------------------------------- CONFIGURACIÓN
local LOW_MEMORY = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MAX_POOLED = LOW_MEMORY and 4 or 8
local MAX_ONESHOT_SECONDS = 8
local SCAN_INTERVAL = 0.1
local HEART_RANGE = 60
local WHISPER_RANGE = 55
local STING_RANGE = 38
local STING_COOLDOWN = 8
local FADE_SPEED = 4

local KIND = {
	KILLER = {whisperSpeed = 0.9, whisperVol = 0.7, scareSpeed = 1.0, rollMax = 70},
	GHOST = {whisperSpeed = 1.3, whisperVol = 0.8, scareSpeed = 1.4, rollMax = 80},
	BOSS = {whisperSpeed = 0.55, whisperVol = 1.0, scareSpeed = 0.6, rollMax = 140},
	FALL = {whisperSpeed = 1, whisperVol = 0, scareSpeed = 1.0, rollMax = 60},
}

---------------------------------------------------------------- EMISOR 3D (uno solo, persistente)
local emitter = Instance.new("Part")
emitter.Name = "AudioEmitter"
emitter.Size = Vector3.new(1, 1, 1)
emitter.Transparency = 1
emitter.Anchored = true
emitter.CanCollide = false
emitter.CanQuery = false
emitter.CanTouch = false
emitter.CastShadow = false
emitter.Parent = workspace

---------------------------------------------------------------- POOL DE SONIDOS
local holder = Instance.new("Folder")
holder.Name = "AudioPool"
holder.Parent = SoundService

local idle = {}
local created = 0
local playTokens = {}

local function acquire()
	local s = table.remove(idle)
	if s then
		return s
	end
	if created >= MAX_POOLED then
		return nil
	end
	created += 1
	local snd = Instance.new("Sound")
	snd.Name = "PooledSound"
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.Parent = holder
	return snd
end

local function release(s)
	s:Stop()
	s.SoundId = ""
	s.Parent = holder
	table.insert(idle, s)
end

local function playOneShot(soundId, volume, speed, parent)
	if soundId == "" then
		return
	end
	local s = acquire()
	if not s then
		return -- pool lleno: se descarta (protege la RAM)
	end
	s.Looped = false
	s.SoundId = soundId
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 90
	s.Parent = parent or holder

	local token = (playTokens[s] or 0) + 1
	playTokens[s] = token
	local function finish()
		if playTokens[s] == token then
			playTokens[s] = token + 1
			release(s)
		end
	end
	s.Ended:Once(finish)
	task.delay(MAX_ONESHOT_SECONDS, finish) -- red de seguridad si el audio no carga
	s:Play()
end

---------------------------------------------------------------- LOOPS PERSISTENTES
local loopPlaying = {}

local function makeLoop(name, soundId, parent)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = soundId
	s.Looped = true
	s.Volume = 0
	s.Parent = parent
	return s
end

local function setLoop(sound, volume)
	if volume > 0.01 then
		sound.Volume = volume
		if not loopPlaying[sound] then
			loopPlaying[sound] = true
			sound:Play()
		end
	elseif loopPlaying[sound] then
		loopPlaying[sound] = nil
		sound:Stop()
	end
end

local heartbeat = makeLoop("Heartbeat", SOUND_IDS.Heartbeat, SoundService)
local whisper = makeLoop("Whisper", SOUND_IDS.Whisper, emitter)
whisper.RollOffMode = Enum.RollOffMode.InverseTapered
whisper.RollOffMinDistance = 8
whisper.RollOffMaxDistance = 80

if SOUND_IDS.Ambient ~= "" then
	local ambient = makeLoop("Ambient", SOUND_IDS.Ambient, SoundService)
	ambient.Volume = 0.25
	ambient:Play()
end

task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({heartbeat, whisper})
	end)
end)

---------------------------------------------------------------- ESTADO
local nearest = {model = nil, root = nil, dist = math.huge, kind = "KILLER"}
local alive = false
local hidden = player:GetAttribute("IsHidden") == true
local muteUntil = 0
local scanTimer = 0

local heartVol, heartSpeed, whisperVol = 0, 1, 0
local heartTarget, heartSpeedTarget, whisperTarget = 0, 1, 0
local whisperRolloff = 0
local stingedAt = setmetatable({}, {__mode = "k"})

local function scan()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	alive = hrp ~= nil and hum ~= nil and hum.Health > 0

	nearest.model, nearest.root, nearest.dist = nil, nil, math.huge
	if not alive then
		return
	end

	for _, model in ipairs(killersFolder:GetChildren()) do
		local root = model:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local d = (root.Position - hrp.Position).Magnitude
			if d < nearest.dist then
				nearest.dist, nearest.root, nearest.model = d, root, model
			end
		end
	end
	nearest.kind = nearest.model and nearest.model:GetAttribute("Kind") or "KILLER"
end

local function computeTargets()
	if not alive or os.clock() < muteUntil or not nearest.model then
		heartTarget, whisperTarget = 0, 0
		return
	end

	local profile = KIND[nearest.kind] or KIND.KILLER
	local d = nearest.dist
	local heartI = math.clamp(1 - d / HEART_RANGE, 0, 1)
	local whisperI = math.clamp(1 - d / WHISPER_RANGE, 0, 1)

	heartTarget = heartI > 0 and (0.15 + 0.85 * heartI ^ 1.2) * (hidden and 0.55 or 1) or 0
	heartSpeedTarget = (0.8 + 1.1 * heartI) * (hidden and 0.85 or 1)
	whisperTarget = profile.whisperVol * whisperI * (hidden and 0.5 or 1)
	whisper.PlaybackSpeed = profile.whisperSpeed
	if whisperRolloff ~= profile.rollMax then
		whisperRolloff = profile.rollMax
		whisper.RollOffMaxDistance = profile.rollMax
	end

	-- Aviso 3D la primera vez que una entidad entra en rango
	if not hidden and d <= STING_RANGE then
		local last = stingedAt[nearest.model]
		local now = os.clock()
		if not last or now - last > STING_COOLDOWN then
			stingedAt[nearest.model] = now
			emitter.Position = nearest.root.Position
			playOneShot(SOUND_IDS.Sting, 0.7, profile.scareSpeed * 1.1, emitter)
		end
	end
end

local function approach(current, target, maxStep)
	if current < target then
		return math.min(current + maxStep, target)
	end
	return math.max(current - maxStep, target)
end

RunService.Heartbeat:Connect(function(dt)
	scanTimer += dt
	if scanTimer >= SCAN_INTERVAL then
		scanTimer = 0
		scan()
		computeTargets()
	end

	local root = nearest.root
	if root and root.Parent then
		emitter.Position = root.Position
	end

	local step = dt * FADE_SPEED
	heartVol = approach(heartVol, heartTarget, step)
	heartSpeed = approach(heartSpeed, heartSpeedTarget, dt * 1.5)
	whisperVol = approach(whisperVol, whisperTarget, step)

	setLoop(heartbeat, heartVol)
	setLoop(whisper, whisperVol)
	if loopPlaying[heartbeat] then
		heartbeat.PlaybackSpeed = heartSpeed
	end
end)

---------------------------------------------------------------- EVENTOS
jumpscareEvent.OnClientEvent:Connect(function(kind)
	local profile = KIND[kind] or KIND.KILLER
	muteUntil = os.clock() + 2.5
	heartVol, whisperVol = 0, 0
	heartTarget, whisperTarget = 0, 0
	setLoop(heartbeat, 0)
	setLoop(whisper, 0)
	-- Si el jugador activó "Sustos suaves" (botón de HorrorClient) el volumen baja
	local gain = (player:GetAttribute("ReduceScares") == true) and 0.25 or 1
	if kind == "FALL" then
		playOneShot(SOUND_IDS.Laugh, 1 * gain, 1)
	else
		playOneShot(SOUND_IDS.Scream, 1 * gain, profile.scareSpeed)
	end
end)

victoryEvent.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.Victory, 0.9, 1)
end)

player:GetAttributeChangedSignal("IsHidden"):Connect(function()
	local nowHidden = player:GetAttribute("IsHidden") == true
	if nowHidden ~= hidden then
		hidden = nowHidden
		playOneShot(SOUND_IDS.Hide, 0.6, hidden and 0.8 or 1.1)
	end
end)

player.CharacterAdded:Connect(function()
	muteUntil = 0
	heartVol, whisperVol = 0, 0
	heartTarget, whisperTarget = 0, 0
	hidden = false
end)
