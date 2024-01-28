registerCommand("polcharge", { Loc[Config.Lan].command["charge"], {}, false, function(source) TriggerClientEvent("jim-payments:client:PolCharge", source) end })

RegisterServerEvent("jim-payments:server:PolCharge", function(citizen, price)
	local src = source
    local biller = Core.Functions.GetPlayer(src)
    local billed = Core.Functions.GetPlayer(tonumber(citizen))
	local price = math.floor(tonumber(price))

	local commPercent = Config.PolCharge.FineJobs[biller.PlayerData.job.name] and Config.PolCharge.FineJobs[biller.PlayerData.job.name].Commission or 0.25
	if Config.PolCharge.FineJobs[biller.PlayerData.job.name] then
		commPercent = Config.PolCharge.FineJobs[biller.PlayerData.job.name].Commission
	else
		commPercent = 0.25
		print("Can't find job in 'FineJobs', defaulting to 0.25 (25% commission)")
	end
	local commission = math.floor(price * commPercent)

	if price > 0 then
		if not Config.PolCharge.FineJobConfirmation then
			polCharge({
				biller = biller,
				billed = billed,
				price = price,
				commission = commission,
				billerJob = tostring(biller.PlayerData.job.name),
				amountChange = (price - commission)
			})

			triggerNotify(nil, billed.PlayerData.charinfo.firstname..Loc[Config.Lan].success["charged"]..(price - commission), "success", src)
			triggerNotify(nil, Loc[Config.Lan].success["you_charged"]..(price - commission), nil, billed.PlayerData.source)
		else
			TriggerClientEvent("jim-payments:client:PolPopup", billed.PlayerData.source, price, src, biller.PlayerData.job.label, commPercent)
		end
	else triggerNotify(nil, Loc[Config.Lan].error["charge_zero"], 'error', source) return end
end)

RegisterServerEvent("jim-payments:server:PolPopup", function(data)
	local src = source
    local billed = Core.Functions.GetPlayer(src)
    local biller = Core.Functions.GetPlayer(tonumber(data.biller))
	local price = math.floor(data.amount)
	local commission = math.floor(tonumber(data.amount) * data.commPercent)
	if data.accept then
		polCharge({
			biller = biller,
			billed = billed,
			price = price,
			commission = commission,
			billerJob = tostring(biller.PlayerData.job.name),
			amountChange = (price - commission)
		})
	elseif not data.accept then
		triggerNotify(nil, Loc[Config.Lan].error["declined_payment"], nil, src)
		triggerNotify(nil, billed.PlayerData.charinfo.firstname.." declined the $"..data.amount..Loc[Config.Lan].success["charge_end"], "error", data.biller)
	end
end)

function polCharge(data)
	local billedSource, billerSource, newAmount = data.billed.PlayerData.source, data.biller.PlayerData.source, 0
	if data.billed.Functions.RemoveMoney("bank", data.price) then
		if Config.System.Debug then print("^5Debug^7: ^3PolCharge^7 - ^2Player^7(^6"..billedSource.."^7) ^2charged ^7$^6"..data.price.."^7") end
	end
	if Config.ApGov then exports['ap-government']:chargeCityTax(billedSource, "Item", data.price) end
	if data.biller.Functions.AddMoney("bank", data.commission) then
		if Config.System.Debug then
			print("^5Debug^7: ^3PolCharge^7 - ^2Commission of ^7$^6"..data.commission.." ^2sent to Player^7(^6"..billerSource.."^7)")
		end
	end

	if Config.General.Banking == "renewed" then
		exports['Renewed-Banking']:addAccountMoney(data.billerJob, data.amountChange)
		newAmount = exports['Renewed-Banking']:getAccountMoney(data.billerJob)

	elseif Config.General.Banking == "qb-management" or Config.General.Banking == "qb-banking" then
		exports[Config.General.Banking]:AddMoney(data.billerJob, data.amountChange)
		newAmount = exports[Config.General.Banking]:GetAccount(data.billerJob)
		if Config.General.Banking == "qb-banking" then newAmount = newAmount.account_balance end

	elseif Config.General.Banking == "fd" then
		exports["fd_banking"]:AddMoney(data.billerJob, data.amountChange)
		newAmount = exports["fd_banking"]:GetAccount(data.billerJob)

	elseif Config.General.Banking == "okok" then
		exports['okokBanking']:AddMoney(data.billerJob, data.amountChange)
		newAmount = exports['okokBanking']:GetAccount(data.billerJob)

	end
	if Config.System.Debug then
		print("^5Debug^7: ^3"..Config.General.Banking.."^7(^3Job^7): ^2Adding ^7$"..data.amountChange.." ^2to account ^7'^6"..data.billerJob.."^7' ($"..newAmount..")")
	end
end