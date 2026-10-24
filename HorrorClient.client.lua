-- HorrorClient.client.lua
-- Gestión de interfaz y eventos atmosféricos en el cliente, previniendo duplicaciones al reaparecer.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function cleanupExistingUI()
    local existingUI = playerGui:FindFirstChild("TerrorObbyHUD")
    if existingUI then
        existingUI:Destroy()
    end
end

local function initClient()
    cleanupExistingUI()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TerrorObbyHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Creación base del contenedor HUD para dispositivos móviles y PC
    print("[HorrorClient] Interfaz del cliente inicializada sin duplicaciones.")
end

localPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    initClient()
end)

if localPlayer.Character then
    initClient()
end
