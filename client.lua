local QBCore = exports['qb-core']:GetCoreObject()

PlayerJob = {}
local onDuty = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded') AddEventHandler('QBCore:Client:OnPlayerLoaded', function() QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang end) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate') AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerJob = JobInfo onDuty = PlayerJob.onduty end)
RegisterNetEvent('QBCore:Client:SetDuty') AddEventHandler('QBCore:Client:SetDuty', function(duty) onDuty = duty end)
RegisterNetEvent('QBCore:Client:OnGangUpdate') AddEventHandler('QBCore:Client:OnGangUpdate', function(GangInfo) PlayerGang = GangInfo end)

--Keeps track of duty on script restarts
AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() == resource then QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang onDuty = PlayerJob.onduty end) end end)

Citizen.CreateThread(function()
	local jobroles = {}
	for k, v in pairs(Config.Jobs) do jobroles[tostring(k)] = 0 end
	exports['qb-target']:AddBoxZone("JimBank", vector3(251.75, 222.17, 106.2), 0.6, 2.0, { name="JimBank", heading = 340.0, debugPoly=false, minZ = 105.75, maxZ = 107.29, }, 
		{ options = { { event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Receipts", job = jobroles } }, distance = 2.0 })
end)

RegisterNetEvent('jim-payments:client:Charge', function(data)
	if not onDuty then TriggerEvent("QBCore:Notify", "Not Clocked in!", "error") return end  -- Require to be on duty when making a payment
	local onlineList = {}
	local nearbyList = {}
	QBCore.Functions.TriggerCallback('jim-payments:MakePlayerList', function(cb) onlineList = cb if onlineList[1] == nil then Wait(200) end
		for k, v in pairs(QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(v) then
					if v ~= PlayerId() then
						nearbyList[#nearbyList+1] = { value = onlineList[i].value, text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
					end
				end
			end
			dist = nil
		end
		if data.img == nil then img = "" else img = data.img end
		if nearbyList[#nearbyList] == nil then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
		local dialog = exports['qb-input']:ShowInput({ header = img..PlayerJob.label.." Cash Register", submitText = "Send",
		inputs = {
				{ text = " ", name = "citizen", type = "select", options = nearbyList },
				{ type = 'radio', name = 'billtype', text = 'Payment Type', options = { { value = "cash", text = "Cash" }, { value = "bank", text = "Card" } } }, 
				{ type = 'number', isRequired = true, name = 'price', text = '💵  Amount to Charge' },}
		})
		if dialog then
			if not dialog.citizen or not dialog.price then return end
			TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype, data.img)
		end
	end)
end)

RegisterNetEvent('jim-payments:Tickets:Menu', function()
	local amount = nil
	local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:Ticket:Count', function(cb) p:resolve(cb) end) amount = Citizen.Await(p)
	for k, v in pairs(Config.Jobs) do if k ~= PlayerJob.name then 
		else exports['qb-menu']:openMenu({
			{ isMenuHeader = true, header = "🧾 "..PlayerJob.label.." Receipts 🧾", txt = "Do you want trade your receipts for payment?" },
			{ isMenuHeader = true, header = "", txt = "Amount of Tickets: "..amount.."<br>Total Payment: $"..(Config.Jobs[PlayerJob.name].PayPerTicket * amount) },
			{ header = "✅ Yes", txt = "", params = { event = "jim-payments:Tickets:Sell:yes" } },
			{ header = "❌ No", txt = "", params = { event = "jim-payments:Tickets:Sell:no" } }, })
		end
	end
end)

RegisterNetEvent("jim-payments:client:PayPopup", function(amount, biller, billtype, img, billerjob)
	if img == nil then img = "" end
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = img.."🧾 "..billerjob.." Payment 🧾", txt = "Do you want accept the payment?" },
		{ isMenuHeader = true, header = "", txt = billtype:gsub("^%l", string.upper).." Payment: $"..amount },
		{ header = "✅ Yes", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = true, amount = amount, biller = biller, billtype = billtype } } },
		{ header = "❌ No", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = false, amount = amount, biller = biller, billtype = billtype } } }, })
end)

RegisterNetEvent('jim-payments:Tickets:Sell:yes', function() TriggerServerEvent('jim-payments:Tickets:Sell') end)
RegisterNetEvent('jim-payments:Tickets:Sell:no', function() exports['qb-menu']:closeMenu() end)
