local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('jim-payments:Tickets:Give')
AddEventHandler('jim-payments:Tickets:Give', function(amount, job)
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == job and Player.PlayerData.job.onduty then
				if amount >= Config.Jobs[job].MinAmountforTicket then
					Player.Functions.AddItem('payticket', 1, false, {["quality"] = nil})
					TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Receipt received', 'success')
					TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items['payticket'], "add", 1) 
				elseif amount < Config.Jobs[job].MinAmountforTicket then
					TriggerClientEvent("QBCore:Notify", Player.PlayerData.source, "Amount too low, didn't receive a receipt", "error")
				end
			end
        end
    end
end)

RegisterServerEvent('jim-payments:Tickets:Sell')
AddEventHandler('jim-payments:Tickets:Sell', function(data)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemByName("payticket") == nil then TriggerClientEvent('QBCore:Notify', source, "No tickets to trade", 'error') return
	else
		tickets = Player.Functions.GetItemByName("payticket").amount
		Player.Functions.RemoveItem('payticket', tickets)
		pay = (tickets * Confing.Jobs[Player.PlayerData.job.name].PayPerTicket)
		Player.Functions.AddMoney('bank', pay, 'ticket-payment')
		TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['payticket'], "remove", tickets)
		TriggerClientEvent('QBCore:Notify', source, "Tickets: "..tickets.." Total: $"..pay, 'success')
	end
end)

RegisterServerEvent("jim-payments:server:Charge", function(citizen, price, billtype)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(citizen))
    local amount = tonumber(price)
	local billtype = string.lower(tostring(billtype))

	if billed ~= nil then
		if billtype == "cash" then balance = billed.Functions.GetMoney(billtype)
			if source == tonumber(citizen) then TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error') return end
			if balance >= amount then
				billed.Functions.RemoveMoney('cash', amount) TriggerEvent("qb-bossmenu:server:addAccountMoney", tostring(biller.PlayerData.job.name), amount)
				TriggerEvent('jim-payments:Tickets:Give', amount, tostring(biller.PlayerData.job.name))
			elseif balance < amount then
				TriggerClientEvent("QBCore:Notify", source, "Customer doesn't have enough cash to pay", "error")
				TriggerClientEvent("QBCore:Notify", tonumber(citizen), "You don't have enough cash to pay", "error")
			end
		elseif billtype == "card" then	
			if biller.PlayerData.citizenid == billed.PlayerData.citizenid then TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error') return end
			if amount and amount > 0 then
				MySQL.Async.insert(
					'INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
					{billed.PlayerData.citizenid, amount, biller.PlayerData.job.name,
					 biller.PlayerData.charinfo.firstname, biller.PlayerData.citizenid})
				TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
				TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
				TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New Invoice Received')
			else TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')	end
		end
	else TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error') end
end)

QBCore.Functions.CreateCallback('jim-payments:server:GetCurrentPlayers', function(source, cb)
	local onlineList = {}
	local SPlayer = QBCore.Functions.GetPlayer(source)
	for k, v in pairs(QBCore.Functions.GetPlayers()) do
		local Player = QBCore.Functions.GetPlayer(v)
		if Player ~= nil and v ~= source then
			local dist = #(vector3(Player.PlayerData.position.x, Player.PlayerData.position.y, Player.PlayerData.position.z) - vector3(SPlayer.PlayerData.position.x, SPlayer.PlayerData.position.y, SPlayer.PlayerData.position.z))
			if dist < Config.PaymentRadius then onlineList[#onlineList+1] = { value = tonumber(v), text = "["..v.."] - "..Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname } end
		end
	end
	cb(onlineList)
end)
