-- HorrorClient.client.lua
-- Ubicación: StarterPlayer.StarterPlayerScripts.HorrorClient
-- Gestiona el HUD persistente sin duplicarse al morir, controles de Linterna [F] y
-- Crucifijo Sagrado [Q], alertas de proximidad de monstruos y modo de accesibilidad.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 20)
local toggleFlashlightEvent = remotesFolder and remotesFolder:WaitForChild("ToggleFlashlight", 20)
local useCrucifixEvent = remotesFolder and remotesFolder:WaitForChild("UseCrucifix", 20)
local clientNotificationEvent = remotesFolder and remotesFolder:WaitForChild("ClientNotification", 20)

local oldHud = playerGui:FindFirstChild("TerrorObbyHUD")
if oldHud then
	oldHud:Destroy()
end

local hudGui = Instance.new("ScreenGui")
hudGui.Name = "TerrorObbyHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.Parent = playerGui

local dangerVignette = Instance.new("Frame")
dangerVignette.Name = "DangerVignette"
dangerVignette.Size = UDim2.fromScale(1, 1)
dangerVignette.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
dangerVignette.BackgroundTransparency = 1
dangerVignette.Active = false
dangerVignette.Parent = hudGui

local topBar = Instance.new("Frame")
topBar.Name = "TopStatsBar"
topBar.Size = UDim2.fromOffset(340, 48)
topBar.Position = UDim2.new(0.5, -170, 0, 14)
topBar.BackgroundColor3 = Color3.fromRGB(18, 15, 22)
topBar.BackgroundTransparency = 0.2
topBar.Parent = hudGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.fromScale(1, 1)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 235, 210)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = 15
statsLabel.Text = "🎃 Etapa: 1/150 | 💰 25 | ✝️ 1"
statsLabel.Parent = topBar

local notifyLabel = Instance.new("TextLabel")
notifyLabel.Size = UDim2.fromOffset(420, 36)
notifyLabel.Position = UDim2.new(0.5, -210, 0, 70)
notifyLabel.BackgroundTransparency = 1
notifyLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
notifyLabel.TextStrokeTransparency = 0.2
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextSize = 16
notifyLabel.Text = ""
notifyLabel.Parent = hudGui

local actionFrame = Instance.new("Frame")
actionFrame.Name = "ActionButtons"
actionFrame.Size = UDim2.fromOffset(150, 175)
actionFrame.Position = UDim2.new(1, -165, 0.5, -80)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = hudGui

local function createActionButton(name, text, posY, bgColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.fromOffset(145, 48)
	btn.Position = UDim2.fromOffset(0, posY)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	btn.Parent = actionFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn
	return btn
end

local flashlightBtn = createActionButton("FlashlightBtn", "🔦 Linterna [F]", 0, Color3.fromRGB(45, 55, 75))
local crucifixBtn = createActionButton("CrucifixBtn", "✝️ Crucifijo [Q]", 56, Color3.fromRGB(130, 30, 35))
local reduceScaresBtn = createActionButton("ScareToggleBtn", "👁️ Sustos: ON", 112, Color3.fromRGB(40, 40, 45))

local reduceScares = false

flashlightBtn.Activated:Connect(function()
	if toggleFlashlightEvent then
		toggleFlashlightEvent:FireServer()
	end
end)

crucifixBtn.Activated:Connect(function()
	if useCrucifixEvent then
		useCrucifixEvent:FireServer()
	end
end)

reduceScaresBtn.Activated:Connect(function()
	reduceScares = not reduceScares
	localPlayer:SetAttribute("ReduceScares", reduceScares)
	reduceScaresBtn.Text = reduceScares and "👁️ Sustos: SUAVES" or "👁️ Sustos: ON"
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY then
		if toggleFlashlightEvent then toggleFlashlightEvent:FireServer() end
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonX then
		if useCrucifixEvent then useCrucifixEvent:FireServer() end
	end
end)

local function updateStatsDisplay()
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	local stage = leaderstats and leaderstats:FindFirstChild("Stage") and leaderstats.Stage.Value or 1
	local coins = leaderstats and leaderstats:FindFirstChild("Coins") and leaderstats.Coins.Value or 0
	local charges = localPlayer:GetAttribute("CrucifixCharges") or 0
	local vipTag = localPlayer:GetAttribute("HasVIP") and " 👑VIP" or ""
	statsLabel.Text = string.format("🎃 Etapa: %d/150 | 💰 %d | ✝️ %d%s", stage, coins, charges, vipTag)
end

task.spawn(function()
	local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
	if leaderstats then
		for _, stat in ipairs(leaderstats:GetChildren()) do
			stat.Changed:Connect(updateStatsDisplay)
		end
	end
	localPlayer:GetAttributeChangedSignal("CrucifixCharges"):Connect(updateStatsDisplay)
	localPlayer:GetAttributeChangedSignal("HasVIP"):Connect(updateStatsDisplay)
	updateStatsDisplay()
end)

if clientNotificationEvent then
	clientNotificationEvent.OnClientEvent:Connect(function(msg)
		notifyLabel.Text = tostring(msg)
		local currentMsg = notifyLabel.Text
		task.delay(4, function()
			if notifyLabel.Text == currentMsg then
				notifyLabel.Text = ""
			end
		end)
	end)
end

RunService.RenderStepped:Connect(function()
	if reduceScares then
		dangerVignette.BackgroundTransparency = 1
		return
	end
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local monstersFolder = Workspace:FindFirstChild("Monsters")
	if not hrp or not monstersFolder then
		dangerVignette.BackgroundTransparency = 1
		return
	end

	local minDistance = 999
	for _, m in ipairs(monstersFolder:GetChildren()) do
		local mRoot = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
		if mRoot then
			local d = (mRoot.Position - hrp.Position).Magnitude
			if d < minDistance then
				minDistance = d
			end
		end
	end

	if minDistance < 40 then
		local intensity = math.clamp(1 - (minDistance / 40), 0, 0.65)
		dangerVignette.BackgroundTransparency = 1 - (intensity * 0.45)
	else
		dangerVignette.BackgroundTransparency = 1
	end
end)
