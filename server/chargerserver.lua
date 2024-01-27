AddEventHandler('onResourceStart', function(r) if GetCurrentResourceName() ~= r then return end
	for k in pairs(Config.Receipts.Jobs) do
		if not Jobs[k] and not Gangs[k] then
			print("Jim-Payments: Config.Receipts.Jobs searched for job/gang '"..k.."' and couldn't find it in the Shared")
		end
	end
end)

registerCommand("cashregister", { Loc[Config.Lan].command["cash_reg"], {}, false, function(source) TriggerClientEvent("jim-payments:client:Charge", source, {}, true) end })

createCallback('jim-payments:MakePlayerList', function(source, cb)
	local onlineList = {}
	for _, v in pairs(Core.Functions.GetPlayers()) do
		local Player = getPlayer(v)
		onlineList[#onlineList+1] = {
			value = tonumber(v),
			text = "["..v.."] - "..Player.name
		}
	end
	if GetResourceState(OXLibExport):find("start") then return onlineList
	else cb(onlineList) end
end)

RegisterServerEvent("jim-payments:server:Charge", function(citizen, price, billtype, img, outside, gang)
	print(citizen, price, billtype, img, outside, gang)
	local src = source
    local biller = Core.Functions.GetPlayer(src)
    local billed = Core.Functions.GetPlayer(tonumber(citizen))
    local amount = tonumber(price)
	local balance = billed.Functions.GetMoney(billtype)
	if amount and amount > 0 then
		if balance < amount then
			triggerNotify(nil, Loc[Config.Lan].error["customer_nocash"], "error", src)
			triggerNotify(nil, Loc[Config.Lan].error["you_nocash"], "error", tonumber(citizen))
			return
		end
		local label = biller.PlayerData.job.label
		if gang == true then label = biller.PlayerData.gang.label end
		if Config.General.PhoneBank == false or gang == true or billtype == "cash" then
			TriggerClientEvent("jim-payments:client:PayPopup", billed.PlayerData.source, amount, src, billtype, img, label, gang, outside)
		else
			if Config.General.PhoneType == "qb" then
				MySQL.Async.insert(
					'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
					{billed.PlayerData.citizenid, amount, biller.PlayerData.job.name, biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid}, function(id)
						if id then
							TriggerClientEvent('qb-phone:client:AcceptorDenyInvoice', billed.PlayerData.source, id, biller.PlayerData.charinfo.firstname, biller.PlayerData.job.name, biller.PlayerData.citizenid, amount, GetInvokingResource())
						end
					end)
				TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
			elseif Config.General.PhoneType == "gks" then
				MySQL.Async.execute('INSERT INTO gksphone_invoices (citizenid, amount, society, sender, sendercitizenid, label) VALUES (@citizenid, @amount, @society, @sender, @sendercitizenid, @label)', {
					['@citizenid'] = billed.PlayerData.citizenid,
					['@amount'] = amount,
					['@society'] = biller.PlayerData.job.name,
					['@sender'] = biller.PlayerData.charinfo.firstname,
					['@sendercitizenid'] = biller.PlayerData.citizenid,
					['@label'] = biller.PlayerData.job.label,
				})
				TriggerClientEvent('gksphone:notifi', src, {title = 'Billing', message = Loc[Config.Lan].success["inv_succ"], img= '/html/static/img/icons/logo.png' })
				TriggerClientEvent('gksphone:notifi', billed.PlayerData.source, {title = 'Billing', message = Loc[Config.Lan].success["inv_recieved"], img= '/html/static/img/icons/logo.png' })
			end
			triggerNotify(nil, Loc[Config.Lan].success["inv_succ"], 'success', src)
			triggerNotify(nil, Loc[Config.Lan].success["inv_recieved"], nil, billed.PlayerData.source)
		end
	else triggerNotify(nil, Loc[Config.Lan].error["charge_zero"], 'error', source) return end
end)

RegisterServerEvent("jim-payments:server:PayPopup", function(data)
	local src = source
    local billed = Core.Functions.GetPlayer(src)
    local biller = Core.Functions.GetPlayer(tonumber(data.biller))
	local newdata = {
		senderCitizenId = biller.PlayerData.citizenid,
		society = data.gang and biller.PlayerData.gang.name or biller.PlayerData.job.name,
		amount = data.amount
	}
	if data.accept then
		billed.Functions.RemoveMoney(tostring(data.billtype), data.amount)
		if Config.General.ApGov then exports['ap-government']:chargeCityTax(billed.PlayerData.source, "Item", data.amount) end
		TriggerEvent('jim-payments:Tickets:Give', newdata, biller, data.gang)
		triggerNotify(nil, billed.PlayerData.charinfo.firstname..Loc[Config.Lan].success["accepted_pay"]..data.amount..Loc[Config.Lan].success["payment"], "success", data.biller)
	elseif not data.accept then
		triggerNotify(nil, Loc[Config.Lan].success["declined"], "error", src)
		triggerNotify(nil, billed.PlayerData.charinfo.firstname..Loc[Config.Lan].error["decline_pay"]..data.amount..Loc[Config.Lan].success["payment"], "error", data.biller)
	end
end)

RegisterServerEvent('jim-payments:Tickets:Give', function(data, biller, gang) local src = source
    local billed = Core.Functions.GetPlayer(src) -- This should always be from the person who accepted the payment
	local takecomm = math.floor(data.amount * Config.Receipts.Jobs[data.society].Commission)
	if biller ~= nil then -- If this is found, it ISN'T a phone payment, so add money to society here
		local billerGang, billerJob, amountChange, newAmount = tostring(biller.PlayerData.gang.name), tostring(biller.PlayerData.job.name), (data.amount - takecomm), 0

		if gang then
			if Config.General.Banking == "renewed" then
				exports['Renewed-Banking']:addAccountMoney(billerGang, amountChange)
				newAmount = exports['Renewed-Banking']:getAccountMoney(billerGang)

			elseif Config.General.Banking == "qb-management" or Config.General.Banking == "qb-banking" then
				exports[Config.General.Banking]:AddGangMoney(billerGang, amountChange)
				newAmount = exports[Config.General.Banking]:AddGangMoney(billerGang, amountChange)
				if Config.General.Banking == "qb-banking" then newAmount = newAmount["account_balance"] end

			elseif Config.General.Banking == "fd" then
				exports["fd_banking"]:AddGangMoney(billerGang, amountChange)
				newAmount = exports["fd_banking"]:GetGangAccount(billerGang)

			elseif Config.General.Banking == "okok" then
				exports['okokBanking']:AddMoney(billerGang, amountChange)
				newAmount = exports['okokBanking']:GetAccount(billerGang)
			end
		elseif not gang then
			if Config.General.Banking == "renewed" then
				exports['Renewed-Banking']:addAccountMoney(billerJob, amountChange)
				newAmount = exports['Renewed-Banking']:getAccountMoney(billerJob)

			elseif Config.General.Banking == "qb-management" or Config.General.Banking == "qb-banking" then
				exports[Config.General.Banking]:AddMoney(billerJob, amountChange)
				newAmount = exports[Config.General.Banking]:GetAccount(billerJob, amountChange)
				if Config.General.Banking == "qb-banking" then newAmount = newAmount["account_balance"] end

			elseif Config.General.Banking == "fd" then
				exports["fd_banking"]:AddMoney(billerJob, amountChange)
				newAmount = exports["fd_banking"]:GetAccount(billerJob)

			elseif Config.General.Banking == "okok" then
				exports['okokBanking']:AddMoney(billerJob, amountChange)
				newAmount = exports['okokBanking']:GetAccount(billerJob)
			end

		end
		print("^5Debug^7: ^3"..Config.General.Banking.."^7(^3"..(gang and "Gang" or "Job").."^7): ^2Adding ^7$"..amountChange.." ^2to account ^7'^6"..(gang and billerGang or billerJob).."^7' ($"..newAmount..")")
		if Config.System.Debug then
		end
	elseif not biller then	--Find the biller from their citizenid
		for _, v in pairs(Core.Functions.GetPlayers()) do
		local Player = Core.Functions.GetPlayer(v)
			if Player.PlayerData.citizenid == data.senderCitizenId then	biller = Player	end
		end
		triggerNotify(nil, data.sender..Loc[Config.Lan].success["invoice_start"]..data.amount..Loc[Config.Lan].success["invoice_end"], "success", biller.PlayerData.source)
	end

	-- If ticket system enabled, do this
	if (biller.PlayerData.job.onduty or gang) and Config.Receipts.TicketSystem then
		if data.amount >= Config.Receipts.Jobs[data.society].MinAmountforTicket then
			if Config.Receipts.TicketSystemAll then
				for _, v in pairs(Core.Functions.GetPlayers()) do
					local Player = Core.Functions.GetPlayer(v)
					if Player ~= nil or Player ~= billed then
						if gang then
							if Player.PlayerData.gang.name == data.society then
								TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, "payticket", 1, Player.PlayerData.source)
								triggerNotify(nil, Loc[Config.Lan].success["rec_rec"], 'success', Player.PlayerData.source)
							end
						else
							if Player.PlayerData.job.name == data.society and Player.PlayerData.job.onduty then
								TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, "payticket", 1, Player.PlayerData.source)
								triggerNotify(nil, Loc[Config.Lan].success["rec_rec"], 'success', Player.PlayerData.source)
							end
						end
					end
				end
			else
				TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, "payticket", 1, biller.PlayerData.source)
				triggerNotify(nil, Loc[Config.Lan].success["rec_rec"], 'success', biller.PlayerData.source)
			end
		end
	end

	-- Commission section, does each config option separately
	local comm = tonumber(Config.Receipts.Jobs[data.society].Commission)
	if Config.Receipts.Commission and comm ~= 0 then
		if Config.Receipts.CommissionLimit and data.amount < Config.Receipts.Jobs[data.society].MinAmountforTicket then return end
		if Config.Receipts.CommissionDouble then
			biller.Functions.AddMoney("bank", math.floor(tonumber(data.amount) * (comm *2)))
			triggerNotify(nil, Loc[Config.Lan].success["recieved"]..math.floor(tonumber(data.amount) * (comm *2))..Loc[Config.Lan].success["commission"], "success", biller.PlayerData.source)
		else biller.Functions.AddMoney("bank",  math.floor(tonumber(data.amount) *comm))
			triggerNotify(nil, Loc[Config.Lan].success["recieved"]..math.floor(tonumber(data.amount) * comm)..Loc[Config.Lan].success["commission"], "success", biller.PlayerData.source)
		end
		if Config.Receipts.CommissionAll then
			for _, v in pairs(Core.Functions.GetPlayers()) do
				local Player = Core.Functions.GetPlayer(v)
				if Player and Player ~= biller then
					if Player.PlayerData.job.name == data.society and Player.PlayerData.job.onduty then
						Player.Functions.AddMoney("bank",  math.floor(tonumber(data.amount) * comm))
						triggerNotify(nil, Loc[Config.Lan].success["recieved"]..math.floor(tonumber(data.amount) * comm)..Loc[Config.Lan].success["commission"], "success", Player.PlayerData.source)
					end
				end
			end
		end
	end
end)

RegisterServerEvent('jim-payments:Tickets:Sell', function()
    local Player = Core.Functions.GetPlayer(source)
	if not Player.Functions.GetItemByName("payticket") then triggerNotify(nil, Loc[Config.Lan].error["no_ticket_to"], 'error', source) return
	else
		tickets = Player.Functions.GetItemByName("payticket").amount
		Player.Functions.RemoveItem('payticket', tickets)
		pay = (tickets * Config.Receipts.Jobs[Player.PlayerData.job.name].PayPerTicket)
		Player.Functions.AddMoney('bank', pay, 'ticket-payment')
		TriggerClientEvent('inventory:client:ItemBox', source, Core.Shared.Items['payticket'], "remove", tickets)
		triggerNotify(nil, Loc[Config.Lan].success["trade_ticket_start"]..tickets..Loc[Config.Lan].success["trade_ticket_end"]..cv(pay), 'success', source)
	end
end)

CreateThread(function()
	if Config.Usebzzz then
		Core.Functions.CreateUseableItem('terminal', function(source, item)
		TriggerClientEvent("jim-payments:client:Charge", source, {}, true)
		end)
	end
end)