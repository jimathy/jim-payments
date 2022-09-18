local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('QBCore:Server:UpdateObject', function() if source ~= '' then return false end QBCore = exports['qb-core']:GetCoreObject() end)

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

RegisterServerEvent('jim-payments:server:ATM:use', function(amount, billtype, baccount, account, society, gsociety)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local cashB = Player.Functions.GetMoney("cash")
	local bankB = Player.Functions.GetMoney("bank")
	local amount = tonumber(amount)

	--Simple transfers from bank to wallet --
	if account == "bank" or account == "atm" then
		if billtype == "withdraw" then
			if bankB < amount then triggerNotify(nil, Loc[Config.Lan].error["bank_low"], "error", src)
			elseif bankB >= tonumber(amount) then
				triggerNotify(nil, Loc[Config.Lan].success["draw"]..cv(amount)..Loc[Config.Lan].success["from_bank"], "success") -- Don't really need this as phone gets notified when money is withdrawn
				Player.Functions.RemoveMoney('bank', amount) Wait(1500)
				Player.Functions.AddMoney('cash', amount)
			end
		elseif billtype == "deposit" then
			if cashB < amount then triggerNotify(nil, Loc[Config.Lan].error["no_cash"], "error", src)
			elseif cashB >= amount then
				Player.Functions.RemoveMoney('cash', amount) Wait(1500)
				Player.Functions.AddMoney('bank', amount)
				triggerNotify(nil, Loc[Config.Lan].success["deposited"]..cv(amount)..Loc[Config.Lan].success["into_bank"], "success", src)
			end
		end
	-- Transfers from bank to savings account --
	elseif account == "savings" then
		local getSavingsAccount = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_type = ?', { Player.PlayerData.citizenid, 'Savings' })
		if getSavingsAccount[1] ~= nil then savbal = tonumber(getSavingsAccount[1].amount) aid = getSavingsAccount[1].record_id end

		if billtype == "withdraw" then
			if savbal >= amount then
				savbal -= amount
				Player.Functions.AddMoney('bank', amount)
				triggerNotify(nil, "$"..cv(amount)..Loc[Config.Lan].success["draw_save"], "success", src)
				MySQL.Async.execute('UPDATE bank_accounts SET amount = ? WHERE citizenid = ? AND record_id = ?', { savbal, Player.PlayerData.citizenid, getSavingsAccount[1].record_id }, function(success)
					if success then	return true	else return false end
				end)
			elseif savbal < amount then
				triggerNotify(nil, Loc[Config.Lan].error["saving_low"], "error")
			end
		elseif billtype == "deposit" then
			if amount < bankB then
				savbal += amount
				Player.Functions.RemoveMoney('bank', amount)
				triggerNotify(nil, "$"..cv(amount)..Loc[Config.Lan].success["depos_save"], "success", src)
				MySQL.Async.execute('UPDATE bank_accounts SET amount = ? WHERE citizenid = ? AND record_id = ?', { savbal, Player.PlayerData.citizenid, getSavingsAccount[1].record_id }, function(success)
					if success then	return true	else return false end
				end)
			else triggerNotify(nil, Loc[Config.Lan].error["bank_low"], "error", src)
			end
		end
	--Simple transfers from society account to bank --
	elseif account == "society" then
		if billtype == "withdraw" then
			if tonumber(society) < amount then triggerNotify(nil, Loc[Config.Lan].error["soc_low"], "error", src)
			elseif tonumber(society) >= amount then
				triggerNotify(nil, Loc[Config.Lan].success["draw"]..cv(amount)..Loc[Config.Lan].success["fromthe"]..Player.PlayerData.job.label..Loc[Config.Lan].success["account"], "success", src)
				Player.Functions.AddMoney('bank', amount)
				if Config.Manage then exports["qb-management"]:RemoveMoney(tostring(Player.PlayerData.job.name), amount)
				else TriggerEvent("qb-bossmenu:server:removeAccountMoney", tostring(Player.PlayerData.job.name), amount) end
			end
		elseif billtype == "deposit" then
			if bankB < amount then triggerNotify(nil, Loc[Config.Lan].error["nomoney_bank"], "error", src)
			elseif bankB >= amount then
				if Config.Manage then exports["qb-management"]:AddMoney(tostring(Player.PlayerData.job.name), amount)
				else TriggerEvent("qb-bossmenu:server:addAccountMoney", tostring(Player.PlayerData.job.name), amount) end
				Player.Functions.RemoveMoney('bank', amount) Wait(1500)
				triggerNotify(nil, Loc[Config.Lan].success["deposited"]..cv(amount)..Loc[Config.Lan].success["into"]..Player.PlayerData.job.label..Loc[Config.Lan].success["account"], "success", src)
			end
		end
	-- Transfer from boss account to players --
	elseif account == "societytransfer" then
		local bannedCharacters = {'%','$',';'}
		local newAmount = tostring(amount)
		local newiban = tostring(baccount)
		for _, v in pairs(bannedCharacters) do
			newAmount = string.gsub(newAmount, '%' .. v, '')
			newiban = string.gsub(newiban, '%' .. v, '')
		end
		baccount = newiban
		amount = tonumber(newAmount)

		local Player = QBCore.Functions.GetPlayer(src)
		if (society - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
				if Config.Manage then exports["qb-management"]:RemoveMoney(tostring(Player.PlayerData.job.name), amount)
				else TriggerEvent("qb-bossmenu:server:removeAccountMoney", tostring(Player.PlayerData.job.name), amount) end
				if Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, Loc[Config.Lan].success["sent"]..amount..Loc[Config.Lan].success["to"]..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, Loc[Config.Lan].success["recieved"]..cv(amount)..Loc[Config.Lan].success["from"]..tostring(Player.PlayerData.job.label)..Loc[Config.Lan].success["account"], "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then triggerNotify(nil, Loc[Config.Lan].error["error_start"]..baccount..Loc[Config.Lan].error["error_end"], "error", src)
			end
		end

	--Simple transfers from gang society account to bank --
	elseif account == "gang" then
		if billtype == "withdraw" then
			if tonumber(gsociety) < amount then triggerNotify(nil, Loc[Config.Lan].error["soc_low"], "error", src)
			elseif tonumber(gsociety) >= amount then
				triggerNotify(nil, Loc[Config.Lan].success["draw"]..cv(amount)..Loc[Config.Lan].success["fromthe"]..Player.PlayerData.gang.label..Loc[Config.Lan].success["account"], "success", src)
				Player.Functions.AddMoney('bank', amount)
				if Config.Manage then exports["qb-management"]:RemoveGangMoney(tostring(Player.PlayerData.gang.name), amount)
				else TriggerEvent("qb-gangmenu:server:removeAccountMoney", tostring(Player.PlayerData.gang.name), amount) end
			end
		elseif billtype == "deposit" then
			if bankB < amount then triggerNotify(nil, Loc[Config.Lan].error["nomoney_bank"], "error", src)
			elseif bankB >= amount then
				if Config.Manage then exports["qb-management"]:AddGangMoney(tostring(Player.PlayerData.gang.name), amount)
				else TriggerEvent("qb-gangmenu:server:addAccountMoney", tostring(Player.PlayerData.gang.name), amount) end
				Player.Functions.RemoveMoney('bank', amount) Wait(1500)
				triggerNotify(nil, Loc[Config.Lan].success["deposited"]..cv(amount)..Loc[Config.Lan].success["into"]..Player.PlayerData.gang.label..Loc[Config.Lan].success["account"], "success", src)
			end
		end
	-- Transfer from gang account to players --
	elseif account == "gangtransfer" then
		local bannedCharacters = {'%','$',';'}
		local newAmount = tostring(amount)
		local newiban = tostring(baccount)
		for _, v in pairs(bannedCharacters) do
			newAmount = string.gsub(newAmount, '%' .. v, '')
			newiban = string.gsub(newiban, '%' .. v, '')
		end
		baccount = newiban
		amount = tonumber(newAmount)

		local Player = QBCore.Functions.GetPlayer(src)
		if (gsociety - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
				if Config.Manage then exports["qb-management"]:RemoveGangMoney(tostring(Player.PlayerData.gang.name), amount)
				else TriggerEvent("qb-bossmenu:server:removeAccountMoney", tostring(Player.PlayerData.gang.name), amount) end
				if not Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, Loc[Config.Lan].success["sent"]..amount..Loc[Config.Lan].success["to"]..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, Reciever.PlayerData.source, Loc[Config.Lan].success["recieved"]..cv(amount)..Loc[Config.Lan].success["from"]..tostring(Player.PlayerData.gang.label)..Loc[Config.Lan].success["account"], "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then triggerNotify(nil, Loc[Config.Lan].error["error_start"]..baccount..Loc[Config.Lan].error["error_end"], "error", src)

			end
		end

	elseif account == "transfer" then
		local bannedCharacters = {'%','$',';'}
		local newAmount = tostring(amount)
		local newiban = tostring(baccount)
		for _, v in pairs(bannedCharacters) do
			newAmount = string.gsub(newAmount, '%' .. v, '')
			newiban = string.gsub(newiban, '%' .. v, '')
		end
		baccount = newiban
		amount = tonumber(newAmount)

		local Player = QBCore.Functions.GetPlayer(src)
		if (Player.PlayerData.money.bank - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)
				Player.Functions.RemoveMoney('bank', amount)
				if Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, Loc[Config.Lan].success["sent"]..cv(amount)..Loc[Config.Lan].success["to"]..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, Loc[Config.Lan].success["recieved"]..cv(amount)..Loc[Config.Lan].success["from"]..Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname, "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then triggerNotify(nil, Loc[Config.Lan].error["error_start"]..baccount..Loc[Config.Lan].error["error_end"], "error", src)

			end
		end
	end
end)

QBCore.Functions.CreateCallback('jim-payments:ATM:Find', function(source, cb)
	local Player = QBCore.Functions.GetPlayer(source)
	local name = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
	local cid = Player.PlayerData.citizenid.." ["..source.."]"
	local cash = Player.Functions.GetMoney("cash")
	local bank = Player.Functions.GetMoney("bank")
	local account = Player.PlayerData.charinfo.account
	local society = 0
	local gsociety = 0

	-- If qb-management, grab info directly from database
	if Config.Manage then
		local result = MySQL.Sync.fetchAll('SELECT * FROM management_funds')
		for _, v in pairs(result) do
			if Player.PlayerData.job.name == v.job_name then society = v.amount end
		end
		if Player.PlayerData.gang.name ~= "none" then
			for _, v in pairs(result) do
				if Player.PlayerData.gang.name == v.job_name then gsociety = v.amount end
			end
		end
	else

	end
	-- Grab Savings account info
	local result = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_type = ?', { Player.PlayerData.citizenid, 'Savings' })
    if result[1] then
        accountID = result[1].record_id
        savingBalance = result[1].amount
	else
		MySQL.Async.insert('INSERT INTO bank_accounts (citizenid, amount, account_type) VALUES (?, ?, ?)', { Player.PlayerData.citizenid, 0, 'Savings' }, function() completed = true end) repeat Wait(0) until completed == true
		local result = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_type = ?', { Player.PlayerData.citizenid, 'Savings' })
		aid = result[1].record_id
		savingBalance = result[1].amount
    end
	cb({name = name,
		cash = cash,
		bank = bank,
		account = account,
		cid = cid,
		savbal = savingBalance,
		aid = accountID,
		society = society,
		gsociety = gsociety})
end)

QBCore.Commands.Add("cashgive", Loc[Config.Lan].command["pay_user"], {}, false, function(source) TriggerClientEvent("jim-payments:client:ATM:give", source) end)

RegisterServerEvent("jim-payments:server:ATM:give", function(citizen, price)
    local Player = QBCore.Functions.GetPlayer(source)
    local Reciever = QBCore.Functions.GetPlayer(tonumber(citizen))
    local amount = tonumber(price)
	local balance = Player.Functions.GetMoney("cash")

	if amount and amount > 0 then
		if balance >= amount then
			Player.Functions.RemoveMoney('cash', amount)
			triggerNotify(nil, Loc[Config.Lan].success["you_gave"]..Reciever.PlayerData.charinfo.firstname.." $"..cv(amount), "success", source)
			Reciever.Functions.AddMoney('cash', amount)
			triggerNotify(nil, Loc[Config.Lan].success["you_got"]..cv(amount)..Loc[Config.Lan].success["from"]..Player.PlayerData.charinfo.firstname, "success", tonumber(citizen))
		elseif balance < amount then
			triggerNotify(nil, Loc[Config.Lan].error["not_enough"], "error", source)
		end
	else triggerNotify(nil, Loc[Config.Lan].error["zero"], 'error', source) end
end)
