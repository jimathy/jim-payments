onResourceStart(function()
	for k in pairs(Config.Receipts.Jobs) do
		while not Jobs do Wait(10) end
		if not Jobs[k] and not Gangs[k] then
			debugPrint("^1Error^7: ^5Config^7.^5Receipts^7.^5Jobs ^2searched for job/gang ^7'^3"..k.."^7' ^2and couldn't find it in the Shared^7")
		end
	end

	if Items and not Items["payticket"] then
		debugPrint("^1Error^7: ^2Unable to find ^7'^3payticket^7' ^2item  it in the Shared^7")
	end

	registerCommand("cashregister", {
		locale("command", "cash_reg"), {}, false,
		function(source)
			TriggerClientEvent(getScript()..":client:Charge", source, {}, true)
		end
	})

	createCallback(getScript()..":MakePlayerList", function(source)
		local onlineList = {}
		for _, v in pairs(GetPlayers()) do
			if v ~= nil or type(v) ~= "number" then
				local Player = getPlayer(v)
				onlineList[#onlineList+1] = { value = tonumber(v), text = "["..v.."] - "..Player.name }
				Wait(10)
			end
		end
		return onlineList
	end)


	if Config.General.Usebzzz then
		createUseableItem('terminal', function(source, item)
			TriggerClientEvent(getScript()..":client:Charge", source, {}, true)
		end)
	end
end, true)

RegisterServerEvent(getScript()..":server:Charge", function(citizen, price, billtype, img, outside, gang)
	local src = source
    local biller = getPlayer(src)
    local billed = getPlayer(tonumber(citizen))
    local amount = tonumber(price)
	local balance = billed[billtype]
	if amount and amount > 0 then
		if balance < amount then
			triggerNotify(nil, locale("error", "customer_nocash"), "error", src)
			triggerNotify(nil, locale("error", "you_nocash"), "error", tonumber(citizen))
			return
		end
		local label = gang == true and Gangs[biller.gang].label or Jobs[biller.job].label
		if Config.General.PhoneBank == false or gang == true or billtype == "cash" then
			TriggerClientEvent(getScript()..":client:PayPopup", billed.source, amount, src, billtype, img, label, gang, outside)
		else
			if Config.General.PhoneType == "qb" then
				MySQL.Async.insert(
					'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
					{billed.citizenid, amount, biller.job, biller.firstname, biller.citizenid}, function(id)
						if id then
							TriggerClientEvent('qb-phone:client:AcceptorDenyInvoice', billed.source, id, biller.firstname, biller.job, biller.citizenid, amount, GetInvokingResource())
						end
					end)
				TriggerClientEvent('qb-phone:RefreshPhone', billed.source)
			elseif Config.General.PhoneType == "gks" then
				MySQL.Async.execute('INSERT INTO gksphone_invoices (citizenid, amount, society, sender, sendercitizenid, label) VALUES (@citizenid, @amount, @society, @sender, @sendercitizenid, @label)', {
					['@citizenid'] = billed.citizenid,
					['@amount'] = amount,
					['@society'] = biller.job,
					['@sender'] = biller.firstname,
					['@sendercitizenid'] = biller.citizenid,
					['@label'] = label,
				})
				TriggerClientEvent('gksphone:notifi', src, {title = 'Billing', message = locale("success", "inv_succ"), img= '/html/static/img/icons/logo.png' })
				TriggerClientEvent('gksphone:notifi', billed.source, {title = 'Billing', message = locale("success", "inv_recieved"), img= '/html/static/img/icons/logo.png' })
			end
			triggerNotify(nil, locale("success", "inv_succ"), 'success', src)
			triggerNotify(nil, locale("success", "inv_recieved"), nil, billed.source)
		end
	else triggerNotify(nil, locale("error", "charge_zero"), 'error', source) return end
end)

RegisterServerEvent(getScript()..":server:PayPopup", function(data)
	local src = source
    local billed = getPlayer(src)
    local biller = getPlayer(tonumber(data.biller))
	local newdata = {
		senderCitizenId = biller.citizenid,
		society = data.gang and biller.gang or biller.job,
		amount = data.amount
	}
	if data.accept then
		chargePlayer(data.amount, data.billtype, src)
		if Config.General.ApGov then
			exports['ap-government']:chargeCityTax(billed.source, "Item", data.amount)
		end
		TriggerEvent(getScript()..":Tickets:Give", newdata, biller, data.gang)
		triggerNotify(nil, billed.firstname..locale("success", "accepted_pay")..data.amount..locale("success", "payment"), "success", data.biller)
	elseif not data.accept then
		triggerNotify(nil, locale("success", "declined"), "error", src)
		triggerNotify(nil, billed.firstname..locale("error", "decline_pay")..data.amount..locale("success", "payment"), "error", data.biller)
	end
end)