local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() == resource then TriggerEvent("jim-shops:MakeStash") end
	for k, v in pairs(Config.Products) do
		for i = 1, #v do
			if not QBCore.Shared.Items[Config.Products[k][i].name] then
				print("Config.Products['"..k.."'] can't find item: "..Config.Products[k][i].name)
			end
		end
	end
	for k, v in pairs(Config.Locations) do
		if v["products"] == nil then
			print("Config.Locations['"..k.."'] can't find its product table")
		end
	end
end)

local function GetStashItems(stashId)
	local items = {}
	local result = MySQL.Sync.fetchScalar('SELECT items FROM stashitems WHERE stash = ?', {stashId})
	if result then
		local stashItems = json.decode(result)
		if stashItems then
			for k, item in pairs(stashItems) do
				local itemInfo = QBCore.Shared.Items[item.name:lower()]
				if itemInfo then
					items[item.slot] = {
						name = itemInfo["name"],
						amount = tonumber(item.amount),
						info = item.info ~= nil and item.info or "",
						label = itemInfo["label"],
						description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
						weight = itemInfo["weight"],
						type = itemInfo["type"],
						unique = itemInfo["unique"],
						useable = itemInfo["useable"],
						image = itemInfo["image"],
						slot = item.slot,
					}
				end
			end
		end
	end
	return items
end

--Wrapper converting for opening shops externally
RegisterServerEvent('jim-shops:ShopOpen', function(shop, name, shoptable)
	local data = { shoptable = { products = shoptable.items, label = shoptable.label, }, custom = true }
	TriggerClientEvent('jim-shops:ShopMenu', source, data, true)
end)

RegisterServerEvent('jim-shops:GetItem', function(amount, billtype, item, shoptable, price, info, shop, num, nostash)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	--Inventory space checks
	local give = true
	local totalWeight = QBCore.Player.GetTotalWeight(Player.PlayerData.items)
    local maxWeight = QBCore.Config.Player.MaxWeight
	local slots = 0
	for k, v in pairs(Player.PlayerData.items) do slots = slots +1 end
	slots = Config.MaxSlots - slots
	local balance = Player.Functions.GetMoney(tostring(billtype))
	-- If too heavy:
	if (totalWeight + (QBCore.Shared.Items[item].weight * amount)) > maxWeight then 
		TriggerClientEvent("QBCore:Notify", src, "Not enough space in inventory", "error") give = false
	-- If unique and it would poof away:
	elseif QBCore.Shared.Items[item].unique and (tonumber(slots) < tonumber(amount)) then
		TriggerClientEvent("QBCore:Notify", src, "Not enough slots in inventory", "error") give = false
	else
		-- If its a weapon, do this:
		if QBCore.Shared.Items[item].type == "weapon" then 
			if QBCore.Shared.Items[item].unique then 
				for i = 1, amount do
					if Player.Functions.AddItem(item, 1) then
					else TriggerClientEvent('QBCore:Notify', src, "Can't give item!", "error") give = false break end
					Wait(10)
				end
			end
		else
			-- If item is unique:
			if QBCore.Shared.Items[item].unique then
				for i = 1, amount do
					if Player.Functions.AddItem(item, 1, nil, info) then
					else TriggerClientEvent('QBCore:Notify', src, "Can't give item!", "error") give = false break end
					Wait(10)
				end
			else
				if Player.Functions.AddItem(item, amount, false, info) then
					TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add", amount)
				else
					TriggerClientEvent('QBCore:Notify', source,  "Can't give item!", "error") give = false
				end
			end
		end

		if Config.Limit and not nostash then
			stashItems = GetStashItems("["..shop.."("..num..")]")
			for i = 1, #stashItems do
				if stashItems[i].name == item then
					if (stashItems[i].amount - amount) <= 0 then stashItems[i].amount = 0 else stashItems[i].amount = stashItems[i].amount - amount end 
					TriggerEvent('jim-shops:server:SaveStashItems', "["..shop.."("..num..")]", stashItems)
					if Config.Debug then print("Removing "..QBCore.Shared.Items[item].label.." x"..amount.." from Shop's Stash: '["..shop.."("..num..")]") end
				end
			end
		end
		--Money checks
		if give then
			if balance >= (tonumber(price) * tonumber(amount)) then 
				Player.Functions.RemoveMoney(tostring(billtype), (tonumber(price) * tonumber(amount)), 'ticket-payment')
			else 
				TriggerClientEvent("QBCore:Notify", src, "Not enough money", "error") return
			end
		end
	end
	--Make data to send back to main shop menu
	local data = {}
	data.shoptable = shoptable
	custom = true
	if Config.Limit and not nostash then
		custom = nil
		data.k = shop 
		data.l = num
	end
	TriggerClientEvent('jim-shops:ShopMenu', src, data, custom)
end)

RegisterNetEvent("jim-shops:MakeStash", function()
	for k, v in pairs(Config.Locations) do
		local stashTable = {}
		for l, b in pairs(v["coords"]) do
			for i = 1, #v["products"] do
				if Config.Debug then print("MakeStash - Searching for item '"..v["products"][i].name.."'")
					if not QBCore.Shared.Items[v["products"][i].name:lower()] then 
						print ("MakeStash - Can't find item '"..v["products"][i].name.."'")
					end
				end
				local itemInfo = QBCore.Shared.Items[v["products"][i].name:lower()]
				stashTable[i] = {
					name = itemInfo["name"],
					amount = tonumber(v["products"][i].amount),
					info = {},
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"],
					type = itemInfo["type"],
					unique = itemInfo["unique"],
					useable = itemInfo["useable"],
					image = itemInfo["image"],
					slot = i,
				}
			end
		if Config.Limit then TriggerEvent('jim-shops:server:SaveStashItems', "["..k.."("..l..")]", stashTable)
		elseif Config.Limit == false then stashname = "["..k.."("..l..")]" MySQL.Async.execute('DELETE FROM stashitems WHERE stash= ?', {stashname}) end 
		end
	end
end)

--Compatability Wrapper Event for qb-truckerjob to refill shop stashes
RegisterNetEvent("qb-shops:server:RestockShopItems", function(storeinfo)
	local k, l = nil
	local storename = storeinfo
	if string.find(storename, "247supermarket") then k = "247supermarket"
	elseif string.find(storename, "hardware") then k = "hardware"
	elseif string.find(storename, "robsliquor") then k = "robsliquor"
	elseif string.find(storename, "ltdgasoline") then k = "ltdgasoline"
	end
	l = storename:gsub(k,"") 
	if l == "" then l = 1 end
	local stashTable = {}
	for i = 1, #Config.Locations[k]["products"] do
		if Config.Debug then print("RestockShopItems - Searching for item '"..v["products"][i].name.."'")
			if not QBCore.Shared.Items[v["products"][i].name:lower()] then 
				print ("RestockShopItems - Can't find item '"..v["products"][i].name.."'")
			end
		end
		local itemInfo = QBCore.Shared.Items[Config.Locations[k]["products"][i].name:lower()]
		stashTable[i] = {
			name = itemInfo["name"],
			amount = tonumber(Config.Locations[k]["products"][i].amount),
			info = {},
			label = itemInfo["label"],
			description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
			weight = itemInfo["weight"],
			type = itemInfo["type"],
			unique = itemInfo["unique"],
			useable = itemInfo["useable"],
			image = itemInfo["image"],
			slot = i,
		}
	end
	if Config.Limit then TriggerEvent('jim-shops:server:SaveStashItems', "["..k.."("..l..")]", stashTable) end
end)

QBCore.Functions.CreateCallback('jim-shops:server:getLicenseStatus', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local licenseTable = Player.PlayerData.metadata["licences"]
    local licenseItem = Player.Functions.GetItemByName("weaponlicense")
    cb(licenseTable.weapon, licenseItem)
end)

QBCore.Functions.CreateCallback('jim-shops:server:GetStashItems', function(source, cb, stashId) cb(GetStashItems(stashId)) end)
RegisterNetEvent('jim-shops:server:SaveStashItems', function(stashId, items) MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashId, ['items'] = json.encode(items) }) end)
