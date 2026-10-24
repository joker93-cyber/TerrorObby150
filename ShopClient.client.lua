-- ShopClient.client.lua
-- Interfaz de la tienda y llamadas seguras para la compra de Game Passes y mejoras.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local VIP_GAMEPASS_ID = 2052196520

local ShopClient = {}

function ShopClient.PromptVIP()
    pcall(function()
        MarketplaceService:PromptGamePassPurchase(localPlayer, VIP_GAMEPASS_ID)
    end)
end

print("[ShopClient] Módulo de tienda del cliente cargado.")

return ShopClient
