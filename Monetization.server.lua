-- Monetization.server.lua
-- Gestión segura en servidor para Game Passes y Developer Products (VIP ID: 2052196520)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local VIP_GAMEPASS_ID = 2052196520

local MonetizationService = {}

function MonetizationService.Init()
    Players.PlayerAdded:Connect(function(player)
        -- Verificación robusta del Pase VIP en el servidor
        local success, hasPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
        end)
        
        if success and hasPass then
            player:SetAttribute("HasVIP", true)
            print("[Monetization] El jugador " .. player.Name .. " posee el Pase VIP activo.")
        else
            player:SetAttribute("HasVIP", false)
        end
    end)

    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local playerId = receiptInfo.PlayerId
        local productId = receiptInfo.ProductId
        local player = Players:GetPlayerByUserId(playerId)
        
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Lógica segura para procesar productos consumibles (monedas, ventajas, etc.)
        print(string.format("[Monetization] Procesando compra del producto %d para %s", productId, player.Name))
        
        -- Aquí se otorgaría la recompensa de manera segura en el servidor
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    print("[Monetization] Servicio de monetización configurado de forma segura.")
end

return MonetizationService
