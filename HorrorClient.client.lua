local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local jumpscareEvent = ReplicatedStorage:WaitForChild("TriggerJumpscare")
local victoryEvent = ReplicatedStorage:WaitForChild("VictoryEvent")
local killersFolder = workspace:WaitForChild("ActiveKillers")
local playerGui = player:WaitForChild("PlayerGui")

local DANGER_RANGE = 45
local SCAN_INTERVAL = 0.1

---------------------------------------------------------------- GUI DE SUPERPOSICIÓN (pantalla completa)
local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "HorrorOverlay"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 50
pcall(function()
	overlayGui.ScreenInsets = Enum.ScreenInsets.None
end)
overlayGui.Parent = playerGui

local dangerOverlay = Instance.new("Frame")
dangerOverlay.Size = UDim2.fromScale(1, 1)
dangerOverlay.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
dangerOverlay.BackgroundTransparency = 1
dangerOverlay.BorderSizePixel = 0
dangerOverlay.Active = false
dangerOverlay.Parent = overlayGui

local jumpscareFrame = Instance.new("Frame")
jumpscareFrame.Size = UDim2.fromScale(1, 1)
jumpscareFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
jumpscareFrame.BorderSizePixel = 0
jumpscareFrame.Visible = false
jumpscareFrame.ZIndex = 10
jumpscareFrame.Parent = overlayGui

local scareText = Instance.new("TextLabel")
scareText.Size = UDim2.fromScale(1, 1)
scareText.BackgroundTransparency = 1
scareText.Text = "¡TE ATRAPÓ!"
scareText.TextColor3 = Color3.fromRGB(200, 0, 0)
scareText.Font = Enum.Font.Creepster
scareText.TextScaled = true
scareText.ZIndex = 11
scareText.Parent = jumpscareFrame

local victoryLabel = Instance.new("TextLabel")
victoryLabel.Size = UDim2.fromScale(0.8, 0.14)
victoryLabel.Position = UDim2.fromScale(0.1, 0.4)
victoryLabel.BackgroundTransparency = 1
victoryLabel.Text = ""
victoryLabel.TextColor3 = Color3.fromRGB(255, 235, 140)
victoryLabel.TextStrokeTransparency = 0
victoryLabel.Font = Enum.Font.GothamBold
victoryLabel.TextScaled = true
victoryLabel.Visible = false
victoryLabel.ZIndex = 5
victoryLabel.Parent = overlayGui

---------------------------------------------------------------- GUI HUD (respeta zonas seguras del iPhone)
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HorrorHUD"
hudGui.ResetOnSpawn = false
hudGui.DisplayOrder = 40
pcall(function()
	hudGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
hudGui.Parent = playerGui

local hiddenStatus = Instance.new("TextLabel")
hiddenStatus.Size = UDim2.fromScale(0.5, 0.07)
hiddenStatus.Position = UDim2.fromScale(0.25, 0.12)
hiddenStatus.BackgroundTransparency = 1
hiddenStatus.Text = "👁️ ESCONDIDO EN ARMARIO (INDETECTABLE)"
hiddenStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
hiddenStatus.TextStrokeTransparency = 0.5
hiddenStatus.Font = Enum.Font.GothamBold
hiddenStatus.TextScaled = true
hiddenStatus.Visible = false
hiddenStatus.Parent = hudGui

local flashlightBtn = Instance.new("TextButton")
flashlightBtn.Size = UDim2.fromScale(0.2, 0.09)
flashlightBtn.Position = UDim2.fromScale(0.78, 0.42)
flashlightBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
flashlightBtn.TextColor3 = Color3.fromRGB(255, 240, 150)
flashlightBtn.Font = Enum.Font.GothamBold
flashlightBtn.TextScaled = true
flashlightBtn.Text = "🔦 OFF: 100%"
flashlightBtn.Parent = hudGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.2, 0)
corner.Parent = flashlightBtn

---------------------------------------------------------------- LINTERNA
local flashlightOn = false
local battery = 100
local spotLight = nil
local lastLabel = ""

local function setFlashlight(on)
	flashlightOn = on
	if spotLight and spotLight.Parent then
		spotLight.Enabled = on
	end
end

local function updateLabel()
	local text = string.format("🔦 %s: %d%%", flashlightOn and "ON" or "OFF", math.floor(battery))
	if text ~= lastLabel then -- solo reescribe el texto cuando cambia
		lastLabel = text
		flashlightBtn.Text = text
	end
end

local function toggleFlashlight()
	if player:GetAttribute("IsHidden") == true then
		return
	end
	if flashlightOn then
		setFlashlight(false)
	elseif battery > 5 then
		setFlashlight(true)
	end
end

local function attachLightToCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		return
	end
	if spotLight then
		spotLight:Destroy()
		spotLight = nil
	end
	local light = Instance.new("SpotLight")
	light.Brightness = 3.5
	light.Range = 45
	light.Angle = 55
	light.Shadows = false
	light.Enabled = flashlightOn
	light.Parent = hrp
	spotLight = light
end

player.CharacterAdded:Connect(attachLightToCharacter)
if player.Character then
	task.spawn(attachLightToCharacter, player.Character)
end

flashlightBtn.Activated:Connect(toggleFlashlight)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY) then
		toggleFlashlight()
	end
end)

---------------------------------------------------------------- ESTADO ESCONDIDO
local function refreshHidden()
	local hidden = player:GetAttribute("IsHidden") == true
	hiddenStatus.Visible = hidden
	if hidden then
		setFlashlight(false)
	end
end
player:GetAttributeChangedSignal("IsHidden"):Connect(refreshHidden)
refreshHidden()

---------------------------------------------------------------- DETECCIÓN DE PELIGRO (escaneo con límite de frecuencia)
local nearestKiller = math.huge
local scanTimer = 0

local function scanKillers()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		nearestKiller = math.huge
		return
	end
	local best = math.huge
	for _, killer in ipairs(killersFolder:GetChildren()) do
		local root = killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (root.Position - hrp.Position).Magnitude
			if d < best then
				best = d
			end
		end
	end
	nearestKiller = best
end

RunService.Heartbeat:Connect(function(dt)
	-- Batería
	if flashlightOn then
		battery = math.max(0, battery - (dt * 4))
		if battery <= 0 then
			setFlashlight(false)
		end
	elseif battery < 100 then
		battery = math.min(100, battery + (dt * 2.5))
	end
	updateLabel()

	-- Escaneo de entidades cercanas (10 veces por segundo)
	scanTimer += dt
	if scanTimer >= SCAN_INTERVAL then
		scanTimer = 0
		scanKillers()
	end

	-- Overlay de peligro
	if nearestKiller < DANGER_RANGE and player:GetAttribute("IsHidden") ~= true then
		local pulse = math.abs(math.sin(os.clock() * 8)) * 0.35
		local intensity = (1 - (nearestKiller / DANGER_RANGE)) * 0.65
		dangerOverlay.BackgroundTransparency = math.clamp(1 - (intensity + pulse), 0.25, 1)
	elseif dangerOverlay.BackgroundTransparency ~= 1 then
		dangerOverlay.BackgroundTransparency = 1
	end
end)

---------------------------------------------------------------- JUMPSCARE Y VICTORIA
local scareToken = 0
jumpscareEvent.OnClientEvent:Connect(function(killerType)
	scareToken += 1
	local token = scareToken

	if killerType == "BOSS" then
		scareText.Text = "💀 ¡EL JEFE DEVORÓ TU ALMA!"
	elseif killerType == "GHOST" then
		scareText.Text = "👻 ¡ALMA EN PENA!"
	else
		scareText.Text = "🔪 ¡NO ESCAPASTE!"
	end

	jumpscareFrame.Visible = true
	for i = 1, 6 do
		if token ~= scareToken then
			return -- otro jumpscare tomó el control
		end
		jumpscareFrame.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(10, 10, 10)
		task.wait(0.06)
	end
	if token == scareToken then
		jumpscareFrame.Visible = false
	end
end)

local victoryToken = 0
victoryEvent.OnClientEvent:Connect(function(totalWins)
	victoryToken += 1
	local token = victoryToken
	victoryLabel.Text = "🏆 ¡ESCAPASTE! Victorias: " .. tostring(totalWins)
	victoryLabel.Visible = true
	task.delay(5, function()
		if token == victoryToken then
			victoryLabel.Visible = false
		end
	end)
end)
