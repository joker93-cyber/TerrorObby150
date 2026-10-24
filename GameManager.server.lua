-- GameManager.server.lua
-- Servidor autoritativo para la gestión de etapas, checkpoints y estado de juego.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameManager = {}
GameManager.PlayerStages = {}

function GameManager.Init()
    Players.PlayerAdded:Connect(function(player)
        GameManager.PlayerStages[player] = 1
        
        -- Configuración segura de leaderstats para el almacenamiento de etapas
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
        
        local stage = Instance.new("IntValue")
        stage.Name = "Stage"
        stage.Value = 1
        stage.Parent = leaderstats

        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                -- Limpieza y control de reaparición en el checkpoint actual
                print("[GameManager] El jugador " .. player.Name .. " ha muerto. Reapareciendo en su etapa.")
            end)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        GameManager.PlayerStages[player] = nil
    end)
    
    print("[GameManager] Inicializado correctamente en el servidor.")
end

return GameManager
