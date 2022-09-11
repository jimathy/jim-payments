local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('QBCore:Client:UpdateObject', function() QBCore = exports['qb-core']:GetCoreObject() end)

PlayerJob = {}
PlayerGang = {}

local onDuty = false
local BankPed = nil
local Targets = {}
local Till = {}

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

CreateThread(function()
	local jobroles = {} local gangroles = {}
	--Build Job/Gang Checks for cashin location
	for k, v in pairs(Config.Jobs) do if v.gang then gangroles[tostring(k)] = 0 else jobroles[tostring(k)] = 0 end end
	--Create Target at location
	Targets["JimBank"] =
	exports['qb-target']:AddCircleZone("JimBank", vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z), 2.0, { name="JimBank", debugPoly=Config.Debug, useZ=true, },
		{ options = {
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = Loc[Config.Lan].target["cashin_boss"], job = jobroles, },
			{ event = "jim-payments:Tickets:Menu", icon = "fas fa-receipt", label = Loc[Config.Lan].target["cashin_gang"], gang = gangroles, } },
		distance = 2.0 })
	--Crete Ped at the location
	if Config.Peds then
		if not Config.Gabz then CreateModelHide(vector3(Config.CashInLocation.x, Config.CashInLocation.y, Config.CashInLocation.z), 1.0, `v_corp_bk_chair3`, true) end
		BankPed = makePed(Config.PedPool[math.random(1, #Config.PedPool)], Config.CashInLocation, false, false)
	end

	--Spawn Custom Cash Register Targets
	for k, v in pairs(Config.CustomCashRegisters) do
		for i = 1, #v do
			local job = k
			local gang = nil
			if v[i].gang then job = nil gang = k end
			Targets["CustomRegister: "..k..i] =
			exports['qb-target']:AddBoxZone("CustomRegister: "..k..i, v[i].coords.xyz, 0.47, 0.34, { name="CustomRegister: "..k..i, heading = v[i].coords[4], debugPoly=Config.Debug, minZ=v[i].coords.z-0.1, maxZ=v[i].coords.z+0.4 },
				{ options = { { event = "jim-payments:client:Charge", icon = "fas fa-credit-card", label = Loc[Config.Lan].target["charge"], job = job, gang = gang, img = "" }, },
					distance = 2.0 })
			if v[i].prop then
				Till[#Till+1] = makeProp({prop = `prop_till_03`, coords = v[i].coords}, 1, false)
			end
		end
	end
end)

RegisterNetEvent('jim-payments:client:Charge', function(data, outside)
	--Check if player is using /cashregister command
	if not outside and not onDuty and data.gang == nil then triggerNotify(nil, Loc[Config.Lan].error["not_onduty"], "error") return end
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
		if not nearbyList[1] then triggerNotify(nil, Loc[Config.Lan].error["no_one"], "error") return end
		newinputs[#newinputs+1] = { text = " ", name = "citizen", type = "select", options = nearbyList }
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen', text = Loc[Config.Lan].menu["cus_id"] }
	end
	--Check if image was given when opening the regsiter
	local img = data.img or ""
	--Continue adding payment options to qb-input
	newinputs[#newinputs+1] = { type = 'radio', name = 'billtype', text = Loc[Config.Lan].menu["type"], options = { { value = "cash", text = Loc[Config.Lan].menu["cash"] }, { value = "bank", text = Loc[Config.Lan].menu["card"] } } }
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = Loc[Config.Lan].menu["amount_charge"] }
	--Grab Player Job name or Gang Name if needed
	local label = PlayerJob.label
	local gang = false
	if data.gang then label = PlayerGang.label gang = true end
	local dialog = exports['qb-input']:ShowInput({ header = img..label..Loc[Config.Lan].menu["cash_reg"], submitText = Loc[Config.Lan].menu["send"], inputs = newinputs})
	if dialog then
		if not dialog.citizen or not dialog.price then return end
		TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype, data.img, outside, gang)
	end
end)

RegisterNetEvent('jim-payments:client:PolCharge', function()
	--Check if player is allowed to use /cashregister command
	local allowed = false
	for k in pairs(Config.FineJobs) do if k == PlayerJob.name then allowed = true end end
	if not allowed then triggerNotify(nil, Loc[Config.Lan].error["no_job"], "error") return end

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
		if not nearbyList[1] then triggerNotify(nil, Loc[Config.Lan].error["no_one"], "error") return end
		newinputs[#newinputs+1] = { text = " ", name = "citizen", type = "select", options = nearbyList }
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen', text = Loc[Config.Lan].menu["person_id"] }
	end
	--Continue adding payment options to qb-input
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = Loc[Config.Lan].menu["amount_charge"] }
	--Grab Player Job name or Gang Name if needed
	local label = PlayerJob.label
	local gang = false
	local dialog = exports['qb-input']:ShowInput({ header = label..Loc[Config.Lan].menu["charge"], submitText = Loc[Config.Lan].menu["send"], inputs = newinputs})
	if dialog then
		if not dialog.citizen or not dialog.price then return end
		TriggerServerEvent('jim-payments:server:PolCharge', dialog.citizen, dialog.price)
	end
end)

RegisterNetEvent('jim-payments:Tickets:Menu', function(data)
	--Get ticket info
	local p = promise.new() QBCore.Functions.TriggerCallback('jim-payments:Ticket:Count', function(cb) p:resolve(cb) end)
	local amount = Citizen.Await(p)
	if not amount then triggerNotify(nil, Loc[Config.Lan].error["no_ticket"], "error") amount = 0 return else amount = amount.amount end
	local sellable = false
	local name = "" local label = ""
	--Check/adjust for job/gang names
	for k, v in pairs(Config.Jobs) do
		if data.gang then if v.gang and k == PlayerGang.name then name = k label = PlayerGang.label sellable = true end
		else if not v.gang and k == PlayerJob.name then name = k label = PlayerJob.label sellable = true end
	end
		if sellable then -- if info is found then:
			exports['qb-menu']:openMenu({
				{ isMenuHeader = true, header = "🧾 "..label..Loc[Config.Lan].menu["receipt"], txt = Loc[Config.Lan].menu["trade_confirm"] },
				{ isMenuHeader = true, header = "", txt = Loc[Config.Lan].menu["ticket_amount"]..amount..Loc[Config.Lan].menu["total_pay"]..(Config.Jobs[name].PayPerTicket * amount) },
				{ icon = "fas fa-circle-check", header = Loc[Config.Lan].menu["yes"], txt = "", params = { event = "jim-payments:Tickets:Sell:yes" } },
				{ icon = "fas fa-circle-xmark", header = Loc[Config.Lan].menu["no"], txt = "", params = { event = "jim-payments:Tickets:Sell:no" } },
			})
		end
	end
end)

RegisterNetEvent("jim-payments:client:PayPopup", function(amount, biller, billtype, img, billerjob, gang, outside)
	local img = img or ""
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = img.."🧾 "..billerjob..Loc[Config.Lan].menu["payment"], txt = Loc[Config.Lan].menu["accept_payment"] },
		{ isMenuHeader = true, header = "", txt = billtype:gsub("^%l", string.upper)..Loc[Config.Lan].menu["payment_amount"]..amount },
		{ icon = "fas fa-circle-check", header = Loc[Config.Lan].menu["yes"], txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = true, amount = amount, biller = biller, billtype = billtype, gang = gang, outside = outside } } },
		{ icon = "fas fa-circle-xmark", header = Loc[Config.Lan].menu["no"], txt = "", params = { isServer = true, event = "jim-payments:server:PayPopup", args = { accept = false, amount = amount, biller = biller, billtype = billtype, outside = outside } } }, })
end)

RegisterNetEvent("jim-payments:client:PolPopup", function(amount, biller, billerjob)
	exports['qb-menu']:openMenu({
		{ isMenuHeader = true, header = "🧾 "..billerjob..Loc[Config.Lan].menu["payment"], txt = Loc[Config.Lan].menu["accept_charge"] },
		{ isMenuHeader = true, header = "", txt = Loc[Config.Lan].menu["bank_charge"]..amount },
		{ icon = "fas fa-circle-check", header = Loc[Config.Lan].menu["yes"], txt = "", params = { isServer = true, event = "jim-payments:server:PolPopup", args = { accept = true, amount = amount, biller = biller } } },
		{ icon = "fas fa-circle-xmark", header = Loc[Config.Lan].menu["no"], txt = "", params = { isServer = true, event = "jim-payments:server:PolPopup", args = { accept = false, amount = amount, biller = biller } } }, })
end)

RegisterNetEvent('jim-payments:Tickets:Sell:yes', function() TriggerServerEvent('jim-payments:Tickets:Sell') end)
RegisterNetEvent('jim-payments:Tickets:Sell:no', function() exports['qb-menu']:closeMenu() end)

AddEventHandler('onResourceStop', function(r) if r ~= GetCurrentResourceName() then return end
	for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
	for i = 1, #Till do DeleteEntity(Till[i]) end
	unloadModel(GetEntityModel(BankPed)) DeletePed(BankPed)
end)
