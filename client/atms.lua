local Targets = {}

if Config.ATMs.enable then
    CreateThread(function() -- Automatic detection of models and make targets and blips
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            for _, v in pairs(GetGamePool('CObject')) do
                for _, model in pairs(Config.ATMs.ATMModels) do
                    if GetEntityModel(v) == model then
                        local name, entCoords = getScript()..":ATMLocation:"..v, GetEntityCoords(v)
                        if #(pedCoords - entCoords) <= 150 then
                            if not Targets[name] then
                                Targets[name] =
                                    createCircleTarget({name, vec3(entCoords.x, entCoords.y, entCoords.z+1.03), 0.5, { name=name, debugPoly = debugMode, useZ=true, },},
                                        { { action = function() lookEnt(v) TriggerEvent(getScript()..":Client:ATM") end,
                                            icon = "fas fa-money-check-alt", label = locale("target", "atm"),
                                        }, }, 1.5)
                            end
                            if Config.ATMs.showBlips then
                                if not DoesBlipExist(GetBlipFromEntity(v)) then
                                    makeEntityBlip({entity = v, sprite = 434, col = 3, name = "ATM" })
                                end
                            end
                        else
                            removeZoneTarget(name)
                            Targets[name] = nil
                            if DoesBlipExist(GetBlipFromEntity(v)) then RemoveBlip(GetBlipFromEntity(v)) end
                        end
                    end
                end
            end
            Wait(5000)
        end
    end)
end

RegisterNetEvent(getScript()..":Client:ATM", function() local setheader = nil
	--this grabs all the info from names to savings account numbers in the databases
    local info = triggerCallback(getScript()..":GetInfo")
    jsonPrint(info)
    playAnim("amb@prop_human_atm@male@enter", "enter", 2000, 1)

	if progressBar({ label = locale("menu", "acc_atm"), time = 3000 }) then
        local Menu = {}

        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = locale("menu", "welcome")..info.name,
            txt = info.cid,
        }
        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = locale("menu", "header_balance"),
            txt = locale("menu", "bank_balance")..cv(info.bank)..br..locale("menu", "cash_balance")..cv(info.cash)
        }
        Menu[#Menu+1] = {
            header = locale("menu", "withdraw"),
            onSelect = function()
                atmWithdrawl(info)
            end,
        }
        local header = locale("menu", "header_atm")
        if Config.System.Menu == "qb" then
            header = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
        elseif Config.System.Menu == "ox" then
            header = '!['..''.. ']('..Config.General.menuLogo..')'
        end
        openMenu(Menu, { header = header, canClose = true, onExit = function() playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1) end, })
    else
        triggerNotify(nil, locale("error", "cancel"), "error")
    end
end)

function atmWithdrawl(info)
    local setimage = locale("menu", "header_atm")
    if Config.System.Menu == "qb" then setimage = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
    elseif Config.System.Menu == "ox" then setimage = '!['..''.. ']('..Config.General.menuLogo..')'
    end
    local dialog = createInput(locale("menu", "header_atm"), {
        {   type = 'radio',
            name = 'billtype',
            text = Config.System.Menu == "ox" and locale("menu", "bank_balance")..cv(info.bank)..locale("menu", "cash_balance")..cv(info.cash)
                or
            setimage..
            locale("menu", "header_balance")..br..
            locale("menu", "bank_balance")..cv(info.bank)..br..
            locale("menu", "cash_balance")..cv(info.cash)..br..br..
            locale("menu", "header_option"),
        options = {
            { value = "withdraw", text = locale("menu", "withdraw") },
        } },
        {   type = 'number',
            isRequired = true,
            name = 'amount',
            text = locale("menu", "header_trans_amount"),
            min = 0,
            max = info.bank,
        },
    })
    if dialog then
        if dialog[1] then
            dialog.billtype = dialog[1]
            dialog.amount = dialog[2] or 1
        end
        if not dialog.amount then return end
        playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1)
        Wait(1000)
        TriggerServerEvent(getScript()..":server:ATM:use", dialog.amount, dialog.billtype, dialog.account, "atm", info.society, info.gsociety)
    end
end

RegisterNetEvent(getScript()..":client:ATM:give", function()

	local newinputs = {} -- Begin qb-input creation here.
    local nearbyList = {}
    if Config.General.List then -- If nearby player list is wanted:
		--Retrieve a list of nearby players from server
		local onlineList = triggerCallback(getScript()..":MakePlayerList")
		--Convert list of players nearby into one qb-input understands + add distance info
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, v in ipairs(GetPlayersFromCoords(playerCoords, Config.General.PaymentRadius)) do
            local ped = GetPlayerPed(v)
            local dist = #(GetEntityCoords(ped) - playerCoords)
            for i = 1, #onlineList do
                if onlineList[i].value == GetPlayerServerId(v) then
                    if v ~= PlayerId() or debugMode then
                        nearbyList[#nearbyList+1] = {
                            value = onlineList[i].value,
                            label = onlineList[i].text .. ' (' .. math.floor(dist+0.05) .. 'm)',
                            text = onlineList[i].text .. ' (' .. math.floor(dist+0.05) .. 'm)'
                        }
                    end
                end
            end
        end
		--If list is empty(no one nearby) show error and stop
		if not nearbyList[1] then triggerNotify(nil, locale("error" ,"no_one"), "error") return end
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = { type = 'text', isRequired = true, required = true, name = 'citizen', label = locale("menu" ,"person_id"), text = locale("menu" ,"person_id") }
	end

    if Config.General.List then
        newinputs[#newinputs+1] = { type = "select", text = locale("menu" ,"cus_id"), name = "citizen", label = locale("menu" ,"cus_id"), default = 1, options = nearbyList }
    else
        newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen',  text = locale("menu" ,"cus_id") }
    end
    newinputs[#newinputs+1] = {
        type = 'select',
        name = 'billtype',
        text = locale("menu" ,"type"),
        default = billPrev,
        options = {
            { value = "cash", text = locale("menu" ,"cash"), label = locale("menu" ,"cash") },
        }
    }
    newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = locale("menu" ,"amount_charge") }

    local dialog = createInput(locale("menu", "give_cash"), newinputs)

	if dialog then
        if dialog[1] then
            dialog.citizen = dialog[1]
            dialog.billtype = dialog[2]
            dialog.price = dialog[3]
        end
        billPrev = dialog.billtype
        TriggerServerEvent('jim-payments:server:ATM:give', dialog.citizen, dialog.price)
    end
end)