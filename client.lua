local QBCore = exports['qb-core']:GetCoreObject()

PlayerJob = {}
PlayerGang = {}

local onDuty = false
local BankPed = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang end) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerJob = JobInfo onDuty = PlayerJob.onduty end)
RegisterNetEvent('QBCore:Client:SetDuty', function(duty) onDuty = duty end)
RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo) PlayerGang = GangInfo end)

--Keeps track of duty on script restarts
AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	QBCore.Functions.GetPlayerData(function(PlayerData)
		PlayerJob = PlayerData.job
		PlayerGang = PlayerData.gang
		onDuty = PlayerJob.onduty
	end)
end)

local function loadModel(model) if Config.Debug then print("Debug: Loading Model: '"..model.."'") end RequestModel(model) while not HasModelLoaded(model) do Wait(0) end end
local function unloadModel(model) if Config.Debug then print("Debug: Removing Model: '"..model.."'") end SetModelAsNoLongerNeeded(model) end

CreateThread(function()
	local jobroles = {} local gangroles = {}
	--Build Job/Gang Checks for cashin location
	for k, v in pairs(Config.Jobs) do if v.gang then gangroles[tostring(k)] = 0 else jobroles[tostring(k)] = 0 end end
	--Create Target at location
	exports['qb-target']:AddCircleZone("JimBank", vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z), 2.0, { name="JimBank", debugPoly=Config.Debug, useZ=true, },
		{ options = {
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Job Receipts", job = jobroles, },
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = "Cash in Gang Receipts", gang = gangroles, } },
		distance = 2.0 })
	--Crete Ped at the location
	if Config.Peds then
		local i = math.random(1, #Config.PedPool)
		loadModel(Config.PedPool[i])
		if not BankPed then BankPed = CreatePed(0, Config.PedPool[i], vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z-1), Config.CashInLocation[4], false, false) end
		if Config.Debug then print("Ped Created for Ticket Trade") end
	end
end)

RegisterNetEvent('jim-payments:client:Charge', function(data, outside)
	--Check if player is using /cashregister command
	if not outside and not onDuty and data.gang == nil then TriggerEvent("QBCore:Notify", "Not Clocked in!", "error") return end
	local newinputs = {} -- Begin qb-input creation here.
	if Config.List then -- If nearby player list is wanted:
		--Retrieve a list of nearby players from server
		local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:MakePlayerList', function(cb) p:resolve(cb) end)
		local onlineList = Citizen.Await(p)
		local nearbyList = {}
		--Convert list of players nearby into one qb-input understands + add distance info
		for _, v in pairs(QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(v) then
					if v ~= PlayerId() or Config.Debug then
						nearbyList[#nearbyList+1] = { value = onlineList[i].value, text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
					end
				end
			end
		end
		--If list is empty(no one nearby) show error and stop
		if not nearbyList[#nearbyList] then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
		newinputs[#newinputs+1] = { text = " ", name = "citizen", type = "select", options = nearbyList }
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen', text = '# Customer ID #' }
	end
	--Check if image was given when opening the regsiter
	local img = data.img or ""
	--Continue adding payment options to qb-input
	newinputs[#newinputs+1] = { type = 'radio', name = 'billtype', text = 'Payment Type', options = { { value = "cash", text = "Cash" }, { value = "bank", text = "Card" } } }
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = '💵  Amount to Charge' }
	--Grab Player Job name or Gang Name if needed
	local label = PlayerJob.label
	local gang = false
	if data.gang then label = PlayerGang.label gang = true end
	local dialog = exports['qb-input']:ShowInput({ header = img..label.." Cash Register", submitText = "Send", inputs = newinputs})
	if dialog then
		if not dialog.citizen or not dialog.price then return end
		TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype, data.img, outside, gang)
	end
end)

RegisterNetEvent('jim-payments:client:PolCharge', function()
	--Check if player is allowed to use /cashregister command
	local allowed = false
	for k in pairs(Config.FineJobs) do if k == PlayerJob.name then allowed = true end end
	if not allowed then TriggerEvent("QBCore:Notify", "You don't have the required job", "error") return end

	local newinputs = {} -- Begin qb-input creation here.
	if Config.FineJobList then -- If nearby player list is wanted:
		--Retrieve a list of nearby players from server
		local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:MakePlayerList', function(cb) p:resolve(cb) end)
		local onlineList = Citizen.Await(p)
		local nearbyList = {}
		--Convert list of players nearby into one qb-input understands + add distance info
		for _, v in pairs(QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(v) then
					if v ~= PlayerId() or Config.Debug then
						nearbyList[#nearbyList+1] = { value = onlineList[i].value, text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
					end
				end
			end
		end
		--If list is empty(no one nearby) show error and stop
		if not nearbyList[#nearbyList] then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
		newinputs[#newinputs+1] = { text = " ", name = "citizen", type = "select", options = nearbyList }
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen', text = "# Person's ID #" }
	end
	--Continue adding payment options to qb-input
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = '💵  Amount to Charge' }
	--Grab Player Job name or Gang Name if needed
	local label = PlayerJob.label
	local gang = false
	local dialog = exports['qb-input']:ShowInput({ header = label.." Charge", submitText = "Send", inputs = newinputs})
	if dialog then
		if not dialog.citizen or not dialog.price then return end
		TriggerServerEvent('jim-payments:server:PolCharge', dialog.citizen, dialog.price)
	end
end)


RegisterNetEvent('jim-payments:Tickets:Menu', function(data)
	--Get ticket info
	local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:Ticket:Count', function(cb) p:resolve(cb) end)
	local amount = Citizen.Await(p)
	if amount == 0 then TriggerEvent("QBCore:Notify", "You don't have any tickets to trade", "error") return end
	local sellable = false
	local name = "" local label = ""
	--Check/adjust for job/gang names
	for k, v in pairs(Config.Jobs) do
		if data.gang then if v.gang and k == PlayerGang.name then name = k label = PlayerGang.label sellable = true end
		else if not v.gang and k == PlayerJob.name then name = k label = PlayerJob.label sellable = true end
	end
		if sellable then -- if info is found then:
			exports['qb-menu']:openMenu({
				{ isMenuHeader = true, header = "🧾 "..label.." Receipts 🧾", txt = "Do you want trade your receipts for payment?" },
				{ isMenuHeader = true, header = "", txt = "Amount of Tickets: "..amount.."<br>Total Payment: $"..(Config.Jobs[name].PayPerTicket * amount) },
				{ icon = "fas fa-circle-check", header = "Yes", txt = "", params = { event = "jim-payments:Tickets:Sell:yes" } },
				{ icon = "fas fa-circle-xmark", header = "No", txt = "", params = { event = "jim-payments:Tickets:Sell:no" } },
			})
		end
	end
end)

RegisterNetEvent("jim-payments:client:PayPopup", function(amount, biller, billtype, img, billerjob, gang, outside)
	local img = img or ""
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = img.."🧾 "..billerjob.." Payment 🧾", txt = "Do you want accept the payment?" },
		{ isMenuHeader = true, header = "", txt = billtype:gsub("^%l", string.upper).." Payment: $"..amount },
		{ icon = "fas fa-circle-check", header = "Yes", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = true, amount = amount, biller = biller, billtype = billtype, gang = gang, outside = outside } } },
		{ icon = "fas fa-circle-xmark", header = "No", txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = false, amount = amount, biller = biller, billtype = billtype, outside = outside } } }, })
end)

RegisterNetEvent("jim-payments:client:PolPopup", function(amount, biller, billerjob)
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = "🧾 "..billerjob.." Payment 🧾", txt = "Do you want accept the charge?" },
		{ isMenuHeader = true, header = "", txt = "Bank Charge: $"..amount },
		{ icon = "fas fa-circle-check", header = "Yes", txt = "", params = { isServer = true, event = "jim-payments:server:PolPopup", args = { accept = true, amount = amount, biller = biller } } },
		{ icon = "fas fa-circle-xmark", header = "No", txt = "", params = { isServer = true, event = "jim-payments:server:PolPopup", args = { accept = false, amount = amount, biller = biller } } }, })
end)

RegisterNetEvent('jim-payments:Tickets:Sell:yes', function() TriggerServerEvent('jim-payments:Tickets:Sell') end)
RegisterNetEvent('jim-payments:Tickets:Sell:no', function() exports['qb-menu']:closeMenu() end)

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	exports['qb-target']:RemoveZone("JimBank") unloadModel(GetEntityModel(BankPed)) DeletePed(BankPed)
end)