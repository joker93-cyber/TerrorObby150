-- ShopClient.client.lua
-- Ubicación: StarterPlayer.StarterPlayerScripts.ShopClient
-- Súper Tienda adaptable (iPhone, PC, Consola) para adquirir el Pase VIP (ID: 2052196520),
-- cargas del Crucifijo Sagrado y saltos de etapa usando monedas del juego.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local VIP_GAMEPASS_ID = 2052196520

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 20)
local shopPurchaseEvent = remotesFolder and remotesFolder:WaitForChild("ShopCoinPurchase", 20)

local oldShop = playerGui:FindFirstChild("TerrorShopGui")
if oldShop then
	oldShop:Destroy()
end

local shopGui = Instance.new("ScreenGui")
shopGui.Name = "TerrorShopGui"
shopGui.ResetOnSpawn = false
shopGui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenShopButton"
openBtn.Size = UDim2.fromOffset(135, 48)
openBtn.Position = UDim2.new(0, 16, 0.5, -24)
openBtn.BackgroundColor3 = Color3.fromRGB(215, 145, 20)
openBtn.TextColor3 = Color3.fromRGB(20, 15, 10)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 15
openBtn.Text = "🛒 TIENDA VIP"
openBtn.Parent = shopGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 10)
openCorner.Parent = openBtn

local modal = Instance.new("Frame")
modal.Name = "ShopModal"
modal.Size = UDim2.fromOffset(360, 290)
modal.Position = UDim2.new(0.5, -180, 0.5, -145)
modal.BackgroundColor3 = Color3.fromRGB(22, 18, 28)
modal.Visible = false
modal.Parent = shopGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 14)
modalCorner.Parent = modal

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 215, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "⚡ SÚPER TIENDA DE SUPERVIVENCIA ⚡"
title.Parent = modal

local function createShopOffer(text, posY, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -32, 0, 52)
	btn.Position = UDim2.fromOffset(16, posY)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	btn.Parent = modal

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	btn.Activated:Connect(callback)
	return btn
end

createShopOffer(
	"👑 Pase VIP (Velocidad + Escudo + Crucifijo) - 250 R$",
	60,
	Color3.fromRGB(185, 115, 15),
	function()
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(localPlayer, VIP_GAMEPASS_ID)
		end)
	end
)

createShopOffer(
	"✝️ +1 Carga de Crucifijo Sagrado (40 Monedas)",
	124,
	Color3.fromRGB(125, 30, 40),
	function()
		if shopPurchaseEvent then
			shopPurchaseEvent:FireServer("CrucifixCharge")
		end
	end
)

createShopOffer(
	"⚡ Saltar Etapa Actual (120 Monedas)",
	188,
	Color3.fromRGB(45, 85, 145),
	function()
		if shopPurchaseEvent then
			shopPurchaseEvent:FireServer("SkipStageCoin")
		end
	end
)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(110, 32)
closeBtn.Position = UDim2.new(0.5, -55, 1, -40)
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Text = "Cerrar"
closeBtn.Parent = modal

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

openBtn.Activated:Connect(function()
	modal.Visible = not modal.Visible
end)

closeBtn.Activated:Connect(function()
	modal.Visible = false
end)
