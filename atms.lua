local QBCore = exports['qb-core']:GetCoreObject()

-- This script is a simple replacement for QB-Banking and QB-ATMs
-- It uses QB-Input and server callbacks to retreive info about accounts and cash
-- This requires QB-Target and has the location of every ATM, ATM prop and bank window
-- If Config.useATM = false, then none of this load

--Specific to ATM config options
Config.useATM = false
Config.useBanks = true
Config.BankBlips = true
Config.ATMBlips = false

Config.ATMModels = {"prop_atm_01", "prop_atm_02", "prop_atm_03", "prop_fleeca_atm" }

Config.ATMLocations = {
  --PACIFIC BANK 10 ATMS
	vector3(265.9, 213.86, 106.28),	
	vector3(265.56, 212.98, 106.28),
	vector3(265.19, 211.91, 106.28),
	vector3(264.86, 211.03, 106.28),
	vector3(264.52, 210.06, 106.28),
	vector3(236.64, 219.72, 106.29),
	vector3(237.04, 218.72, 106.29),
	vector3(237.5, 217.87, 106.29),
	vector3(237.93, 216.94, 106.29),
	vector3(238.36, 216.03, 106.29),
	
	--WALL ATMS
	vector3(-386.54, 6046.29, 31.5),
	vector3(-282.82, 6226.24, 31.49),
	vector3(-132.74, 6366.79, 31.48),
	vector3(-95.76, 6457.41, 31.46),
	vector3(-97.52, 6455.65, 31.47),
	vector3(155.95, 6642.99, 31.6),
	vector3(173.92, 6638.16, 31.57),
	vector3(2558.65, 350.92, 108.62),
	vector3(1077.78, -776.64, 58.35),
	vector3(1138.14, -468.88, 66.73),
	vector3(1166.93, -455.96, 66.81),
	vector3(285.37, 143.07, 104.17),
	vector3(-165.43, 234.81, 94.92),
	vector3(-165.4, 232.73, 94.92),
	vector3(-1410.41, -98.76, 52.43),
	vector3(-1409.85, -100.51, 52.38),
	vector3(-1206.0, -324.94, 37.86),
	vector3(-1205.23, -326.55, 37.86),
	vector3(-2072.28, -317.27, 13.32),
	vector3(-2974.7, 380.15, 15.0),
	vector3(-2959.01, 487.45, 15.46),
	vector3(-2956.87, 487.36, 15.46),
	vector3(-3043.98, 594.32, 7.74),
	vector3(-3241.35, 997.74, 12.55),
	vector3(-1305.59, -706.64, 25.32),
	vector3(-537.85, -854.69, 29.28),
	vector3(-709.98, -818.71, 23.73),
	vector3(-712.87, -818.71, 23.73),
	vector3(-526.71, -1223.18, 18.45),
	vector3(-256.47, -715.94, 33.55),
	vector3(-259.13, -723.29, 33.54),
	vector3(-203.82, -861.3, 30.27),
	vector3(111.38, -774.96, 31.44),
	vector3(114.56, -776.13, 31.42),
	vector3(112.46, -819.65, 31.34),
	vector3(118.93, -883.68, 31.12),
	vector3(-846.97, -340.29, 38.68),
	vector3(-846.41, -341.41, 38.68),
	vector3(-262.21, -2012.17, 30.15),
	vector3(-273.23, -2024.32, 30.15),
	vector3(24.46, -945.94, 29.36),
	vector3(-254.48, -692.74, 33.61),
	vector3(-1569.95, -546.94, 34.96),
	vector3(-1570.91, -547.63, 34.96),
	vector3(289.14, -1282.29, 29.6),
	vector3(289.18, -1256.84, 29.44),
	vector3(296.04, -896.22, 29.24),
	vector3(296.74, -894.26, 29.24),
	vector3(-301.63, -829.73, 32.43),
	vector3(-303.23, -829.44, 32.43),
	vector3(5.27, -919.87, 29.56),
	vector3(-1200.61, -885.62, 13.26),
}

Config.BankLocations = {
    vector3(149.9, -1040.46, 29.37),
    vector3(314.23, -278.83, 54.17),
    vector3(-350.8, -49.57, 49.04),
    vector3(-1213.0, -330.39, 37.79),
    vector3(-2962.71, 483.0, 15.7),
    vector3(1175.07, 2706.41, 38.09),
    vector3(247.44, 223.22, 106.29),
    vector3(-113.22, 6470.03, 31.63),
	vector3(242.25, 225.15, 106.29)
	--vector3(252.41, 221.41, 106.29)
}


local function cv(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end
local function createBlips()
	if Config.useATM then
		if Config.ATMBlips then
			for k, v in pairs(Config.ATMLocations) do
				blip = AddBlipForCoord(v)
				SetBlipSprite(blip, 108)
				SetBlipDisplay(blip, 4)
				SetBlipScale(blip, 0.55)
				SetBlipColour(blip, 3)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString("ATM")
				EndTextCommandSetBlipName(blip)
			end
		end
	end
	if Config.useBanks then
		if Config.BankBlips then
			for k, v in pairs(Config.BankLocations) do
				blip = AddBlipForCoord(v)
				SetBlipSprite(blip, 108)
				SetBlipDisplay(blip, 4)
				SetBlipScale(blip, 0.55)
				SetBlipColour(blip, 2)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString("Bank")
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() == resource then createBlips() end end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() createBlips() end)

Citizen.CreateThread(function()
	if Config.useATM or Config.useBanks then
		local bossroles = {}
		for k, v in pairs(QBCore.Shared.Jobs) do 
			for l, b in pairs(QBCore.Shared.Jobs[tostring(k)].grades) do
				if QBCore.Shared.Jobs[tostring(k)].grades[l].isboss == true then
					if bossroles[tostring(k)] ~= nil then
						if bossroles[tostring(k)] > tonumber(l) then bossroles[tostring(k)] = tonumber(l) end
					else bossroles[tostring(k)] = tonumber(l)
					end
				end
			end
		end
		local gangroles = {}
		for k, v in pairs(QBCore.Shared.Gangs) do 
			for l, b in pairs(QBCore.Shared.Gangs[tostring(k)].grades) do
				if tostring(k) ~= "none" then
					if QBCore.Shared.Gangs[tostring(k)].grades[l].isboss == true then
						if gangroles[tostring(k)] ~= nil then
							if gangroles[tostring(k)] > tonumber(l) then gangroles[tostring(k)] = tonumber(l) end
						else gangroles[tostring(k)] = tonumber(l)
						end
					end

				end	
			end
		end
	end
	if Config.useATM then
		exports['qb-target']:AddTargetModel(Config.ATMModels, { options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = "Use ATM", id = "atm" },}, distance = 1.5, })
		for k,v in pairs(Config.ATMLocations) do
			exports['qb-target']:AddCircleZone("jimatm"..k, vector3(tonumber(v.x), tonumber(v.y), tonumber(v.z)+0.2), 0.5, { name="jimatm"..k, debugPoly=false, useZ=true, }, 
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = "Use ATM", id = "atm" },
						  --[[{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Transfer Money", id = "transfer" },]] }, distance = 1.5 })
		end
	end
	if Config.useBanks then
		for k,v in pairs(Config.BankLocations) do
			exports['qb-target']:AddCircleZone("jimbank"..k, vector3(tonumber(v.x), tonumber(v.y), tonumber(v.z)), 2.0, { name="jimbank"..k, debugPoly=false, useZ=true, }, 
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-piggy-bank", label = "Use Bank", id = "bank" },
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Transfer Money", id = "transfer" },
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-dollar", label = "Access Savings", id = "savings" },
						  
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = "Access Society Account", id = "society", job = bossroles },
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Society Money Transfer", id = "societytransfer", job = bossroles },
						  
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = "Gang Society Account", id = "gang", gang = gangroles },
						  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Gang Money Transfer", id = "gangtransfer", gang = gangroles }, }, distance = 2.5 })
		end
	end
end)

local function PlayATMAnimation(animation)
    if animation == 'enter' then RequestAnimDict('amb@prop_human_atm@male@enter')
        while not HasAnimDictLoaded('amb@prop_human_atm@male@enter') do Wait(1) end
        if HasAnimDictLoaded('amb@prop_human_atm@male@enter') then TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@enter', "enter", 1.0,-1.0, 1500, 1, 1, true, true, true) end
	end
    if animation == 'exit' then RequestAnimDict('amb@prop_human_atm@male@exit')
		while not HasAnimDictLoaded('amb@prop_human_atm@male@exit') do Wait(1) end
        if HasAnimDictLoaded('amb@prop_human_atm@male@exit') then TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@exit', "exit", 1.0,-1.0, 3000, 1, 1, true, true, true) end
	end
end

RegisterNetEvent('jim-payments:Client:ATM:use', function(data)
	--this grabs all the info from names to savings account numbers in the databases
	while name == nil do 
	QBCore.Functions.TriggerCallback('jim-payments:ATM:Find', function(cb1, cb2, cb3, cb4, cb5, cb6, cb7) name = cb1 cash = cb2 bank = cb3 account = cb4 cid = cb5 savbal = cb6 aid = cb7 end) 
		Citizen.Wait(100) 
	end
	while society == nil do 
	QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetAccount', function(cb) society = cb end, PlayerJob.name)
		Citizen.Wait(100) 
	end	
	while gsociety == nil do 
	QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetAccount', function(cb) gsociety = cb end, PlayerGang.name)
		Citizen.Wait(100) 
	end
	local atmbartime = 2500
	local setoptions = {}

	if data.id == "atm" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, }
		setview = "Welcome back, "..name.."<br><br>- Citizen ID -<br>"..cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(bank).."<br>💵Cash - $"..cv(cash)..'<br><br>- Options -'
		setheader = "💵 ATM Banking 💵"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		for k, v in pairs(Config.ATMModels) do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed, true)
			local hash = GetHashKey(v)
			local atm = IsObjectNearPoint(hash, playerCoords.x, playerCoords.y, playerCoords.z, 1.5)
			if atm then
				local obj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.5, v, false, false, false)
				local atmCoords = GetEntityCoords(obj, false)
				TaskTurnPedToFaceEntity(playerPed, obj, 1000)
				Wait(1000)
				PlayATMAnimation('enter')
				QBCore.Functions.Progressbar("accessing_atm", "Accessing ATM", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
				end, function()
					TriggerEvent("QBCore:Notify", "Cancelled!", "error")
				return
				end)
			end
		end

	elseif data.id == "bank" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..name.."<br><br>- Account -<br>"..account.."<br>"..cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(bank).."<br>💵Cash - $"..cv(cash).."<br><br>- Options -"
		setheader = "🏦 Banking 🏦"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Bank", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)	
		
	elseif data.id == "transfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..name.."<br><br>- Account -<br>"..account.."<br>"..cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(bank).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)

	elseif data.id == "savings" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..name.."<br><br>- Account Info -<br>Savings ID: "..aid.."<br>"..cid.."<br><br>- Balances -<br>💰Savings - $"..cv(savbal).."<br>🏦Bank - $"..cv(bank).."<br><br>- Options -"
		setheader = "💰 Savings 💰"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }					
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Savings", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)
		
	elseif data.id == "society" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..name.."<br><br>- Society Account -<br>"..PlayerJob.label.."<br><br>- Balances -<br>🏢"..PlayerJob.label.." - $"..cv(society).."<br>🏦Bank - $"..cv(bank).."<br><br>- Options -"
		setheader = "🏢 Society Banking 🏢"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Society Account", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)
		
	elseif data.id == "societytransfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..name.."<br><br>- Society Account -<br>"..PlayerJob.label.."<br><br>- Balances -<br>🏢"..PlayerJob.label.." - $"..cv(society).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)
		
	elseif data.id == "gang" then
		setheader = "🏢 Society Banking 🏢"
		setview = "Welcome back, "..name.."<br><br>- Society Account -<br>"..PlayerGang.label.."<br><br>- Balances -<br>🏢"..PlayerGang.label.." - $"..cv(gsociety).."<br>🏦Bank - $"..cv(bank).."<br><br>- Options -"
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Society Account", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)
		
	elseif data.id == "gangtransfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..name.."<br><br>- Society Account -<br>"..PlayerGang.label.."<br><br>- Balances -<br>🏢"..PlayerGang.label.." - $"..cv(gsociety).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			return
		end)
	end
		
	Wait(atmbartime+500)
	local dialog = exports['qb-input']:ShowInput({ header = setheader, txt = "test", submitText = "Transfer", inputs = setinputs })
	if dialog then
		if not dialog.amount then return end
		PlayATMAnimation('exit') Citizen.Wait(1000)
		TriggerServerEvent('jim-payments:server:ATM:use', dialog.amount, dialog.billtype, dialog.account, data.id, society, gsociety)
	end
	gsociety, society, name = nil
end)


RegisterNetEvent('jim-payments:client:ATM:give', function()
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
		if nearbyList[#nearbyList] == nil then TriggerEvent("QBCore:Notify", "No one near by to charge", "error") return end
		local dialog = exports['qb-input']:ShowInput({ header = "Give someone cash", submitText = "Give",
		inputs = {
				{ text = " ", name = "citizen", type = "select", options = nearbyList },                
				{ type = 'number', isRequired = true, name = 'price', text = '💵  Amount to Pay' }, }
		})
		if dialog then
			if not dialog.citizen or not dialog.price then return end
			TriggerServerEvent('jim-payments:server:ATM:give', dialog.citizen, dialog.price)
		end
	end)
end)