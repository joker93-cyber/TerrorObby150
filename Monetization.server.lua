local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------- CONFIGURACIÓN (único sitio que editas)
local SKIP_STAGE_PRODUCT_ID = 3721391740
local VIP_GAMEPASS_ID = 2052196520
----------------------------------------------------------------

local VIP_WALKSPEED = 22
local RETRIES = 4
local DATA_WAIT = 20
local PROGRESS_PREFIX = "Plr_"

local ProgressStore = DataStoreService:GetDataStore("HorrorObby150_Prod_v2") -- mismo que GameManager
local ReceiptStore = DataStoreService:GetDataStore("HorrorObby150_Receipts_v1")

local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local NOT_YET = Enum.ProductPurchaseDecision.NotProcessedYet

-- Atributos primero, evento después: el cliente los lee al ver ShopNotify
ReplicatedStorage:SetAttribute("SkipStageProductId", SKIP_STAGE_PRODUCT_ID)
ReplicatedStorage:SetAttribute("VipGamePassId", VIP_GAMEPASS_ID)

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "ShopNotify"
notifyEvent.Parent = ReplicatedStorage

if SKIP_STAGE_PRODUCT_ID <= 0 or VIP_GAMEPASS_ID <= 0 then
	warn("[Monetization] Configura SKIP_STAGE_PRODUCT_ID y VIP_GAMEPASS_ID al inicio de este script.")
end

---------------------------------------------------------------- ESTADO
local vipOwners = {}
local joinClock = {}
local inFlight = {}
local playerLocks = {}

---------------------------------------------------------------- UTILIDADES
local function retry(fn)
	local lastErr
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt)
	end
	warn("[Monetization] DataStore/Marketplace falló: " .. tostring(lastErr))
	return false, nil
end

local function totalStages()
	return workspace:GetAttribute("TotalStages") or 150
end

local function notify(player, message)
	if player.Parent then
		notifyEvent:FireClient(player, message)
	end
end

-- Serializa compras del mismo jugador (evita que dos saltos calculen la misma etapa)
local function withLock(userId, fn)
	local waited = 0
	while playerLocks[userId] do
		task.wait(0.1)
		waited += 0.1
		if waited > 30 then
			return false, "lock timeout"
		end
	end
	playerLocks[userId] = true
	local ok, result = pcall(fn)
	playerLocks[userId] = nil
	return ok, result
end

local function readStoredStage(stored)
	if type(stored) == "number" then
		return stored
	elseif type(stored) == "table" and type(stored.Stage) == "number" then
		return stored.Stage
	end
	return 1
end

local function waitForDataReady(player)
	local deadline = (joinClock[player] or 0) + DATA_WAIT
	while player.Parent and player:GetAttribute("DataReady") ~= true and os.clock() < deadline do
		task.wait(0.25)
	end
end

local function teleportToStage(player, stage)
	if player:GetAttribute("IsHidden") == true then
		-- Escondido: respawn limpio; GameManager lo coloca en su checkpoint
		pcall(function()
			player:LoadCharacter()
		end)
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local folder = workspace:FindFirstChild("Checkpoints")
	local cp = folder and folder:FindFirstChild(tostring(stage))
	if char and hum and hum.Health > 0 and cp then
		char:PivotTo(cp.CFrame * CFrame.new(0, 4, 0))
	end
end

---------------------------------------------------------------- PRODUCTO: SALTAR ETAPA
local function grantSkip(player, receiptInfo)
	local userId = receiptInfo.PlayerId
	local receiptKey = "R_" .. receiptInfo.PurchaseId -- GUID único
	local progressKey = PROGRESS_PREFIX .. userId

	-- 1) ¿Ya se procesó? (idempotencia entre servidores y reinicios)
	local okRead, record = retry(function()
		return ReceiptStore:GetAsync(receiptKey)
	end)
	if not okRead then
		return NOT_YET
	end
	if type(record) == "table" and record.Done then
		return GRANTED
	end

	-- 2) Esperar a que GameManager termine de cargar los datos del jugador
	waitForDataReady(player)
	if not player.Parent then
		return NOT_YET
	end

	-- 3) Crear el registro con la etapa destino (una sola vez; si existe, se reutiliza)
	if type(record) ~= "table" then
		local ls = player:WaitForChild("leaderstats", 10)
		local stageVal = ls and ls:WaitForChild("Etapa", 5)
		if not stageVal then
			return NOT_YET
		end
		local okStored, stored = retry(function()
			return ProgressStore:GetAsync(progressKey)
		end)
		if not okStored then
			return NOT_YET
		end
		local newStage = math.min(totalStages(), math.max(readStoredStage(stored), stageVal.Value) + 1)

		local okWrite, winner = retry(function()
			return ReceiptStore:UpdateAsync(receiptKey, function(old)
				if old ~= nil then
					return old
				end
				return {NewStage = newStage, UserId = userId, ProductId = receiptInfo.ProductId, Time = os.time()}
			end)
		end)
		if not okWrite or type(winner) ~= "table" then
			return NOT_YET
		end
		record = winner
	end

	local newStage = record.NewStage
	if type(newStage) ~= "number" then
		return NOT_YET
	end

	-- 4) Guardar progreso de forma monotónica (nunca baja la etapa guardada)
	local okSave = retry(function()
		return ProgressStore:UpdateAsync(progressKey, function(old)
			local data
			if type(old) == "table" then
				data = old
			elseif type(old) == "number" then
				data = {Stage = old, Wins = 0}
			else
				data = {Stage = 1, Wins = 0}
			end
			data.Stage = math.max(tonumber(data.Stage) or 1, newStage)
			data.Wins = tonumber(data.Wins) or 0
			return data
		end)
	end)
	if not okSave then
		return NOT_YET
	end

	-- 5) Marcar como completado (mejor esfuerzo; reaplicar sería inofensivo)
	retry(function()
		return ReceiptStore:UpdateAsync(receiptKey, function(old)
			if type(old) ~= "table" then
				old = record
			end
			old.Done = true
			return old
		end)
	end)

	-- 6) Aplicar en memoria y teletransportar
	local ls = player:FindFirstChild("leaderstats")
	local stageVal = ls and ls:FindFirstChild("Etapa")
	if stageVal and player.Parent then
		if stageVal.Value < newStage then
			stageVal.Value = newStage
		end
		teleportToStage(player, stageVal.Value)
		notify(player, "⏭ ¡Etapa " .. stageVal.Value .. " desbloqueada!")

		if player:GetAttribute("DataReady") ~= true then
			task.spawn(function()
				for _ = 1, 10 do
					task.wait(1)
					if not player.Parent then
						return
					end
					if stageVal.Value < newStage then
						stageVal.Value = newStage
					end
				end
			end)
		end
	end
	return GRANTED
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if SKIP_STAGE_PRODUCT_ID <= 0 or receiptInfo.ProductId ~= SKIP_STAGE_PRODUCT_ID then
		warn("[Monetization] Producto desconocido: " .. tostring(receiptInfo.ProductId))
		return NOT_YET
	end
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return NOT_YET -- se reintentará cuando vuelva a entrar
	end

	local key = tostring(receiptInfo.PurchaseId)
	if inFlight[key] then
		return NOT_YET
	end
	inFlight[key] = true
	local ok, decision = withLock(receiptInfo.PlayerId, function()
		return grantSkip(player, receiptInfo)
	end)
	inFlight[key] = nil

	if ok and decision == GRANTED then
		return GRANTED
	end
	return NOT_YET
end

---------------------------------------------------------------- GAMEPASS: PACK VIP
local function applyVip(player, char)
	if not vipOwners[player] or not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
	if hum then
		hum.WalkSpeed = VIP_WALKSPEED
	end
	if hrp then
		local old = hrp:FindFirstChild("VIPLight")
		if old then
			old:Destroy()
		end
		local light = Instance.new("PointLight")
		light.Name = "VIPLight"
		light.Color = Color3.fromRGB(255, 235, 200)
		light.Range = 16
		light.Brightness = 0.9
		light.Shadows = false
		light.Parent = hrp
	end
end

local function checkVip(player)
	if VIP_GAMEPASS_ID <= 0 then
		return
	end
	local ok, owns = retry(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
	end)
	if ok and owns and player.Parent then
		vipOwners[player] = true
		player:SetAttribute("IsVIP", true)
		if player.Character then
			applyVip(player, player.Character)
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == VIP_GAMEPASS_ID and wasPurchased and player.Parent then
		vipOwners[player] = true
		player:SetAttribute("IsVIP", true)
		if player.Character then
			task.spawn(applyVip, player, player.Character)
		end
		notify(player, "⭐ ¡Pack Superviviente VIP activado!")
	end
end)

---------------------------------------------------------------- JUGADORES
local function onPlayerAdded(player)
	joinClock[player] = os.clock()
	player:SetAttribute("IsVIP", false)
	player.CharacterAdded:Connect(function(char)
		task.spawn(applyVip, player, char)
	end)
	task.spawn(checkVip, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end

Players.PlayerRemoving:Connect(function(player)
	vipOwners[player] = nil
	joinClock[player] = nil
end)
