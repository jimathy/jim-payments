RegisterNetEvent('jim-payments:client:PolCharge', function()
	--Check if player is allowed to use /cashregister command
	local allowed = false
	for k in pairs(Config.PolCharge.FineJobs) do if k == PlayerJob.name then allowed = true end end
	if not allowed then triggerNotify(nil, Loc[Config.Lan].error["no_job"], "error") return end

	local newinputs = {} -- Begin qb-input creation here.
    local nearbyList = {}
    if Config.PolCharge.FineJobList then -- If nearby player list is wanted:
        --Retrieve a list of nearby players from server
		local onlineList = triggerCallback("jim-payments:MakePlayerList")
		--Convert list of players nearby into one qb-input understands + add distance info
		for _, v in pairs(Core.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.General.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(v) then
					if v ~= PlayerId() or Config.System.Debug then
						nearbyList[#nearbyList+1] = { value = onlineList[i].value, label = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)', text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)' }
					end
				end
			end
		end
		--If list is empty(no one nearby) show error and stop
		if not nearbyList[1] then triggerNotify(nil, Loc[Config.Lan].error["no_one"], "error") return end
	end

    if Config.PolCharge.FineJobList then
        newinputs[#newinputs+1] = { type = "select", text = Loc[Config.Lan].menu["cus_id"], name = "citizen", label = Loc[Config.Lan].menu["cus_id"], default = 1, options = nearbyList }
    else
        newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen',  text = Loc[Config.Lan].menu["cus_id"] }
    end
    newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = Loc[Config.Lan].menu["amount_charge"] }

    local dialog = createInput(img, newinputs)
	if dialog then
        if dialog[1] then
            dialog.citizen = dialog[1]
            dialog.price = dialog[2]
        end
		TriggerServerEvent('jim-payments:server:PolCharge', dialog.citizen, dialog.price)
    end
end)

RegisterNetEvent("jim-payments:client:PolPopup", function(amount, biller, billerjob)
    local Menu = {}
    Menu[#Menu+1] = { isMenuHeader = true, header = "", txt = Loc[Config.Lan].menu["bank_charge"]..amount }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-check",
        header = Loc[Config.Lan].menu["yes"],
        txt = "",
        onSelect = function()
            TriggerServerEvent("jim-payments:server:PolPopup", {
                accept = true,
                amount = amount,
                biller = biller,
            })
        end,
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-xmark",
        header = Loc[Config.Lan].menu["no"],
        onSelect = function()
            TriggerServerEvent("jim-payments:server:PolPopup", {
                accept = false,
                amount = amount,
                biller = biller,
            })
        end,
    }
    openMenu(Menu, {
        header = "🧾 "..billerjob..Loc[Config.Lan].menu["payment"],
        headertxt = Loc[Config.Lan].menu["accept_payment"],
        onExit = function()
            TriggerServerEvent("jim-payments:server:PolPopup", {
                accept = false,
                amount = amount,
                biller = biller,
            })
        end,
    })
end)