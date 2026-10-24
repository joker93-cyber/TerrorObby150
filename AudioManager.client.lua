-- AudioManager.client.lua
-- Ubicación en Roblox: StarterPlayer.StarterPlayerScripts.AudioManager
-- Administra la atmósfera sonora, tensión de persecución y control de silencio
-- con compatibilidad total en dispositivos móviles (iPhone/Android) y PC.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local isMuted = false

local audioFolder = SoundService:FindFirstChild("TerrorObbyAudio")
if not audioFolder then
	audioFolder = Instance.new("Folder")
	audioFolder.Name = "TerrorObbyAudio"
	audioFolder.Parent = SoundService
end

-- Sonido rítmico de tensión cuando un monstruo persigue al jugador
local heartbeatSound = audioFolder:FindFirstChild("ChaseTension") or Instance.new("Sound")
heartbeatSound.Name = "ChaseTension"
heartbeatSound.SoundId = "rbxassetid://9114221580"
heartbeatSound.Looped = true
heartbeatSound.Volume = 0
heartbeatSound.Parent = audioFolder

pcall(function()
	if not heartbeatSound.IsPlaying then
		heartbeatSound:Play()
	end
end)

-- Bucle ligero (cada 0.2s) para ajustar volumen de persecución según distancia al monstruo
task.spawn(function()
	while true do
		task.wait(0.2)
		if isMuted or localPlayer:GetAttribute("ReduceScares") then
			heartbeatSound.Volume = 0
		else
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local monstersFolder = Workspace:FindFirstChild("Monsters")
			local closest = 999

			if hrp and monstersFolder then
				for _, m in ipairs(monstersFolder:GetChildren()) do
					if m.PrimaryPart then
						local d = (m.PrimaryPart.Position - hrp.Position).Magnitude
						if d < closest then
							closest = d
						end
					end
				end
			end

			if closest < 45 then
				heartbeatSound.Volume = math.clamp((45 - closest) / 45, 0.05, 0.6)
			else
				heartbeatSound.Volume = 0
			end
		end
	end
end)
