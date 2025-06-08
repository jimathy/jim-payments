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

	for _, v in pairs({"cashregister", "terminal"}) do
		registerCommand(v, {
			locale("command", "cash_reg"), {}, false,
			function(source)
				TriggerClientEvent(getScript()..":client:Charge", source, {}, true)
			end
		})
	end

	if Items["terminal"] then
		createUseableItem("terminal", function(source, item)
			TriggerClientEvent(getScript()..":client:Charge", source, {}, true)
		end)
	end

	createCallback(getScript()..":MakePlayerList", function(source)
		local onlineList = {}
		for _, v in pairs(GetPlayers()) do
			if v ~= nil or type(v) ~= "number" then
				local Player = getPlayer(v)
				if Player.name then
					onlineList[#onlineList+1] = { value = tonumber(v), text = "["..v.."] - "..Player.name }
				end
				Wait(10)
			end
		end
		return onlineList
	end)

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
			if sendPhoneInvoice({
				src = billed.source,
				amount = amount,
				billedCitizenid = billed.citizenId,
				job = biller.job,
				name = biller.firstname,
				billerCitizenid = biller.citizenId,
				label = label,

			}) then
				triggerNotify(nil, locale("success", "inv_succ"), 'success', src)
				triggerNotify(nil, locale("success", "inv_recieved"), nil, billed.source)
			else

			end
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