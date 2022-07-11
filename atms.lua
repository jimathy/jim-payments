local QBCore = exports['qb-core']:GetCoreObject()

-- This script is a simple replacement for QB-Banking and QB-ATMs
-- It uses QB-Input and server callbacks to retreive info about accounts and cash
-- This requires QB-Target and has the location of every ATM, ATM prop and bank window

local Targets = {}
local Peds = {}

local BankLoc = Config.VanBankLocations
local ATMLoc = Config.VanATMLocations

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

local function loadModel(model) if not HasModelLoaded(model) then if Config.Debug then print("^5Debug^7: ^2Loading Model^7: '^6"..model.."^7'") end RequestModel(model) while not HasModelLoaded(model) do Wait(0) end end end
local function unloadModel(model) if Config.Debug then print("^5Debug^7: ^2Removing Model^7: '^6"..model.."^7'") end SetModelAsNoLongerNeeded(model) end
local function loadAnimDict(dict) if Config.Debug then print("^5Debug^7: ^2Loading Anim Dictionary^7: '^6"..dict.."^7'") end while not HasAnimDictLoaded(dict) do RequestAnimDict(dict) Wait(5) end end
local function unloadAnimDict(dict) if Config.Debug then print("^5Debug^7: ^2Removing Anim Dictionary^7: '^6"..dict.."^7'") end RemoveAnimDict(dict) end

local bossroles = {}
local gangroles = {}
CreateThread(function()
	if Config.useATM then
		if Config.ATMBlips then
			for _, v in pairs(Config.WallATMLocations) do
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
			for _, v in pairs(Config.ATMLocations) do
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
			for _, v in pairs(Config.BankLocations) do
				for _, b in pairs(v) do
					blip = AddBlipForCoord(b)
					SetBlipSprite(blip, 108)
					SetBlipDisplay(blip, 4)
					SetBlipScale(blip, 0.55)
					SetBlipColour(blip, 2)
					SetBlipAsShortRange(blip, true)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Bank")
					EndTextCommandSetBlipName(blip)
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
						if bossroles[tostring(k)] ~= nil then -- checks if the line exists
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
							if gangroles[tostring(k)] ~= nil then
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
		exports['qb-target']:AddTargetModel(Config.ATMModels, { options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = "Use ATM", id = "atm" },}, distance = 1.5, })
		for k,v in pairs(Config.WallATMLocations) do
			Targets["jimwallatm"..k] =
			exports['qb-target']:AddCircleZone("jimwallatm"..k, vector3(tonumber(v.x), tonumber(v.y), tonumber(v.z)+0.2), 0.5, { name="jimwallatm"..k, debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = "Use ATM", id = "atm" },
						  --{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Transfer Money", id = "transfer" },
			}, distance = 1.5 })
		end
		for k,v in pairs(Config.ATMLocations) do
			Targets["jimatm"..k] =
			exports['qb-target']:AddCircleZone("jimatm"..k, vector3(tonumber(v.x), tonumber(v.y), tonumber(v.z)+0.2), 0.5, { name="jimatm"..k, debugPoly=Config.Debug, useZ=true, },
			{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-alt", label = "Use ATM", id = "atm" },
						  --{ event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Transfer Money", id = "transfer" },
			}, distance = 1.5 })
		end
	end
	if Config.useBanks then
		for k,v in pairs(Config.BankLocations) do
			for l, b in pairs(v) do
				Targets["jimbank"..k..l] =
				exports['qb-target']:AddCircleZone("jimbank"..k..l, vector3(tonumber(b.x), tonumber(b.y), tonumber(b.z)+0.2), 2.0, { name="jimbank"..k..l, debugPoly=Config.Debug, useZ=true, },
				{ options = { { event = "jim-payments:Client:ATM:use", icon = "fas fa-piggy-bank", label = "Use Bank", id = "bank" },
							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Transfer Money", id = "transfer" },
							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-money-check-dollar", label = "Access Savings", id = "savings" },

							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = "Access Society Account", id = "society", job = bossroles },
							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Society Money Transfer", id = "societytransfer", job = bossroles },

							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-building", label = "Gang Society Account", id = "gang", gang = gangroles },
							  { event = "jim-payments:Client:ATM:use", icon = "fas fa-arrow-right-arrow-left", label = "Gang Money Transfer", id = "gangtransfer", gang = gangroles }, },
				distance = 2.5 })
				if Config.Peds then
					local i = math.random(1, #Config.PedPool)
					loadModel(Config.PedPool[i])
					if Peds["jimbank"..k..l] == nil then Peds["jimbank"..k..l] = CreatePed(0, Config.PedPool[i], vector3(tonumber(b.x), tonumber(b.y), tonumber(b.z)-1.03), b[4], false, false) end
					if Config.Debug then print("^5Debug^7: ^6Ped ^2Created for location^7: '^6"..k..l.."^7'") end
				end
			end
		end
	end
end)

local function PlayATMAnimation(animation)
    if animation == 'enter' then
		loadAnimDict('amb@prop_human_atm@male@enter')
		TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@enter', "enter", 1.0,-1.0, 1500, 1, 1, true, true, true)
		unloadAnimDict('amb@prop_human_atm@male@enter')
	end
    if animation == 'exit' then
		loadAnimDict('amb@prop_human_atm@male@exit')
		TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@exit', "exit", 1.0,-1.0, 3000, 1, 1, true, true, true)
		unloadAnimDict('amb@prop_human_atm@male@enter')
	end
end

local function GrabAccount(type, job)
	local p = promise.new()
	QBCore.Functions.TriggerCallback('jim-payments:ManageWrapper', function(cb) p:resolve(cb) end, type, job)
	return Citizen.Await(p)
end

RegisterNetEvent('jim-payments:Client:ATM:use', function(data)
	--this grabs all the info from names to savings account numbers in the databases
	local p = promise.new()
	QBCore.Functions.TriggerCallback('jim-payments:ATM:Find', function(cb) p:resolve(cb) end) local info = Citizen.Await(p)
	local society local gsociety local cancelled = false
	if Config.Manage then
		society = GrabAccount("GetAccount", PlayerJob.name)
		Wait(200)
		gsociety = GrabAccount("GetGangAccount", PlayerGang.name)
	else
		local p = promise.new()
		QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetAccount', function(cb) p:resolve(cb) end, PlayerJob.name) society = Citizen.Await(p)
		local p2 = promise.new()
		QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetAccount', function(cb) p2:resolve(cb) end, PlayerGang.name) gsociety = Citizen.Await(p2)
	end
	local atmbartime = 2500
	local setoptions = {}

	if data.id == "atm" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, }
		setview = "<center><img src=https://static.wikia.nocookie.net/gtawiki/images/b/bd/Fleeca-GTAV-Logo.png width=200px></center><br>Welcome back, "..info.name.."<br><br>- Citizen ID -<br>"..info.cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(info.bank).."<br>💵Cash - $"..cv(info.cash)..'<br><br>- Options -'
		setheader = "💵 ATM Banking 💵"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		for k, v in pairs(Config.ATMModels) do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed, true)
			local hash = GetHashKey(v)
			local atm = IsObjectNearPoint(hash, playerCoords.x, playerCoords.y, playerCoords.z, 1.6)
			if atm then
				local obj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.6, v, false, false, false)
				local atmCoords = GetEntityCoords(obj, false)
				TaskTurnPedToFaceEntity(playerPed, obj, 1000)
				Wait(1000)
				PlayATMAnimation('enter')
				QBCore.Functions.Progressbar("accessing_atm", "Accessing ATM", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
				end, function()
					TriggerEvent("QBCore:Notify", "Cancelled!", "error")
					cancelled = true
				end, data.icon)
			end
		end

	elseif data.id == "bank" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..info.name.."<br><br>- Account -<br>"..info.account.."<br>"..info.cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(info.bank).."<br>💵Cash - $"..cv(info.cash).."<br><br>- Options -"
		setheader = "🏦 Banking 🏦"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Bank", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "transfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..info.name.."<br><br>- Account -<br>"..info.account.."<br>"..info.cid.."<br><br>- Balances -<br>🏦Bank - $"..cv(info.bank).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "savings" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..info.name.."<br><br>- Account Info -<br>Savings ID: "..info.aid.."<br>"..info.cid.."<br><br>- Balances -<br>💰Savings - $"..cv(info.savbal).."<br>🏦Bank - $"..cv(info.bank).."<br><br>- Options -"
		setheader = "💰 Savings 💰"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Savings", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "society" then
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setview = "Welcome back, "..info.name.."<br><br>- Society Account -<br>"..PlayerJob.label.."<br><br>- Balances -<br>🏢"..PlayerJob.label.." - $"..cv(society).."<br>🏦Bank - $"..cv(info.bank).."<br><br>- Options -"
		setheader = "🏢 Society Banking 🏢"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Society Account", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "societytransfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..info.name.."<br><br>- Society Account -<br>"..PlayerJob.label.."<br><br>- Balances -<br>🏢"..PlayerJob.label.." - $"..cv(society).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "gang" then
		setheader = "🏢 Society Banking 🏢"
		setview = "Welcome back, "..info.name.."<br><br>- Society Account -<br>"..PlayerGang.label.."<br><br>- Balances -<br>🏢"..PlayerGang.label.." - $"..cv(gsociety).."<br>🏦Bank - $"..cv(info.bank).."<br><br>- Options -"
		setoptions = { { value = "withdraw", text = "Withdrawl" }, { value = "deposit", text = "Deposit" } }
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
				      { type = 'number', isRequired = true, name = 'amount', text = '💵 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Society Account", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done
		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)

	elseif data.id == "gangtransfer" then
		setoptions = { { value = "transfer", text = "Transfer" } }
		setview = "Welcome back, "..info.name.."<br><br>- Society Account -<br>"..PlayerGang.label.."<br><br>- Balances -<br>🏢"..PlayerGang.label.." - $"..cv(gsociety).."<br><br>- Options -"
		setheader = "🔀 Transfer Services 🔀"
		setinputs = { { type = 'radio', name = 'billtype', text = setview, options = setoptions },
					  { type = 'text', isRequired = true, name = 'account', text = '🏦 Account no.' },
					  { type = 'number', isRequired = true, name = 'amount', text = '💸 Amount to transfer' }, }
		PlayATMAnimation('enter')
		QBCore.Functions.Progressbar("accessing_atm", "Accessing Transfers", atmbartime, false, true, { disableMovement = false, disableCarMovement = false, disableMouse = false, disableCombat = false, }, {}, {}, {}, function() -- Done

		end, function()
			TriggerEvent("QBCore:Notify", "Cancelled!", "error")
			cancelled = true
		end, data.icon)
	end

	Wait(atmbartime+500)
	if not cancelled then
		cancelled = false
		local dialog = exports['qb-input']:ShowInput({ header = setheader, txt = "test", submitText = "Transfer", inputs = setinputs })
		if dialog then
			if not dialog.amount then return end
			PlayATMAnimation('exit') Citizen.Wait(1000)
			TriggerServerEvent('jim-payments:server:ATM:use', dialog.amount, dialog.billtype, dialog.account, data.id, society, gsociety)
		end
	end
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

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
	for k in pairs(Peds) do unloadModel(GetEntityModel(Peds[k])) DeletePed(Peds[k]) end
end)