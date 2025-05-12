RegisterNetEvent(getScript()..":client:PolCharge", function()
    local Playerinfo = getPlayer()
	--Check if player is allowed to use /cashregister command
	local allowed = false
	for k in pairs(Config.PolCharge.FineJobs) do
        if k == Playerinfo.job then
            allowed = true
            break
        end
    end
	if not allowed then
        triggerNotify(nil, locale("error", "no_job"), "error")
        return
    end

	local newinputs = {} -- Begin qb-input creation here.
    local nearbyList = {}
    if Config.PolCharge.FineJobList then -- If nearby player list is wanted:
        -- Retrieve a list of nearby players from server
		local onlineList = triggerCallback(getScript()..":MakePlayerList")
		-- Convert list of players nearby into one an input script understands + add distance info
		for _, v in pairs(Core.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), Config.General.PaymentRadius)) do
			local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(PlayerPedId()))
			for i = 1, #onlineList do
				if onlineList[i].value == GetPlayerServerId(v) then
					if v ~= PlayerId() or debugMode then
						nearbyList[#nearbyList+1] = {
                            value = onlineList[i].value,
                            label = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)',
                            text = onlineList[i].text..' ('..math.floor(dist+0.05)..'m)'
                        }
					end
				end
			end
		end
		--If list is empty(no one nearby) show error and stop
		if not nearbyList[1] then
            triggerNotify(nil, locale("error" ,"no_one"), "error")
            return
        end

        newinputs[#newinputs+1] = {
            type = "select",
            text = locale("menu" ,"cus_id"),
            name = "citizen",
            label = locale("menu" ,"cus_id"),
            default = 1,
            options = nearbyList
        }
    else
        newinputs[#newinputs+1] = {
            type = 'text',
            isRequired = true,
            name = 'citizen',
            text = locale("menu" ,"cus_id")
        }
    end
    newinputs[#newinputs+1] = {
        type = 'number',
        isRequired = true,
        name = 'price',
        text = locale("menu" ,"amount_charge")
    }

    local dialog = createInput(Jobs[Playerinfo.job].label, newinputs)
	if dialog then
        jsonPrint(dialog)
        if dialog[1] then
            dialog.citizen = dialog[1]
            dialog.price = dialog[2]
        end
		TriggerServerEvent(getScript()..":server:PolCharge", dialog.citizen, dialog.price)
    end
end)

RegisterNetEvent(getScript()..":client:PolPopup", function(amount, biller, billerjob)
    local Menu = {}
    Menu[#Menu+1] = {
        isMenuHeader = true,
        header = "",
        txt = locale("menu" ,"bank_charge")..amount
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-check",
        header = locale("menu" ,"yes"),
        txt = "",
        onSelect = function()
            TriggerServerEvent(getScript()..":server:PolPopup", {
                accept = true,
                amount = amount,
                biller = biller,
            })
        end,
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-xmark",
        header = locale("menu" ,"no"),
        onSelect = function()
            TriggerServerEvent(getScript()..":server:PolPopup", {
                accept = false,
                amount = amount,
                biller = biller,
            })
        end,
    }
    openMenu(Menu, {
        header = "🧾 "..billerjob..locale("menu" ,"payment"),
        headertxt = locale("menu" ,"accept_payment"),
        onExit = function()
            TriggerServerEvent(getScript()..":server:PolPopup", {
                accept = false,
                amount = amount,
                biller = biller,
            })
        end,
    })
end)