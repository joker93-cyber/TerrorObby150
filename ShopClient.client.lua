local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local notifyEvent = ReplicatedStorage:WaitForChild("ShopNotify")

---------------------------------------------------------------- HINTS POR TIPO DE ENTRADA
local HINTS = {
	skip = {pc = " [G]", pad = " (X)", touch = ""},
	vip = {pc = " [V]", pad = " (D-Pad →)", touch = ""},
	toggle = {pc = "", pad = " (D-Pad ↑)", touch = ""},
	flash = {pc = "[F]", pad = "(Y)", touch = ""},
}

local function inputKind()
	local t = UserInputService:GetLastInputType()
	if t == Enum.UserInputType.Touch then
		return "touch"
	elseif string.sub(t.Name, 1, 7) == "Gamepad" then
		return "pad"
	elseif t == Enum.UserInputType.None then
		if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
			return "pad"
		end
		return UserInputService.TouchEnabled and "touch" or "pc"
	end
	return "pc"
end

---------------------------------------------------------------- GUI DE TIENDA
local gui = Instance.new("ScreenGui")
gui.Name = "ShopHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.BackgroundTransparency = 1
panel.Size = UDim2.fromScale(0.2, 0.3)
panel.Position = UDim2.fromScale(0.015, 0.2)
panel.Parent = gui

local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MinSize = Vector2.new(150, 110)
panelLimit.MaxSize = Vector2.new(320, 230)
panelLimit.Parent = panel

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0.04, 0)
list.Parent = panel

local function makeButton(name, order, textColor)
	local b = Instance.new("TextButton")
	b.Name = name
	b.LayoutOrder = order
	b.Size = UDim2.fromScale(1, 0.3)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	b.BackgroundTransparency = 0.15
	b.TextColor3 = textColor
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Selectable = true -- cursor virtual del mando
	b.Active = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = b

	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = 10
	textLimit.MaxTextSize = 26
	textLimit.Parent = b

	b.Parent = panel
	return b
end

local toggleBtn = makeButton("ToggleShop", 1, Color3.fromRGB(230, 230, 235))
local skipBtn = makeButton("SkipStage", 2, Color3.fromRGB(255, 220, 120))
local vipBtn = makeButton("VipPack", 3, Color3.fromRGB(255, 200, 70))

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.fromScale(0.5, 0.04)
toast.Size = UDim2.fromScale(0.5, 0.07)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
toast.BackgroundTransparency = 0.2
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.Font = Enum.Font.GothamBold
toast.TextScaled = true
toast.Visible = false
toast.ZIndex = 5
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0.25, 0)
toastCorner.Parent = toast

local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MinSize = Vector2.new(200, 30)
toastLimit.MaxSize = Vector2.new(640, 56)
toastLimit.Parent = toast

---------------------------------------------------------------- LÓGICA
local expanded = true
local flashHint = nil
local toastToken = 0
local lastPrompt = 0

local function totalStages()
	return workspace:GetAttribute("TotalStages") or 150
end

local function getStage()
	local ls = player:FindFirstChild("leaderstats")
	local v = ls and ls:FindFirstChild("Etapa")
	return v and v.Value or 1
end

local function refreshLabels()
	local kind = inputKind()
	local isVip = player:GetAttribute("IsVIP") == true

	toggleBtn.Text = (expanded and "🛒 TIENDA ▾" or "🛒 TIENDA ▸") .. HINTS.toggle[kind]
	if getStage() >= totalStages() then
		skipBtn.Text = "⏭ Etapa MÁX"
	else
		skipBtn.Text = "⏭ Saltar Etapa" .. HINTS.skip[kind]
	end
	vipBtn.Text = isVip and "⭐ VIP ACTIVO ✓" or ("⭐ Pack VIP" .. HINTS.vip[kind])
	vipBtn.TextTransparency = isVip and 0.35 or 0

	if flashHint then
		flashHint.Text = HINTS.flash[kind]
	end
end

local function setExpanded(value)
	expanded = value
	skipBtn.Visible = value
	vipBtn.Visible = value
	refreshLabels()
end

local function showToast(text)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end

local function canPrompt()
	local now = os.clock()
	if now - lastPrompt < 1.5 then
		return false
	end
	lastPrompt = now
	return true
end

local function requestSkip()
	if getStage() >= totalStages() then
		showToast("🏁 Ya estás en la última etapa")
		return
	end
	local id = ReplicatedStorage:GetAttribute("SkipStageProductId")
	if type(id) ~= "number" or id <= 0 then
		showToast("🛒 Tienda no configurada todavía")
		return
	end
	if not canPrompt() then
		return
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, id)
	end)
	if not ok then
		warn("[ShopClient] No se pudo abrir la compra: " .. tostring(err))
	end
end

local function requestVip()
	if player:GetAttribute("IsVIP") == true then
		showToast("⭐ Ya tienes el Pack VIP")
		return
	end
	local id = ReplicatedStorage:GetAttribute("VipGamePassId")
	if type(id) ~= "number" or id <= 0 then
		showToast("🛒 Tienda no configurada todavía")
		return
	end
	if not canPrompt() then
		return
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, id)
	end)
	if not ok then
		warn("[ShopClient] No se pudo abrir la compra: " .. tostring(err))
	end
end

---------------------------------------------------------------- CONEXIONES
toggleBtn.Activated:Connect(function()
	setExpanded(not expanded)
end)
skipBtn.Activated:Connect(requestSkip)
vipBtn.Activated:Connect(requestVip)

-- Teclado (G / V) y mando (X / D-Pad derecha / D-Pad arriba)
local function onAction(actionName, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if actionName == "ShopSkipStage" then
		requestSkip()
	elseif actionName == "ShopVipPack" then
		requestVip()
	elseif actionName == "ShopTogglePanel" then
		setExpanded(not expanded)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("ShopSkipStage", onAction, false, Enum.KeyCode.G, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("ShopVipPack", onAction, false, Enum.KeyCode.V, Enum.KeyCode.DPadRight)
ContextActionService:BindAction("ShopTogglePanel", onAction, false, Enum.KeyCode.DPadUp)

notifyEvent.OnClientEvent:Connect(function(message)
	if type(message) == "string" then
		showToast(message)
	end
	refreshLabels()
end)

player:GetAttributeChangedSignal("IsVIP"):Connect(refreshLabels)
UserInputService.LastInputTypeChanged:Connect(refreshLabels)

task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 30)
	local stage = ls and ls:WaitForChild("Etapa", 10)
	if stage then
		stage:GetPropertyChangedSignal("Value"):Connect(refreshLabels)
		refreshLabels()
	end
end)

---------------------------------------------------------------- BOTÓN DE LINTERNA EXISTENTE (HorrorHUD)
task.spawn(function()
	local hud = playerGui:WaitForChild("HorrorHUD", 30)
	if not hud then
		return
	end
	local flashBtn = hud:FindFirstChildWhichIsA("TextButton")
	local waited = 0
	while not flashBtn and waited < 30 do
		task.wait(0.25)
		waited += 0.25
		flashBtn = hud:FindFirstChildWhichIsA("TextButton")
	end
	if not flashBtn then
		return
	end

	flashBtn.Selectable = true
	flashBtn.Active = true

	if not flashBtn:FindFirstChildOfClass("UISizeConstraint") then
		local c = Instance.new("UISizeConstraint")
		c.MinSize = Vector2.new(120, 46) -- cómodo para el pulgar en iPhone pequeño
		c.MaxSize = Vector2.new(280, 96) -- no se hace gigante en 4K / TV
		c.Parent = flashBtn
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "KeyHint"
	hint.BackgroundTransparency = 1
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.fromScale(0.5, 1)
	hint.Size = UDim2.fromScale(0.6, 0.4)
	hint.TextColor3 = Color3.fromRGB(200, 200, 205)
	hint.Font = Enum.Font.GothamBold
	hint.TextScaled = true
	hint.Text = ""
	hint.Parent = flashBtn
	flashHint = hint
	refreshLabels()
end)

setExpanded(true)
