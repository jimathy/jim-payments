local QBCore = exports['qb-core']:GetCoreObject()

PlayerJob = {}
local onDuty = false
local BankPed = {}
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang end) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerJob = JobInfo onDuty = PlayerJob.onduty end)
RegisterNetEvent('QBCore:Client:SetDuty', function(duty) onDuty = duty end)
RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo) PlayerGang = GangInfo end)

--Keeps track of duty on script restarts
AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang onDuty = PlayerJob.onduty end)
end)

CreateThread(function()
	local jobroles = {}
	local gangroles = {}
	for k, v in pairs(Config.Jobs) do if v.gang then gangroles[tostring(k)] = 0 else jobroles[tostring(k)] = 0 end end
	exports['qb-target']:AddCircleZone("JimBank", vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z), 2.0, { name="JimBank", debugPoly=Config.Debug, useZ=true, }, 
		{ options = { 
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Job Receipts", job = jobroles, },
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Gang Receipts", gang = gangroles, } }, 
		distance = 2.0 })
	if Config.Peds then
		local i = math.random(1, #Config.PedPool)
		RequestModel(Config.PedPool[i]) while not HasModelLoaded(Config.PedPool[i]) do Wait(0) end
		if not BankPed[1] then BankPed[1] = CreatePed(0, Config.PedPool[i], vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z-1), Config.CashInLocation[4], false, false) end
		if Config.Debug then print("Ped Created for Ticket Trade") end
	end
end)

RegisterNetEvent('jim-payments:client:Charge', function(data, outside)
	if outside == nil then outside = false end
	if not outside and not onDuty and data.gang == nil then TriggerEvent("QBCore:Notify", "Not Clocked in!", "error") return end  -- Require to be on duty when making a payment
	local onlineList = {}
	local nearbyList = {}
	local p = promise.new()
	QBCore.Functions.TriggerCallback('jim-payments:MakePlayerList', function(cb) p:resolve(cb) end) 
	onlineList = Citizen.Await(p)
	for k, v in pairs(QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.PaymentRadius)) do
		local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
		for i = 1, #onlineList do
			if onlineList[i].value == GetPlayerServerId(v) then
				if v ~= PlayerId() or Config.Debug then
					nearbyList[#nearbyList+1] = { value = onlineList[i].value, text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
				end
			end
		end
		dist = nil
	end
	if not data.img then img = "" else img = data.img end
	if nearbyList[#nearbyList] == nil then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
	local newinputs = {}
	if Config.List then newinputs[#newinputs+1] = { text = " ", name = "citizen", type = "select", options = nearbyList } end
	if not Config.List then newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen', text = '# Customer ID #' } end
	newinputs[#newinputs+1] = { type = 'radio', name = 'billtype', text = 'Payment Type', options = { { value = "cash", text = "Cash" }, { value = "bank", text = "Card" } } }
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = '💵  Amount to Charge' }
	if data.job then label = PlayerJob.label gang = false elseif data.gang then label = PlayerGang.label gang = true end
	local dialog = exports['qb-input']:ShowInput({ header = img..label.." Cash Register", submitText = "Send", inputs = newinputs})
	if dialog then
		if not dialog.citizen or not dialog.price then return end
		TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype, data.img, outside, gang)
	end
end)

RegisterNetEvent('jim-payments:Tickets:Menu', function(data)
	local amount = 0
	local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:Ticket:Count', function(cb) p:resolve(cb) end) amount = Citizen.Await(p)
	if amount == 0 or amount == nil then TriggerEvent("QBCore:Notify", "You don't have any tickets to trade", "error") return end
	local sellable = false
	local name = "" local label = ""
	for k, v in pairs(Config.Jobs) do
		if data.gang then
			if v.gang and k == PlayerGang.name then
				name = k
				label = PlayerGang.label
				sellable = true
			end
		else
			if not v.gang and k == PlayerJob.name then
				name = k
				label = PlayerJob.label
				sellable = true
			end
		end
		if sellable then
			exports['qb-menu']:openMenu({
				{ isMenuHeader = true, header = "🧾 "..label.." Receipts 🧾", txt = "Do you want trade your receipts for payment?" },
				{ isMenuHeader = true, header = "", txt = "Amount of Tickets: "..amount.."<br>Total Payment: $"..(Config.Jobs[name].PayPerTicket * amount) },
				{ icon = "fas fa-circle-check", header = "Yes", txt = "", params = { event = "jim-payments:Tickets:Sell:yes" } },
			{ icon = "fas fa-circle-xmark", header = "No", txt = "", params = { event = "jim-payments:Tickets:Sell:no" } }, })
		end
	end
end)

RegisterNetEvent("jim-payments:client:PayPopup", function(amount, biller, billtype, img, billerjob, gang)
	if not img then img = "" end
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = img.."🧾 "..billerjob.." Payment 🧾", txt = "Do you want accept the payment?" },
		{ isMenuHeader = true, header = "", txt = billtype:gsub("^%l", string.upper).." Payment: $"..amount },
		{ icon = "fas fa-circle-check", header = "Yes", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = true, amount = amount, biller = biller, billtype = billtype, gang = gang } } },
		{ icon = "fas fa-circle-xmark", header = "No", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = false, amount = amount, biller = biller, billtype = billtype } } }, })
end)

RegisterNetEvent('jim-payments:Tickets:Sell:yes', function() TriggerServerEvent('jim-payments:Tickets:Sell') end)
RegisterNetEvent('jim-payments:Tickets:Sell:no', function() exports['qb-menu']:closeMenu() end)

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	exports['qb-target']:RemoveZone("JimBank") DeletePed(BankPed[1])
end)