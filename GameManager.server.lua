local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

---------------------------------------------------------------- REMOTES
local jumpscareEvent = Instance.new("RemoteEvent")
jumpscareEvent.Name = "TriggerJumpscare"
jumpscareEvent.Parent = ReplicatedStorage

local victoryEvent = Instance.new("RemoteEvent")
victoryEvent.Name = "VictoryEvent"
victoryEvent.Parent = ReplicatedStorage

local ProceduralModels = require(ReplicatedStorage:WaitForChild("ProceduralModels"))

---------------------------------------------------------------- ESPERAR MAPA
local checkpointsFolder = workspace:WaitForChild("Checkpoints")
local killersFolder = workspace:WaitForChild("ActiveKillers")
if not workspace:GetAttribute("MapReady") then
	workspace:GetAttributeChangedSignal("MapReady"):Wait()
end

local STAGE_LENGTH = workspace:GetAttribute("StageLength") or 140
local TOTAL_STAGES = workspace:GetAttribute("TotalStages") or 150

pcall(function()
	Players.RespawnTime = 2
end)

---------------------------------------------------------------- CONSTANTES
local SaveStore = DataStoreService:GetDataStore("HorrorObby150_Prod_v2")
local DATA_PREFIX = "Plr_"
local DATA_RETRIES = 4
local AUTOSAVE_INTERVAL = 60

local WIN_NAME = "150_WIN"
local CP_DEBOUNCE = 0.25

local MAX_HIDE_TIME = 8
local HIDE_COOLDOWN = 0.8
local LOCKER_MAX_DISTANCE = 14

local AI_STEP = 0.05
local WAKE_DISTANCE = 140
local ENTITY_OFFSET_Z = 42
local BOSS_RING_INTERVAL = 3.8
local BOSS_RING_RANGE = 60
local RING_DAMAGE = 50
local RING_Y = 6.6
local TOUCH_DEBOUNCE = 1.5
local SCARE_COOLDOWN = 3 -- nunca dos screamers seguidos
local FALL_DEATH_Y = -8 -- morir por debajo de esta altura cuenta como caída

---------------------------------------------------------------- ESTADO POR JUGADOR
local touchDebounce = {}
local scareDebounce = {}
local hideCooldown = {}
local cpDebounce = {}
local hideState = {}      -- [player] = {locker, char, saved, token}
local lockerOccupant = {} -- [locker] = player
local ready = {}          -- ya puede colocarse en su checkpoint
local canSave = {}        -- la carga fue exitosa: se permite guardar
local lastSaved = {}
local activeSaves = 0
local hideTokenCounter = 0

---------------------------------------------------------------- DATASTORE
local function retry(fn, attempts)
	local lastErr
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt)
	end
	warn("[GameManager] DataStore falló: " .. tostring(lastErr))
	return false, nil
end

local function savePlayer(player)
	if not canSave[player] then
		return false
	end
	local ls = player:FindFirstChild("leaderstats")
	local stageVal = ls and ls:FindFirstChild("Etapa")
	local winsVal = ls and ls:FindFirstChild("Victorias")
	if not stageVal or not winsVal then
		return false
	end

	local data = {Stage = stageVal.Value, Wins = winsVal.Value}
	local last = lastSaved[player]
	if last and last.Stage == data.Stage and last.Wins == data.Wins then
		return true
	end

	activeSaves += 1
	local ok = retry(function()
		return SaveStore:UpdateAsync(DATA_PREFIX .. player.UserId, function()
			return data
		end)
	end, DATA_RETRIES)
	if ok then
		lastSaved[player] = data
	end
	activeSaves -= 1
	return ok
end

---------------------------------------------------------------- SCREAMERS
-- kind: "FALL" (meme al caer), "KILLER", "GHOST" o "BOSS" (terror al ser atrapado)
local function sendScare(player, kind)
	if scareDebounce[player] then
		return
	end
	scareDebounce[player] = true
	jumpscareEvent:FireClient(player, kind)
	task.delay(SCARE_COOLDOWN, function()
		scareDebounce[player] = nil
	end)
end

---------------------------------------------------------------- ARMARIOS
local function startHideCooldown(player)
	hideCooldown[player] = true
	task.delay(HIDE_COOLDOWN, function()
		hideCooldown[player] = nil
	end)
end

local function clearHideState(player)
	local state = hideState[player]
	if state then
		if lockerOccupant[state.locker] == player then
			lockerOccupant[state.locker] = nil
		end
		hideState[player] = nil
	end
	player:SetAttribute("IsHidden", false)
end

local function leaveLocker(player)
	local state = hideState[player]
	if not state then
		return
	end
	local locker = state.locker
	hideState[player] = nil
	if lockerOccupant[locker] == player then
		lockerOccupant[locker] = nil
	end
	player:SetAttribute("IsHidden", false)

	local char = player.Character
	if not char or char ~= state.char then
		return -- el personaje murió o fue reemplazado: nada que restaurar
	end

	for inst, original in pairs(state.saved) do
		if inst.Parent then
			inst.Transparency = original
		end
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
		local side = (locker.Position.X >= 0) and -1 or 1
		local exitPos = Vector3.new(
			locker.Position.X + side * 4.5,
			locker.Position.Y - (locker.Size.Y / 2) + 3.6,
			locker.Position.Z
		)
		char:PivotTo(CFrame.new(exitPos))
	end
end

local function enterLocker(player, locker)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end

	local saved = {}
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d ~= hrp then
			saved[d] = d.Transparency
			d.Transparency = 1
		end
	end

	hrp.Anchored = true
	char:PivotTo(locker.CFrame)

	hideTokenCounter += 1
	local token = hideTokenCounter
	hideState[player] = {locker = locker, char = char, saved = saved, token = token}
	lockerOccupant[locker] = player
	player:SetAttribute("IsHidden", true)

	-- Límite máximo dentro del armario (el token evita expulsiones por temporizadores viejos)
	task.delay(MAX_HIDE_TIME, function()
		local state = hideState[player]
		if state and state.token == token then
			leaveLocker(player)
		end
	end)
end

local function onLockerTriggered(locker, player)
	if hideCooldown[player] then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	-- Validación de distancia en servidor
	if (hrp.Position - locker.Position).Magnitude > LOCKER_MAX_DISTANCE then
		return
	end

	local state = hideState[player]
	if state then
		if state.locker ~= locker then
			return
		end
		startHideCooldown(player)
		leaveLocker(player)
	else
		local occupant = lockerOccupant[locker]
		if occupant and occupant ~= player then
			return
		end
		startHideCooldown(player)
		enterLocker(player, locker)
	end
end

---------------------------------------------------------------- CHECKPOINTS
local function placeAtCheckpoint(player, char)
	local ls = player:FindFirstChild("leaderstats")
	local stageVal = ls and ls:FindFirstChild("Etapa")
	if not stageVal or not char then
		return
	end
	local cp = checkpointsFolder:FindFirstChild(tostring(stageVal.Value))
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp or not cp or not char.Parent then
		return
	end
	char:PivotTo(cp.CFrame * CFrame.new(0, 4, 0))
end

local function handleCheckpointTouch(cp, hit)
	local char = hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player or cpDebounce[player] or not ready[player] then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	local stageVal = ls and ls:FindFirstChild("Etapa")
	if not stageVal then
		return
	end

	cpDebounce[player] = true
	task.delay(CP_DEBOUNCE, function()
		cpDebounce[player] = nil
	end)

	if cp.Name == WIN_NAME then
		if stageVal.Value >= TOTAL_STAGES then
			local winsVal = ls:FindFirstChild("Victorias")
			if winsVal then
				winsVal.Value += 1
			end
			stageVal.Value = 1
			victoryEvent:FireClient(player, winsVal and winsVal.Value or 1)
			task.spawn(savePlayer, player)
			placeAtCheckpoint(player, char)
		end
		return
	end

	local cpNum = tonumber(cp.Name)
	if cpNum and cpNum == stageVal.Value + 1 then
		stageVal.Value = cpNum
	end
end

local wiredCheckpoints = {}
local function wireCheckpoint(cp)
	if wiredCheckpoints[cp] or not cp:IsA("BasePart") then
		return
	end
	wiredCheckpoints[cp] = true
	cp.Touched:Connect(function(hit)
		handleCheckpointTouch(cp, hit)
	end)
end

for _, cp in ipairs(checkpointsFolder:GetChildren()) do
	wireCheckpoint(cp)
end
checkpointsFolder.ChildAdded:Connect(wireCheckpoint)

---------------------------------------------------------------- TAGS: TRAMPAS, FADE, ARMARIOS, MOVEDORES
local function bindTag(tag, fn)
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		task.spawn(fn, inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
end

local wiredKill = {}
local function wireKillBrick(part)
	if wiredKill[part] or not part:IsA("BasePart") then
		return
	end
	wiredKill[part] = true
	part.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player or player:GetAttribute("IsHidden") then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			if part.Name == "VoidKill" then
				sendScare(player, "FALL")
			end
			hum.Health = 0
		end
	end)
end

local fadeBusy = {}
local function wireFadeBrick(part)
	if fadeBusy[part] ~= nil or not part:IsA("BasePart") then
		return
	end
	fadeBusy[part] = false
	part.Touched:Connect(function(hit)
		if fadeBusy[part] then
			return
		end
		local char = hit.Parent
		if not char or not Players:GetPlayerFromCharacter(char) then
			return
		end
		fadeBusy[part] = true
		for i = 1, 5 do
			part.Transparency = i * 0.2
			task.wait(0.08)
		end
		part.CanCollide = false
		task.wait(2.5)
		part.Transparency = 0
		part.CanCollide = true
		fadeBusy[part] = false
	end)
end

local wiredLockers = {}
local function wireLocker(locker)
	if wiredLockers[locker] or not locker:IsA("BasePart") then
		return
	end
	local prompt = locker:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	wiredLockers[locker] = true
	prompt.Triggered:Connect(function(player)
		onLockerTriggered(locker, player)
	end)
end

local moversByStage = {}
local activeStages = {}
local registeredMovers = {}
local function registerMover(part)
	if registeredMovers[part] or not part:IsA("BasePart") then
		return
	end
	local stage = part:GetAttribute("Stage")
	local baseCF = part:GetAttribute("BaseCF")
	if typeof(stage) ~= "number" or typeof(baseCF) ~= "CFrame" then
		return
	end
	registeredMovers[part] = true
	local list = moversByStage[stage]
	if not list then
		list = {}
		moversByStage[stage] = list
	end
	table.insert(list, {
		part = part,
		base = baseCF,
		amp = part:GetAttribute("Amp") or 8,
		speed = part:GetAttribute("Speed") or 2,
		phase = part:GetAttribute("Phase") or 0,
	})
end

bindTag("KillBrick", wireKillBrick)
bindTag("FadeBrick", wireFadeBrick)
bindTag("HideLocker", wireLocker)
bindTag("MovingKill", registerMover)

---------------------------------------------------------------- ENTIDADES (FANTASMAS, ASESINOS, JEFES)
local entities = {}

local function spawnBossRing(pos)
	local ring = Instance.new("Part")
	ring.Name = "BossShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(1, 4, 4)
	ring.CFrame = CFrame.new(pos.X, RING_Y, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(255, 30, 0)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false

	local hitSet = {} -- un solo golpe por jugador y por onda
	ring.Touched:Connect(function(hit)
		local char = hit.Parent
		local plr = char and Players:GetPlayerFromCharacter(char)
		if not plr or hitSet[plr] or plr:GetAttribute("IsHidden") then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hitSet[plr] = true
			hum:TakeDamage(RING_DAMAGE)
		end
	end)

	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(1, 42, 42),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 2.1)
end

local function spawnEntity(stage)
	local cp = checkpointsFolder:FindFirstChild(tostring(stage))
	if not cp then
		return
	end

	local okBuild, model, kind = pcall(ProceduralModels.Build, stage)
	if not okBuild or not model then
		warn("[GameManager] No se pudo construir entidad de etapa " .. stage .. ": " .. tostring(model))
		return
	end
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end

	local isBoss = (kind == "BOSS")
	local isGhost = (kind == "GHOST")
	local foot = model:GetAttribute("FootOffset") or 3
	local hover = model:GetAttribute("HoverHeight") or 0
	local floorTop = cp.Position.Y + (cp.Size.Y / 2)
	local startPos = Vector3.new(cp.Position.X, floorTop + foot + hover, cp.Position.Z - ENTITY_OFFSET_Z)

	model.Name = isBoss and ("BOSS_Etapa_" .. stage) or (isGhost and ("Espiritu_" .. stage) or ("Asesino_" .. stage))
	model:PivotTo(CFrame.new(startPos))
	ProceduralModels.SetEffectsEnabled(model, false)
	model.Parent = killersFolder

	root.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player or player:GetAttribute("IsHidden") or touchDebounce[player] then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return
		end
		touchDebounce[player] = true
		sendScare(player, kind)
		hum.Health = 0
		task.delay(TOUCH_DEBOUNCE, function()
			touchDebounce[player] = nil
		end)
	end)

	table.insert(entities, {
		model = model,
		kind = kind,
		isBoss = isBoss,
		isGhost = isGhost,
		pos = startPos,
		home = startPos,
		look = Vector3.new(0, 0, 1),
		speed = isBoss and 15.5 or (isGhost and 14.5 or 16),
		detect = isBoss and 55 or 42,
		awake = false,
		phase = math.random() * math.pi * 2,
		nextRing = 0,
	})
end

local function planarDist(a, b)
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function updateEntity(e, alive, step, now)
	if not e.model.Parent then
		return
	end

	local nearestAny = math.huge
	local target = nil
	local targetDist = e.detect
	for _, a in ipairs(alive) do
		local d = planarDist(a.pos, e.pos)
		if d < nearestAny then
			nearestAny = d
		end
		if not a.hidden and d < targetDist then
			targetDist = d
			target = a.pos
		end
	end

	-- Dormir entidades lejanas: sin movimiento, sin partículas, sin replicación
	local shouldWake = nearestAny <= WAKE_DISTANCE
	if shouldWake ~= e.awake then
		e.awake = shouldWake
		ProceduralModels.SetEffectsEnabled(e.model, shouldWake)
	end
	if not shouldWake then
		return
	end

	local dest = target or e.home
	local dx, dz = dest.X - e.pos.X, dest.Z - e.pos.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	local moved = false
	if dist > 1.5 then -- evita vectores cero (sin CFrame NaN)
		local move = math.min(e.speed * step, dist)
		e.pos = Vector3.new(e.pos.X + (dx / dist) * move, e.pos.Y, e.pos.Z + (dz / dist) * move)
		e.look = Vector3.new(dx / dist, 0, dz / dist)
		moved = true
	end

	if moved or e.isGhost then
		local y = e.pos.Y
		if e.isGhost then
			y += math.sin(now * 2 + e.phase) * 0.4
		end
		local p = Vector3.new(e.pos.X, y, e.pos.Z)
		e.model:PivotTo(CFrame.lookAt(p, p + e.look))
	end

	if e.isBoss and nearestAny <= BOSS_RING_RANGE and now >= e.nextRing then
		e.nextRing = now + BOSS_RING_INTERVAL
		spawnBossRing(e.pos)
	end
end

local function stepAI(step, now)
	local alive = {}
	local newActive = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			table.insert(alive, {pos = hrp.Position, hidden = plr:GetAttribute("IsHidden") == true})
			local idx = math.clamp(math.floor(-hrp.Position.Z / STAGE_LENGTH) + 1, 1, TOTAL_STAGES)
			for s = math.max(1, idx - 1), math.min(TOTAL_STAGES, idx + 1) do
				newActive[s] = true
			end
		end
	end
	activeStages = newActive

	for _, e in ipairs(entities) do
		updateEntity(e, alive, step, now)
	end
end

for s = 5, TOTAL_STAGES, 5 do
	spawnEntity(s)
end

-- Un único bucle para toda la IA y los movedores de las etapas cercanas
local aiAccum = 0
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()

	for stage in pairs(activeStages) do
		local list = moversByStage[stage]
		if list then
			for _, m in ipairs(list) do
				if m.part.Parent then
					m.part.CFrame = m.base * CFrame.new(m.amp * math.sin(now * m.speed + m.phase), 0, 0)
				end
			end
		end
	end

	aiAccum += dt
	if aiAccum < AI_STEP then
		return
	end
	local step = aiAccum
	aiAccum = 0
	stepAI(step, now)
end)

---------------------------------------------------------------- JUGADORES
local function onPlayerAdded(player)
	player:SetAttribute("IsHidden", false)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local stage = Instance.new("IntValue")
	stage.Name = "Etapa"
	stage.Value = 1
	stage.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Victorias"
	wins.Value = 0
	wins.Parent = leaderstats

	leaderstats.Parent = player

	-- Conectar ANTES de cargar datos para no perder el primer spawn
	player.CharacterAdded:Connect(function(char)
		clearHideState(player)
		if ready[player] then
			placeAtCheckpoint(player, char)
		end
		-- Respaldo: si muere muy por debajo del mapa, también cuenta como caída
		task.spawn(function()
			local hum = char:WaitForChild("Humanoid", 10)
			local hrp = char:WaitForChild("HumanoidRootPart", 10)
			if hum and hrp then
				hum.Died:Once(function()
					if hrp.Position.Y < FALL_DEATH_Y then
						sendScare(player, "FALL")
					end
				end)
			end
		end)
	end)

	local ok, data = retry(function()
		return SaveStore:GetAsync(DATA_PREFIX .. player.UserId)
	end, DATA_RETRIES)

	if not player.Parent then
		return
	end

	if ok then
		canSave[player] = true -- solo se guarda si la carga fue exitosa
		local savedStage, savedWins
		if type(data) == "number" then
			savedStage, savedWins = data, 0
		elseif type(data) == "table" then
			savedStage, savedWins = data.Stage, data.Wins
		end
		if type(savedStage) == "number" then
			stage.Value = math.clamp(math.floor(savedStage), 1, TOTAL_STAGES)
		end
		if type(savedWins) == "number" then
			wins.Value = math.max(0, math.floor(savedWins))
		end
		if data ~= nil then
			lastSaved[player] = {Stage = stage.Value, Wins = wins.Value}
		end
	else
		warn("[GameManager] Datos no cargados para " .. player.Name .. ": se juega sin guardar para no borrar progreso.")
	end

	ready[player] = true
	player:SetAttribute("DataReady", true) -- Monetization espera esta señal antes de conceder compras
	if player.Character then
		placeAtCheckpoint(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	savePlayer(player)

	touchDebounce[player] = nil
	scareDebounce[player] = nil
	hideCooldown[player] = nil
	cpDebounce[player] = nil
	clearHideState(player)
	ready[player] = nil
	canSave[player] = nil
	lastSaved[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end

-- Autoguardado periódico
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, plr in ipairs(Players:GetPlayers()) do
			task.spawn(savePlayer, plr)
		end
	end
end)

-- Guardado al cerrar el servidor
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		task.spawn(savePlayer, plr)
	end
	local start = os.clock()
	while activeSaves > 0 and os.clock() - start < 25 do
		task.wait(0.1)
	end
end)
