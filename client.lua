local QBCore = exports['qb-core']:GetCoreObject()

PlayerJob = {}
local onDuty = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = PlayerJob.onduty
end)

RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

--Keeps track of duty on script restarts
AddEventHandler('onResourceStart', function(resource) 
if GetCurrentResourceName() == resource then QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job onDuty = PlayerJob.onduty end) end end)

Citizen.CreateThread(function()
	local jobroles = {}
	for k, v in pairs(Config.Jobs) do jobroles[tostring(k)] = 0 end
	exports['qb-target']:AddBoxZone("JimBank", vector3(251.75, 222.17, 106.2), 0.6, 2.0, { name="JimBank", heading = 340.0, debugPoly=false, minZ = 105.75, maxZ = 107.29, }, 
		{ options = { { event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Receipts", job = jobroles } },
		  distance = 2.0
	})
end)

RegisterNetEvent('jim-payments:client:Charge', function()
	if not onDuty then TriggerEvent("QBCore:Notify", "Not Clocked in!", "error") return end  -- Require to be on duty when making a payment
    QBCore.Functions.TriggerCallback('jim-payments:server:GetCurrentPlayers', function(playerList)
	if playerList[1] == nil then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
		local dialog = exports['qb-input']:ShowInput({ header = "Charge Customer", submitText = "Send",
		inputs = {
				{ text = "Citizen",	name = "citizen", type = "select", options = playerList	},				
				{ type = 'number', isRequired = true, name = 'price', text = 'Amount to Charge' },
				{ type = 'radio', name = 'billtype', text = 'Payment Type', options = {	{ value = "cash", text = "Cash" }, { value = "card", text = "Card" } } }, }
		})
		if dialog then
			if not dialog.citizen or not dialog.price then return end
			TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype)
		end
	end)
end)

RegisterNetEvent('jim-payments:Tickets:Menu', function()
	for k, v in pairs(Config.Jobs) do if k ~= PlayerJob.name then 
		else exports['qb-menu']:openMenu({
				{ isMenuHeader = true, header = PlayerJob.label.." Ticket Payment", txt = "Do you want trade your tickets for payment?" },
				{ header = "Yes", txt = "", params = { event = "jim-payments:Tickets:Sell:yes" } },
				{ header = "No", txt = "", params = { event = "jim-payments:Tickets:Sell:no" } }, })
		end
	end
end)

RegisterNetEvent('jim-payments:Tickets:Sell:yes', function() TriggerServerEvent('jim-payments:Tickets:Sell') end)
RegisterNetEvent('jim-payments:Tickets:Sell:no', function()	exports['qb-menu']:closeMenu() end)
