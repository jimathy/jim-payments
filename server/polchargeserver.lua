registerCommand("polcharge", {
	locale("command", "charge"), {}, false,
	function(source)
		TriggerClientEvent(getScript()..":client:PolCharge", source)
	end
})

RegisterServerEvent(getScript()..":server:PolCharge", function(citizen, price)
	local src = source
    local biller = getPlayer(src)
    local billed = getPlayer(tonumber(citizen))
	local price = math.floor(tonumber(price))

	local commPercent = Config.PolCharge.FineJobs[biller.job] and Config.PolCharge.FineJobs[biller.job].Commission or 0.25
	if Config.PolCharge.FineJobs[biller.job] then
		commPercent = Config.PolCharge.FineJobs[biller.job].Commission
	else
		commPercent = 0.25
		print("^3Warning^7: ^2Can't find player's job in ^7'Config.Polcharge.FineJobs', ^2defaulting to 0.25 (25% commission)^7")
	end
	local commission = math.floor(price * commPercent)
	print(commission)
	if price > 0 then
		if not Config.PolCharge.FineJobConfirmation then
			polCharge({
				biller = biller,
				billed = billed,
				price = price,
				commission = commission,
				billerJob = tostring(biller.job),
				amountChange = (price - commission)
			})

			triggerNotify(nil, billed.firstname..locale("success", "charged")..(price - commission), "success", src)
			triggerNotify(nil, locale("success", "you_charged")..(price - commission), nil, billed.source)
		else
			TriggerClientEvent(getScript()..":client:PolPopup", billed.source, price, src, biller.job, commPercent)
		end
	else triggerNotify(nil, locale("error", "charge_zero"), 'error', source) return end
end)

RegisterServerEvent(getScript()..":server:PolPopup", function(data)
	local src = source
    local billed = getPlayer(src)
    local biller = getPlayer(tonumber(data.biller))
	local price = math.floor(data.amount)
	local commission = math.floor(tonumber(data.amount) * data.commPercent)
	if data.accept then
		polCharge({
			biller = biller,
			billed = billed,
			price = price,
			commission = commission,
			billerJob = tostring(biller.job),
			amountChange = (price - commission)
		})
	elseif not data.accept then
		triggerNotify(nil, locale("error", "declined_payment"), nil, src)
		triggerNotify(nil, billed.PlayerData.charinfo.firstname.." declined the $"..data.amount..locale("success", "charge_end"), "error", data.biller)
	end
end)

function polCharge(data)
	local billedSource, billerSource, newAmount = data.billed.source, data.biller.source, 0
	local bankScript = nil

	chargePlayer(data.price, "bank", billedSource)
	debugPrint("^5Debug^7: ^3PolCharge^7 - ^2Player^7(^6"..billedSource.."^7) ^2charged ^7$^6"..data.price.."^7")

	if Config.ApGov then
		exports['ap-government']:chargeCityTax(billedSource, "Item", data.price)
	end

	fundPlayer(data.commission, "bank", billerSource)
	debugPrint("^5Debug^7: ^3PolCharge^7 - ^2Commission of ^7$^6"..data.commission.." ^2sent to Player^7(^6"..billerSource.."^7)")

	if isStarted("Renewed-Banking") then
		bankScript = "Renewed-Banking"
		exports["Renewed-Banking"]:addAccountMoney(data.billerJob, data.amountChange)
		newAmount = exports["Renewed-Banking"]:getAccountMoney(data.billerJob)

	elseif isStarted("qb-banking") then
		bankScript = "qb-banking"
		exports["qb-banking"]:AddMoney(data.billerJob, data.amountChange, "Cash Register Payment")
		newAmount = exports["qb-banking"]:GetAccountBalance(data.billerJob)

	elseif isStarted("fd_banking") then
		bankScript = "fd_banking"
		if gang then
			exports["fd_banking"]:AddGangMoney(data.billerJob, data.amountChange)
			newAmount = exports["fd_banking"]:GetGangAccount(data.billerJob)
		else
			exports["fd_banking"]:AddMoney(data.billerJob, data.amountChange)
			newAmount = exports["fd_banking"]:GetAccount(data.billerJob)
		end
	elseif isStarted("okokBanking") then
		bankScript = "okokBanking"
		exports['okokBanking']:AddMoney(data.billerJob, data.amountChange)
		newAmount = exports['okokBanking']:GetAccount(data.billerJob)
	end

	debugPrint("^5Debug^7: ^3"..bankScript.."^7(^3Job^7): ^2Adding ^7$"..data.amountChange.." ^2to account ^7'^6"..data.billerJob.."^7' ($"..newAmount..")")
end