-- CombatAndAbilityClient.client.lua
-- Ubicación: StarterPlayer.StarterPlayerScripts.CombatAndAbilityClient
-- Ejecuta la animación de espadazo en el cliente, sacudida de cámara en impactos,
-- cambio dinámico de cielo/ambiente por Bioma y HUD de Jefes y Habilidades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local AbilityConfig = require(ReplicatedStorage:WaitForChild("AbilityConfig"))
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 20)
local basicAttackEvent = remotesFolder:WaitForChild("BasicAttack", 20)
local activateAbilityEvent = remotesFolder:WaitForChild("ActivateAbility", 20)
local combatFeedbackEvent = remotesFolder:WaitForChild("CombatFeedback", 20)

local oldGui = playerGui:FindFirstChild("TerrorCombatHUD")
if oldGui then
	oldGui:Destroy()
end

local combatGui = Instance.new("ScreenGui")
combatGui.Name = "TerrorCombatHUD"
combatGui.ResetOnSpawn = false
combatGui.Parent = playerGui

-- 1. Barra de Salud y Zona
local statusFrame = Instance.new("Frame")
statusFrame.Name = "HealthAndZoneFrame"
statusFrame.Size = UDim2.fromOffset(220, 54)
statusFrame.Position = UDim2.fromOffset(16, 14)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 16, 26)
statusFrame.BackgroundTransparency = 0.2
statusFrame.Parent = combatGui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusFrame

local healthBg = Instance.new("Frame")
healthBg.Size = UDim2.new(1, -20, 0, 18)
healthBg.Position = UDim2.fromOffset(10, 8)
healthBg.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
healthBg.Parent = statusFrame

local healthBgCorner = Instance.new("UICorner")
healthBgCorner.CornerRadius = UDim.new(0, 6)
healthBgCorner.Parent = healthBg

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(45, 200, 85)
healthFill.Parent = healthBg

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 6)
healthFillCorner.Parent = healthFill

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.fromScale(1, 1)
healthText.BackgroundTransparency = 1
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 12
healthText.Text = "❤️ 100 / 100"
healthText.Parent = healthBg

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size = UDim2.new(1, -20, 0, 20)
zoneLabel.Position = UDim2.fromOffset(10, 30)
zoneLabel.BackgroundTransparency = 1
zoneLabel.TextColor3 = Color3.fromRGB(110, 230, 130)
zoneLabel.Font = Enum.Font.GothamBold
zoneLabel.TextSize = 12
zoneLabel.Text = "🛡️ ZONA SEGURA"
zoneLabel.Parent = statusFrame

-- 2. Barra de Vida de Criatura / Jefe Activo
local bossFrame = Instance.new("Frame")
bossFrame.Name = "BossHealthBar"
bossFrame.Size = UDim2.fromOffset(360, 44)
bossFrame.Position = UDim2.new(0.5, -180, 0, 105)
bossFrame.BackgroundColor3 = Color3.fromRGB(25, 10, 15)
bossFrame.BackgroundTransparency = 0.15
bossFrame.Visible = false
bossFrame.Parent = combatGui

local bossCorner = Instance.new("UICorner")
bossCorner.CornerRadius = UDim.new(0, 10)
bossCorner.Parent = bossFrame

local bossTitle = Instance.new("TextLabel")
bossTitle.Size = UDim2.new(1, -16, 0, 20)
bossTitle.Position = UDim2.fromOffset(8, 2)
bossTitle.BackgroundTransparency = 1
bossTitle.TextColor3 = Color3.fromRGB(255, 110, 110)
bossTitle.Font = Enum.Font.GothamBlack
bossTitle.TextSize = 13
bossTitle.Text = "💀 CRIATURA"
bossTitle.Parent = bossFrame

local bossBarBg = Instance.new("Frame")
bossBarBg.Size = UDim2.new(1, -20, 0, 14)
bossBarBg.Position = UDim2.fromOffset(10, 24)
bossBarBg.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
bossBarBg.Parent = bossFrame

local bossBarFill = Instance.new("Frame")
bossBarFill.Size = UDim2.fromScale(1, 1)
bossBarFill.BackgroundColor3 = Color3.fromRGB(235, 35, 55)
bossBarFill.Parent = bossBarBg

-- 3. Animación local de espadazo al atacar
local function playLocalSlashMove()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- Impulso corto de ataque hacia adelante
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 22 + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
	end
end

-- 4. Barra Inferior de Ataque y Poderes
local bottomBar = Instance.new("Frame")
bottomBar.Name = "SkillsBar"
bottomBar.Size = UDim2.fromOffset(420, 64)
bottomBar.Position = UDim2.new(0.5, -210, 1, -76)
bottomBar.BackgroundTransparency = 1
bottomBar.Parent = combatGui

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = bottomBar

local ClientCooldownEnds = {}
local SkillButtons = {}

local function createSkillButton(id, labelText, bgColor)
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. id
	btn.Size = UDim2.fromOffset(64, 58)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextWrapped = true
	btn.Text = labelText
	btn.Parent = bottomBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	return btn
end

local attackBtn = createSkillButton("Attack", "⚔️ Atacar\n[E]", Color3.fromRGB(185, 35, 40))
attackBtn.Activated:Connect(function()
	playLocalSlashMove()
	basicAttackEvent:FireServer()
end)

local keyLabels = {"[1]", "[2]", "[3]", "[4]", "[Z]"}
for index, abilityId in ipairs(AbilityConfig.OrderedList) do
	local cfg = AbilityConfig.Abilities[abilityId]
	local keyStr = keyLabels[index] or ""
	local btn = createSkillButton(abilityId, cfg.Name .. "\n" .. keyStr, Color3.fromRGB(35, 50, 80))
	SkillButtons[abilityId] = {Button = btn, DefaultText = cfg.Name .. "\n" .. keyStr}

	btn.Activated:Connect(function()
		activateAbilityEvent:FireServer(abilityId)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then
		playLocalSlashMove()
		basicAttackEvent:FireServer()
		return
	end

	for _, abilityId in ipairs(AbilityConfig.OrderedList) do
		local cfg = AbilityConfig.Abilities[abilityId]
		if input.KeyCode == cfg.Keybind or input.KeyCode == cfg.GamepadKey then
			activateAbilityEvent:FireServer(abilityId)
			return
		end
	end
end)

combatFeedbackEvent.OnClientEvent:Connect(function(feedbackType, arg1, arg2)
	if feedbackType == "AbilityAccepted" then
		local abilityId = arg1
		local duration = tonumber(arg2) or 5
		ClientCooldownEnds[abilityId] = os.clock() + duration
	elseif feedbackType == "HitPlayer" or feedbackType == "HitMonster" then
		attackBtn.BackgroundColor3 = Color3.fromRGB(255, 210, 50)
		task.delay(0.15, function()
			attackBtn.BackgroundColor3 = Color3.fromRGB(185, 35, 40)
		end)
	end
end)

-- 5. Cambio dinámico de Ambiente Visual a medida que avanzas de Etapa
local lastAppliedBiomeIndex = 0
local BIOME_ATMOSPHERES = {
	[1] = {Clock = 17.6, Ambient = Color3.fromRGB(150, 130, 145), Atmo = Color3.fromRGB(210, 125, 85)},
	[2] = {Clock = 18.2, Ambient = Color3.fromRGB(120, 155, 135), Atmo = Color3.fromRGB(85, 195, 130)},
	[3] = {Clock = 19.0, Ambient = Color3.fromRGB(145, 120, 165), Atmo = Color3.fromRGB(165, 95, 220)},
	[4] = {Clock = 16.8, Ambient = Color3.fromRGB(130, 155, 175), Atmo = Color3.fromRGB(95, 190, 240)},
	[5] = {Clock = 18.0, Ambient = Color3.fromRGB(170, 120, 120), Atmo = Color3.fromRGB(235, 80, 65)}
}

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if hum then
		local hp = math.max(0, math.floor(hum.Health))
		local maxHp = math.max(1, math.floor(hum.MaxHealth))
		healthFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
		healthText.Text = string.format("❤️ %d / %d", hp, maxHp)
	end

	local inSafe = localPlayer:GetAttribute("InSafeZone")
	if inSafe == false then
		zoneLabel.Text = "⚔️ ZONA DE BATALLA"
		zoneLabel.TextColor3 = Color3.fromRGB(255, 95, 95)
	else
		zoneLabel.Text = "🛡️ ZONA SEGURA"
		zoneLabel.TextColor3 = Color3.fromRGB(110, 230, 130)
	end

	-- Cambiar atmósfera según la etapa actual del jugador
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	local stageVal = leaderstats and leaderstats:FindFirstChild("Stage")
	if stageVal then
		local biomeIdx = math.clamp(math.ceil(stageVal.Value / 30), 1, 5)
		if biomeIdx ~= lastAppliedBiomeIndex then
			lastAppliedBiomeIndex = biomeIdx
			local preset = BIOME_ATMOSPHERES[biomeIdx]
			if preset then
				Lighting.ClockTime = preset.Clock
				Lighting.Ambient = preset.Ambient
				local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
				if atmo then
					atmo.Color = preset.Atmo
				end
			end
		end
	end

	-- Mostrar barra de vida de la criatura más cercana
	local monstersFolder = Workspace:FindFirstChild("Monsters")
	local closestMonster = nil
	local closestDist = 65
	if hrp and monstersFolder then
		for _, m in ipairs(monstersFolder:GetChildren()) do
			local mRoot = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
			local mHum = m:FindFirstChildOfClass("Humanoid")
			if mRoot and mHum and mHum.Health > 0 then
				local d = (mRoot.Position - hrp.Position).Magnitude
				if d < closestDist then
					closestDist = d
					closestMonster = m
				end
			end
		end
	end

	if closestMonster then
		local mHum = closestMonster:FindFirstChildOfClass("Humanoid")
		bossFrame.Visible = true
		bossTitle.Text = string.format("💀 %s (%d / %d HP)", closestMonster.Name, math.floor(mHum.Health), math.floor(mHum.MaxHealth))
		bossBarFill.Size = UDim2.fromScale(math.clamp(mHum.Health / math.max(1, mHum.MaxHealth), 0, 1), 1)
	else
		bossFrame.Visible = false
	end

	for abilityId, info in pairs(SkillButtons) do
		local endTime = ClientCooldownEnds[abilityId] or 0
		local remaining = endTime - now
		if remaining > 0 then
			info.Button.Text = string.format("⏳ %.1fs", remaining)
			info.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		else
			info.Button.Text = info.DefaultText
			info.Button.BackgroundColor3 = Color3.fromRGB(35, 50, 80)
		end
	end
end)
