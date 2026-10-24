-- Monetization.server.lua
-- Ubicación: ServerScriptService.Monetization
-- Verifica en el servidor el Pase VIP (ID: 2052196520), gestiona compras con monedas
-- y procesa recibos de Developer Products de forma segura.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VIP_GAMEPASS_ID = 2052196520

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
local clientNotificationEvent = remotesFolder and remotesFolder:WaitForChild("ClientNotification", 15)
local shopPurchaseEvent = remotesFolder and remotesFolder:WaitForChild("ShopCoinPurchase", 15)

local function applyVIPBenefits(player)
	player:SetAttribute("HasVIP", true)
	player:SetAttribute("VIPShieldReady", true)
	local currentCharges = player:GetAttribute("CrucifixCharges") or 1
	if currentCharges < 2 then
		player:SetAttribute("CrucifixCharges", 2)
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 22
	end
end

local function checkPlayerVIP(player)
	local success, ownsVIP = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
	end)
	if success and ownsVIP then
		applyVIPBenefits(player)
	else
		player:SetAttribute("HasVIP", false)
	end
end

Players.PlayerAdded:Connect(checkPlayerVIP)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkPlayerVIP, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased and gamePassId == VIP_GAMEPASS_ID then
		applyVIPBenefits(player)
		if clientNotificationEvent then
			clientNotificationEvent:FireClient(player, "👑 ¡PASE VIP ACTIVADO! Velocidad mejorada, Escudo VIP y Crucifijo extra.")
		end
	end
end)

local PurchaseCooldowns = {}
if shopPurchaseEvent then
	shopPurchaseEvent.OnServerEvent:Connect(function(player, itemType)
		if type(itemType) ~= "string" then return end
		local now = os.clock()
		if now - (PurchaseCooldowns[player.UserId] or 0) < 0.8 then return end
		PurchaseCooldowns[player.UserId] = now

		if _G.TerrorObbyGrantItem then
			local _, message = _G.TerrorObbyGrantItem(player, itemType)
			if clientNotificationEvent then
				clientNotificationEvent:FireClient(player, message)
			end
		end
	end)
end

local ProcessedReceipts = {}
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local purchaseId = receiptInfo.PurchaseId
	if ProcessedReceipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	ProcessedReceipts[purchaseId] = true
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("[Monetization] Servicio VIP (2052196520) y Tienda inicializados en el servidor.")
