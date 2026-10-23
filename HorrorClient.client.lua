local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local jumpscareEvent = ReplicatedStorage:WaitForChild("TriggerJumpscare")
local victoryEvent = ReplicatedStorage:WaitForChild("VictoryEvent")
local killersFolder = workspace:WaitForChild("ActiveKillers")
local playerGui = player:WaitForChild("PlayerGui")

-- Imagen del meme que se ríe al caer. Pega un ID real de imagen: "rbxassetid://NUMERO".
-- Si lo dejas vacío se usa un emoji gigante 🤣 (funciona sin ningún recurso externo).
local MEME_IMAGE_ID = ""

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

local memeEmoji = Instance.new("TextLabel")
memeEmoji.AnchorPoint = Vector2.new(0.5, 0.5)
memeEmoji.Position = UDim2.fromScale(0.5, 0.42)
memeEmoji.Size = UDim2.fromScale(0.6, 0.5)
memeEmoji.BackgroundTransparency = 1
memeEmoji.Text = "🤣"
memeEmoji.TextScaled = true
memeEmoji.Visible = false
memeEmoji.ZIndex = 12
memeEmoji.Parent = jumpscareFrame

local memeImage = Instance.new("ImageLabel")
memeImage.AnchorPoint = Vector2.new(0.5, 0.5)
memeImage.Position = UDim2.fromScale(0.5, 0.42)
memeImage.Size = UDim2.fromScale(0.6, 0.6)
memeImage.BackgroundTransparency = 1
memeImage.Image = MEME_IMAGE_ID
memeImage.ScaleType = Enum.ScaleType.Fit
memeImage.Visible = false
memeImage.ZIndex = 12
memeImage.Parent = jumpscareFrame

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
local hasMemeImage = MEME_IMAGE_ID ~= ""

jumpscareEvent.OnClientEvent:Connect(function(killerType)
	scareToken += 1
	local token = scareToken
	local reduced = player:GetAttribute("ReduceScares") == true
	local isMeme = (killerType == "FALL")

	memeEmoji.Visible = isMeme and not hasMemeImage
	memeImage.Visible = isMeme and hasMemeImage
	scareText.Position = isMeme and UDim2.fromScale(0, 0.35) or UDim2.fromScale(0, 0)
	scareText.Size = isMeme and UDim2.fromScale(1, 0.25) or UDim2.fromScale(1, 1)

	if isMeme then
		scareText.Text = "¡JAJAJA, CAÍSTE!"
		scareText.TextColor3 = Color3.fromRGB(90, 40, 0)
	elseif killerType == "BOSS" then
		scareText.Text = "💀 ¡EL JEFE DEVORÓ TU ALMA!"
		scareText.TextColor3 = Color3.fromRGB(200, 0, 0)
	elseif killerType == "GHOST" then
		scareText.Text = "👻 ¡ALMA EN PENA!"
		scareText.TextColor3 = Color3.fromRGB(200, 0, 0)
	else
		scareText.Text = "🔪 ¡NO ESCAPASTE!"
		scareText.TextColor3 = Color3.fromRGB(200, 0, 0)
	end

	jumpscareFrame.Visible = true

	if reduced then
		-- Modo suave: sin parpadeo, fondo oscuro y corto
		jumpscareFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		jumpscareFrame.BackgroundTransparency = 0.35
		task.wait(isMeme and 0.9 or 0.6)
		if token == scareToken then
			jumpscareFrame.Visible = false
			jumpscareFrame.BackgroundTransparency = 0
			memeEmoji.Visible = false
			memeImage.Visible = false
		end
		return
	end

	jumpscareFrame.BackgroundTransparency = 0
	if isMeme then
		-- Meme: fondo amarillo y la cara se sacude ~1.5 s
		for i = 1, 15 do
			if token ~= scareToken then
				return -- otro screamer tomó el control
			end
			jumpscareFrame.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(255, 225, 60) or Color3.fromRGB(255, 160, 40)
			local tilt = (i % 2 == 0) and 9 or -9
			memeEmoji.Rotation = tilt
			memeImage.Rotation = tilt
			task.wait(0.1)
		end
	else
		for i = 1, 6 do
			if token ~= scareToken then
				return
			end
			jumpscareFrame.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(10, 10, 10)
			task.wait(0.06)
		end
	end
	if token == scareToken then
		jumpscareFrame.Visible = false
		memeEmoji.Visible = false
		memeImage.Visible = false
		memeEmoji.Rotation = 0
		memeImage.Rotation = 0
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

---------------------------------------------------------------- AJUSTE: SUSTOS SUAVES
local settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "SettingsHUD"
settingsGui.ResetOnSpawn = false
settingsGui.DisplayOrder = 41
pcall(function()
	settingsGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end)
settingsGui.Parent = playerGui

local softBtn = Instance.new("TextButton")
softBtn.Name = "SoftScaresButton"
softBtn.Size = UDim2.fromScale(0.17, 0.065)
softBtn.Position = UDim2.fromScale(0.015, 0.02)
softBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
softBtn.BackgroundTransparency = 0.15
softBtn.TextColor3 = Color3.fromRGB(235, 235, 240)
softBtn.Font = Enum.Font.GothamBold
softBtn.TextScaled = true
softBtn.Selectable = true
softBtn.Parent = settingsGui

local softCorner = Instance.new("UICorner")
softCorner.CornerRadius = UDim.new(0.2, 0)
softCorner.Parent = softBtn

local softLimit = Instance.new("UISizeConstraint")
softLimit.MinSize = Vector2.new(110, 38)
softLimit.MaxSize = Vector2.new(210, 60)
softLimit.Parent = softBtn

local function refreshSoftButton()
	local reduced = player:GetAttribute("ReduceScares") == true
	softBtn.Text = reduced and "😌 Sustos suaves: SÍ" or "😱 Sustos suaves: NO"
end
refreshSoftButton()
softBtn.Activated:Connect(function()
	player:SetAttribute("ReduceScares", player:GetAttribute("ReduceScares") ~= true)
	refreshSoftButton()
end)

---------------------------------------------------------------- DIAGNÓSTICO (pon DEBUG_OVERLAY = false cuando todo funcione)
local DEBUG_OVERLAY = true
if DEBUG_OVERLAY then
	local dbgGui = Instance.new("ScreenGui")
	dbgGui.Name = "DebugHUD"
	dbgGui.ResetOnSpawn = false
	dbgGui.DisplayOrder = 60
	pcall(function()
		dbgGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	dbgGui.Parent = playerGui

	local dbgLabel = Instance.new("TextLabel")
	dbgLabel.Position = UDim2.fromScale(0.3, 0.02)
	dbgLabel.Size = UDim2.fromScale(0.5, 0.34)
	dbgLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dbgLabel.BackgroundTransparency = 0.35
	dbgLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	dbgLabel.TextXAlignment = Enum.TextXAlignment.Left
	dbgLabel.TextYAlignment = Enum.TextYAlignment.Top
	dbgLabel.TextWrapped = true
	dbgLabel.Font = Enum.Font.Code
	dbgLabel.TextSize = 13
	dbgLabel.Text = "diagnóstico..."
	dbgLabel.Parent = dbgGui

	task.spawn(function()
		while true do
			task.wait(0.5)
			local lines = {}
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local ls = player:FindFirstChild("leaderstats")
			local st = ls and ls:FindFirstChild("Etapa")
			local cpFolder = workspace:FindFirstChild("Checkpoints")
			lines[#lines + 1] = "Etapa (cliente): " .. (st and tostring(st.Value) or "sin datos")
			lines[#lines + 1] = "MapReady: " .. tostring(workspace:GetAttribute("MapReady")) .. "  Streaming: " .. tostring(workspace.StreamingEnabled)
			lines[#lines + 1] = "Checkpoints cargados aquí: " .. (cpFolder and tostring(#cpFolder:GetChildren()) or "sin carpeta")
			if hrp then
				local p = hrp.Position
				lines[#lines + 1] = string.format("Pos: %.0f, %.0f, %.0f  anclado: %s", p.X, p.Y, p.Z, tostring(hrp.Anchored))
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {char}
				local hit = workspace:Raycast(p, Vector3.new(0, -300, 0), params)
				if hit then
					lines[#lines + 1] = string.format("Suelo debajo: %s a %.0f studs", hit.Instance.Name, p.Y - hit.Position.Y)
				else
					lines[#lines + 1] = "Suelo debajo: NINGUNO"
				end
			else
				lines[#lines + 1] = "Personaje: no existe"
			end
			lines[#lines + 1] = "Servidor: " .. tostring(player:GetAttribute("DbgServer"))
			dbgLabel.Text = table.concat(lines, "\n")
		end
	end)
end
