local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('QBCore:Client:UpdateObject', function() QBCore = exports['qb-core']:GetCoreObject() end)

-- This script is a simple replacement for QB-Banking and QB-ATMs
-- It uses QB-Input and server callbacks to retreive info about accounts and cash
-- This requires QB-Target and has the location of every ATM, ATM prop and bank window

local Targets = {}
local Peds = {}

local BankLoc = Config.VanBankLocations
local ATMLoc = Config.VanATMLocations

local bossroles = {}
local gangroles = {}
CreateThread(function()
	if Config.useATM then
		if Config.ATMBlips then
			for _, v in pairs(Config.WallATMLocations) do
				makeBlip({coords = v, sprite = 108, col = 3, scale = 0.55, disp = 6, name = Loc[Config.Lan].blip["blip_atm"] })
			end
			for _, v in pairs(Config.ATMLocations) do
				makeBlip({coords = v, sprite = 108, col = 3, scale = 0.55, disp = 6, name = Loc[Config.Lan].blip["blip_atm"] })
			end
		end
	end
	if Config.useBanks then
		if Config.BankBlips then
			for _, v in pairs(Config.BankLocations) do
				for _, b in pairs(v) do
					makeBlip({coords = b, sprite = 108, col = 2, scale = 0.55, disp = 6, name = Loc[Config.Lan].blip["blip_bank"] })
					break
				end
			end
		end
	end
	if Config.useATM or Config.useBanks then
		for k in pairs(QBCore.Shared.Jobs) do ---Grabs the list of jobs
			if QBCore.Shared.Jobs[tostring(k)] then
				for l in pairs(QBCore.Shared.Jobs[tostring(k)].grades) do -- Grabs the list of grades
					if QBCore.Shared.Jobs[tostring(k)].grades[l].isboss == true then -- Checks the grade if is boss
						if bossroles[tostring(k)] then -- checks if the line exists
							if bossroles[tostring(k)] > tonumber(l) then bossroles[tostring(k)] = tonumber(l) end -- the
						else bossroles[tostring(k)] = tonumber(l)
						end
					end
				end
			end
		end
		for k in pairs(QBCore.Shared.Gangs) do
			if QBCore.Shared.Gangs[tostring(k)] then
				for l in pairs(QBCore.Shared.Gangs[tostring(k)].grades) do
					if tostring(k) ~= "none" then
						if QBCore.Shared.Gangs[tostring(k)].grades[l].isboss == true then
							if gangroles[tostring(k)] then
								if gangroles[tostring(k)] > tonumber(l) then gangroles[tostring(k)] = tonumber(l) end
							else gangroles[tostring(k)] = tonumber(l)
							end
						end
					end
				end
			end
		end
	end
	if Config.useATM then
		exports['qb-target']:AddTargetModel(Config.ATMModels, { options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = Loc[Config.Lan].target["atm"], id = "atm" },}, distance = 1.5, })
		for k,v in pairs(Config.WallATMLocations) do
			Targets["jimwallatm"..k] =
			exports['qb-target']:AddCircleZone("jimwallatm"..k, vector3(v.x, v.y, v.z+0.2), 0.5, { name="jimwallatm"..k, debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = Loc[Config.Lan].target["atm"], id = "atm" },
						--{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = Loc[Config.Lan].target["transfer_money"], id = "transfer" },
			}, distance = 1.5 })
		end
		for k,v in pairs(Config.ATMLocations) do
			Targets["jimatm"..k] =
			exports['qb-target']:AddCircleZone("jimatm"..k, vector3(v.x, v.y, v.z+0.2), 0.5, { name="jimatm"..k, debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = Loc[Config.Lan].target["atm"], id = "atm" },
						--{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = Loc[Config.Lan].target["transfer_money"], id = "transfer" },
			}, distance = 1.5 })
		end
	end
	if Config.useBanks then
		for k,v in pairs(Config.BankLocations) do
			for l, b in pairs(v) do
				Targets["jimbank"..k..l] =
				exports['qb-target']:AddCircleZone("jimbank"..k..l, vector3(b.x, b.y, b.z+0.2), 2.0, { name="jimbank"..k..l, debugPoly=Config.Debug, useZ=true, },
				{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-piggy-bank", label = Loc[Config.Lan].target["bank"], id = "bank" },
							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = Loc[Config.Lan].target["transfer"], id = "transfer" },
							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-dollar", label = Loc[Config.Lan].target["saving"], id = "savings" },

							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = Loc[Config.Lan].target["soc_saving"], id = "society", job = bossroles },
							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = Loc[Config.Lan].target["soc_trans"], id = "societytransfer", job = bossroles },

							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = Loc[Config.Lan].target["gang_acct"], id = "gang", gang = gangroles },
							{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = Loc[Config.Lan].target["gang_trans"], id = "gangtransfer", gang = gangroles }, },
				distance = 2.5 })
				if Config.Peds then
					local i = math.random(1, #Config.PedPool)
					if not Config.Gabz then CreateModelHide(b.xyz, 1.0, `v_corp_bk_chair3`, true) end
					if not Peds["jimbank"..k..l] then Peds["jimbank"..k..l] = makePed(Config.PedPool[i], b, false, false) end
				end
			end
		end
	end
end)

RegisterNetEvent('jim-payments:Client:ATM:use', function(data)
	--this grabs all the info from names to savings account numbers in the databases
	local p = promise.new()
	QBCore.Functions.TriggerCallback('jim-payments:ATM:Find', function(cb) p:resolve(cb) end) local info = Citizen.Await(p)
	if not Config.Manage then
		local p = promise.new()
		QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetAccount', function(cb) p:resolve(cb) end, PlayerJob.name) info.society = Citizen.Await(p)
		local p2 = promise.new()
		QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetAccount', function(cb) p2:resolve(cb) end, PlayerGang.name) info.gsociety = Citizen.Await(p2)
	end
	local atmbartime = 2500
	local bartext = ""
	local setoptions = {}

	if data.id == "atm" then
		setoptions = { { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] }, }
		setview = "<center><img src=https://static.wikia.nocookie.net/gtawiki/images/b/bd/Fleeca-GTAV-Logo.png width=200px></center><br>"..Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["citizenid"]..info.cid..Loc[Config.Lan].menu["header_balance_bank"]..cv(info.bank)..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_atm"]
		setinputs = { 	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		for k, v in pairs(Config.ATMModels) do
			if IsObjectNearPoint(v, GetEntityCoords(PlayerPedId()), 1.6) then
				local obj = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 1.6, v, false, false, false)
				local atmCoords = GetEntityCoords(obj)
				lookEnt(obj)
				bartext = Loc[Config.Lan].menu["acc_atm"]
			end
		end

	elseif data.id == "bank" then
		setoptions = { { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] }, { value = "deposit", text = Loc[Config.Lan].menu["deposit"] } }
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_acc"]..info.account.."<br>"..info.cid..Loc[Config.Lan].menu["header_balance_bank"]..cv(info.bank)..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_bank"]
		setinputs = { 	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_bank"]

	elseif data.id == "transfer" then
		setoptions = { { value = "transfer", text = Loc[Config.Lan].menu["transfer"] } }
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_acc"]..info.account.."<br>"..info.cid..Loc[Config.Lan].menu["header_balance_bank"]..cv(info.bank)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_trans"]
		setinputs = {	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'text', isRequired = true, name = 'account', text = Loc[Config.Lan].menu["header_account_no"] },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }

		bartext = Loc[Config.Lan].menu["acc_trans"]

	elseif data.id == "savings" then
		setoptions = { { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] }, { value = "deposit", text = Loc[Config.Lan].menu["deposit"] } }
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_info"]..info.aid.."<br>"..info.cid..Loc[Config.Lan].menu["saving_balance"]..cv(info.savbal)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_saving"]
		setinputs = {	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_saving"]

	elseif data.id == "society" then
		setoptions = { { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] }, { value = "deposit", text = Loc[Config.Lan].menu["deposit"] } }
		setview = 	Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_soc"]..PlayerJob.label..Loc[Config.Lan].menu["header_balance"]..PlayerJob.label.." - $"..cv(info.society)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
		setheader = Loc[Config.Lan].menu["header_soc_bank"]
		setinputs = { 	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_boss"]


	elseif data.id == "societytransfer" then
		setoptions = { { value = "transfer", text = Loc[Config.Lan].menu["transfer"] } }
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_soc"]..PlayerJob.label..Loc[Config.Lan].menu["header_balance"]..PlayerJob.label.." - $"..cv(info.society)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_trans"]
		setinputs = { 	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'text', isRequired = true, name = 'account', text = Loc[Config.Lan].menu["header_account_no"] },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_boss_trans"]


	elseif data.id == "gang" then
		setheader = Loc[Config.Lan].menu["header_soc_bank"]
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_soc"]..PlayerGang.label..Loc[Config.Lan].menu["header_balance"]..PlayerGang.label.." - $"..cv(info.gsociety)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..Loc[Config.Lan].menu["header_option"]
		setoptions = { { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] }, { value = "deposit", text = Loc[Config.Lan].menu["deposit"] } }
		setinputs = {	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_gang"]


	elseif data.id == "gangtransfer" then
		setoptions = { { value = "transfer", text = Loc[Config.Lan].menu["transfer"] } }
		setview = Loc[Config.Lan].menu["welcome"]..info.name..Loc[Config.Lan].menu["header_soc"]..PlayerGang.label..Loc[Config.Lan].menu["header_balance"]..PlayerGang.label.." - $"..cv(info.gsociety)..Loc[Config.Lan].menu["header_option"]
		setheader = Loc[Config.Lan].menu["header_trans"]
		setinputs = { 	{ type = 'radio', name = 'billtype', text = setview, options = setoptions },
						{ type = 'text', isRequired = true, name = 'account', text = Loc[Config.Lan].menu["header_account_no"] },
						{ type = 'number', isRequired = true, name = 'amount', text = Loc[Config.Lan].menu["header_trans_amount"] }, }
		bartext = Loc[Config.Lan].menu["acc_gang_trans"]

	end

	loadAnimDict('amb@prop_human_atm@male@enter')
	TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@enter', "enter", 1.0,-1.0, 1500, 1, 1, true, true, true)
	unloadAnimDict('amb@prop_human_atm@male@enter')
	QBCore.Functions.Progressbar("accessing_atm", bartext, atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function()
		local dialog = exports['qb-input']:ShowInput({ header = setheader, txt = "test", submitText = Loc[Config.Lan].menu["transfer"], inputs = setinputs })
		if dialog then
			if not dialog.amount then return end
			loadAnimDict('amb@prop_human_atm@male@exit')
			TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@exit', "exit", 1.0,-1.0, 3000, 1, 1, true, true, true)
			unloadAnimDict('amb@prop_human_atm@male@enter')
			Wait(1000)
			TriggerServerEvent('jim-payments:server:ATM:use', dialog.amount, dialog.billtype, dialog.account, data.id, info.society, info.gsociety)
		end
	end, function()	triggerNotify(nil, Loc[Config.Lan].error["cancel"], "error")
	end, data.icon)
end)

RegisterNetEvent('jim-payments:client:ATM:give', function()
	local onlineList = {}
	local nearbyList = {}
	QBCore.Functions.TriggerCallback('jim-payments:MakePlayerList', function(cb) onlineList = cb if onlineList[1] == nil then Wait(200) end
		for _, id in pairs(QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(id)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(id) then
					if id ~= PlayerId() or Config.Debug then
						nearbyList[#nearbyList+1] = { value = onlineList[i].value, text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
					end
				end
			end
			dist = nil
		end
		if not nearbyList[1] then triggerNotify(nil, Loc[Config.Lan].error["no_one"], "error") return end
		local dialog = exports['qb-input']:ShowInput({ header = Loc[Config.Lan].menu["give_cash"], submitText = Loc[Config.Lan].menu["give"],
		inputs = {
				{ text = " ", name = "citizen", type = "select", options = nearbyList },
				{ type = 'number', isRequired = true, name = 'price', text = Loc[Config.Lan].menu["amount_pay"] }, }
		})
		if dialog then
			if not dialog.citizen or not dialog.price then return end
			TriggerServerEvent('jim-payments:server:ATM:give', dialog.citizen, dialog.price)
		end
	end)
end)

AddEventHandler('onResourceStop', function(r) if r ~= GetCurrentResourceName() then return end
	for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
	for k in pairs(Peds) do unloadModel(GetEntityModel(Peds[k])) DeletePed(Peds[k]) end
end)
