onResourceStart(function()
	registerCommand("cashgive", {
		locale("command" , "pay_user"), {}, false,
		function(source)
			TriggerClientEvent(getScript()..":client:ATM:give", source)
		end
	})

	createCallback(getScript()..":GetInfo", function(source)
		local Player = getPlayer(source)
		local society, gsociety = 0, 0

		society = getSocietyAccount(Player.job)
		if Player.gang ~= "none" then
			gsociety = getSocietyAccount(Player.gang)
		end

		-- Savings account is only QBCore for now
		if isStarted(QBExport) and not isStarted(QBXExport) then
		-- Grab Savings account info
			local result = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_name = ?', { Player.citizenId, 'Savings_'..Player.citizenId, })
			if result[1] then
				accountID = result[1].citizenid
				savingBalance = result[1].account_balance
			else
				MySQL.Async.insert('INSERT INTO bank_accounts (citizenid, account_name, account_balance) VALUES (?, ?, ?)', { Player.citizenId, 'Savings_'..Player.citizenId, 0}, function() completed = true end) repeat Wait(0) until completed == true
				local result = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_name = ?', { Player.citizenId, 'Savings_'..Player.citizenId, })
				accountID = result[1].citizenid
				savingBalance = result[1].account_balance
			end
		end
		local retTable = {
			name = Player.firstname..' '..Player.lastname,
			cash = Player.cash,
			bank = Player.bank,
			account = Player.account,
			cid = Player.citizenId.." ["..source.."]",
			savbal = savingBalance,
			aid = accountID,
			society = society,
			gsociety = gsociety
		}

		return retTable
	end)
end, true)

RegisterServerEvent(getScript()..":server:ATM:use", function(amount, billtype, baccount, account, society, gsociety)
	local src = source
	local Player = getPlayer(src)
	local amount = tonumber(amount)
	local bankScript, newAmount = "", 0

	--Simple transfers from bank to wallet --
	if account == "bank" or account == "atm" then
		if billtype == "withdraw" then
			if Player.bank < amount then
				triggerNotify(nil, locale("error" ,"bank_low"), "error", src)
			elseif Player.bank >= tonumber(amount) then
				triggerNotify(nil, locale("success" ,"draw")..cv(amount)..locale("success" ,"from_bank"), "success") -- Don't really need this as phone gets notified when money is withdrawn
				chargePlayer(amount, "bank", src) Wait(1500)
				fundPlayer(amount, "cash", src)
			end
		elseif billtype == "deposit" then
			if Player.cash < amount then
				triggerNotify(nil, locale("error" ,"no_cash"), "error", src)
			elseif Player.cash >= amount then
				chargePlayer(amount, "cash", src) Wait(1500)
				fundPlayer(amount, "bank", src)
				triggerNotify(nil, locale("success" ,"deposited")..cv(amount)..locale("success" ,"into_bank"), "success", src)
			end
		end
	-- Transfers from bank to savings account --
	elseif account == "savings" then
		local getSavingsAccount = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE citizenid = ? AND account_name = ?', { Player.citizenId, 'Savings_'..Player.citizenId, })
		if getSavingsAccount[1] ~= nil then savbal = tonumber(getSavingsAccount[1].account_balance) aid = getSavingsAccount[1].citizenid end

		if billtype == "withdraw" then
			if savbal >= amount then
				savbal -= amount
				fundPlayer(amount, "cash", src)
				triggerNotify(nil, "$"..cv(amount)..locale("success" ,"draw_save"), "success", src)
				MySQL.Async.execute('UPDATE bank_accounts SET account_balance = ? WHERE citizenid = ?', { savbal, Player.citizenId }, function(success)
					if success then	return true	else return false end
				end)
			elseif savbal < amount then
				triggerNotify(nil, locale("error" ,"saving_low"), "error")
			end
		elseif billtype == "deposit" then
			if amount < Player.bank then
				savbal += amount
				chargePlayer(amount, "bank", src)
				triggerNotify(nil, "$"..cv(amount)..locale("success", "depos_save"), "success", src)
				MySQL.Async.execute('UPDATE bank_accounts SET account_balance = ? WHERE citizenid = ?', { savbal, Player.citizenId}, function(success)
					if success then	return true	else return false end
				end)
			else triggerNotify(nil, locale("error" ,"bank_low"), "error", src)
			end
		end
	--Simple transfers from society account to bank --
	elseif account == "society" then
		if billtype == "withdraw" then
			if tonumber(society) < amount then
				triggerNotify(nil, locale("error" ,"soc_low"), "error", src)
			elseif tonumber(society) >= amount then

				chargeSociety(Player.job, amount)
				fundPlayer(amount, "bank", src)

				triggerNotify(nil, locale("success", "draw")..cv(amount)..locale("success", "fromthe")..Jobs[Player.job].label..locale("success" ,"account"), "success", src)
			end
		elseif billtype == "deposit" then
			if Player.bank < amount then triggerNotify(nil, locale("error", "nomoney_bank"), "error", src)
			elseif Player.bank >= amount then
				fundSociety(Player.job, amount)
				chargePlayer(amount, "bank", src) Wait(1500)
				triggerNotify(nil, locale("success", "deposited")..cv(amount)..locale("success", "into")..Jobs[Player.job].label..locale("success", "account"), "success", src)
			end
		end
	-- Transfer from boss account to players --
	--[[ disabled until i work out a system for other frameworks
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

		local Player = Core.Functions.GetPlayer(src)
		if (society - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = Core.Functions.GetPlayerByCitizenId(result[1].citizenid)
				if Config.Banking == "renewed" then
					exports['Renewed-Banking']:removeAccountMoney(tostring(Player.PlayerData.job.name), amount)
				elseif Config.Banking == "qb-management" then
					exports["qb-management"]:RemoveMoney(tostring(Player.PlayerData.job.name), amount)
				elseif Config.Banking == "qb-banking" then
					exports["qb-banking"]:RemoveMoney(tostring(Player.PlayerData.job.name), amount)
				elseif Config.Banking == "fd" then
					exports.fd_banking:RemoveMoney(tostring(Player.PlayerData.job.name), amount)
				end
				if Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, locale("success" ,"sent"]..amount..locale("success" ,"to"]..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, locale("success" ,"recieved"]..cv(amount)..locale("success" ,"from"]..tostring(Player.PlayerData.job.label)..locale("success" ,"account"], "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then triggerNotify(nil, locale("error" ,"error_start"]..baccount..locale("error" ,"error_end"], "error", src)
			end
		end]]

	--Simple transfers from gang society account to bank --
	elseif account == "gang" then
		if billtype == "withdraw" then
			if tonumber(gsociety) < amount then
				triggerNotify(nil, locale("error" ,"soc_low"), "error", src)
			elseif tonumber(gsociety) >= amount then
				chargeSociety(Player.gang, amount)
			end

			fundPlayer(amount, "bank", src)
			triggerNotify(nil, locale("success" ,"draw")..cv(amount)..locale("success" ,"fromthe")..Gangs[Player.gang].label..locale("success" ,"account"), "success", src)

		elseif billtype == "deposit" then
			if Player.bank < amount then
				triggerNotify(nil, locale("error" ,"nomoney_bank"), "error", src)
			elseif Player.bank >= amount then
				fundSociety(Player.gang, amount)
				chargePlayer(amount, "bank", Player.source) Wait(1500)
				triggerNotify(nil, locale("success" ,"deposited")..cv(amount)..locale("success" ,"into")..Gangs[Player.gang].label..locale("success" ,"account"), "success", src)
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

		local Player = Core.Functions.GetPlayer(src)
		if (gsociety - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = Core.Functions.GetPlayerByCitizenId(result[1].citizenid)
				chargeSociety(Player.PlayerData.gang.nameg, amount)
				if not Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, locale("success" ,"sent")..amount..locale("success" ,"to")..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, Reciever.PlayerData.source, locale("success" ,"recieved")..cv(amount)..locale("success" ,"from")..tostring(Player.PlayerData.gang.label)..locale("success" ,"account"), "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then triggerNotify(nil, locale("error" ,"error_start")..baccount..locale("error" ,"error_end"), "error", src)

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

		local Player = Core.Functions.GetPlayer(src)
		if (Player.PlayerData.money.bank - amount) >= 0 then
			local query = '%"account":"' .. baccount .. '"%'
			local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
			if result[1] then
				local Reciever = Core.Functions.GetPlayerByCitizenId(result[1].citizenid)
				Player.Functions.RemoveMoney('bank', amount)
				if Reciever then
					Reciever.Functions.AddMoney('bank', amount)
					triggerNotify(nil, locale("success" ,"sent")..cv(amount)..locale("success" ,"to")..Reciever.PlayerData.charinfo.firstname.." "..Reciever.PlayerData.charinfo.lastname, "success", src)
					triggerNotify(nil, locale("success" ,"recieved")..cv(amount)..locale("success" ,"from")..Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname, "success", Reciever.PlayerData.source)
				else
					local RecieverMoney = json.decode(result[1].money)
					RecieverMoney.bank += amount
					MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
				end
			elseif not result[1] then
				triggerNotify(nil, locale("error" ,"error_start")..baccount..locale("error" ,"error_end"), "error", src)
			end
		end
	end
end)

RegisterServerEvent(getScript()..":server:ATM:give", function(citizen, price)
    local Player = getPlayer(source)
    local Reciever = getPlayer(tonumber(citizen))
    local amount = tonumber(price)
	local balance = Player.cash

	if amount and amount > 0 then
		if balance >= amount then
			chargePlayer(amount, "cash", source)
			triggerNotify(nil, locale("success" ,"you_gave")..Reciever.name.." $"..cv(amount), "success", source)
			fundPlayer(amount, "cash", Reciever.source)
			triggerNotify(nil, locale("success" ,"you_got")..cv(amount)..locale("success" ,"from")..Player.name, "success", tonumber(citizen))
		elseif balance < amount then
			triggerNotify(nil, locale("error" ,"not_enough"), "error", source)
		end
	else triggerNotify(nil, locale("error" ,"zero"), 'error', source) end
end)

