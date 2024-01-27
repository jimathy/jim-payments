local Targets = {}

if Config.ATMs.enable then
    CreateThread(function() -- Automatic detection of models and make targets and blips
        while true do
            local pedCoords = GetEntityCoords(PlayerPedId())
            for _, v in pairs(GetGamePool('CObject')) do
                for _, model in pairs(Config.ATMs.ATMModels) do
                    if GetEntityModel(v) == model then
                        local name, entCoords = GetCurrentResourceName()..":ATMLocation:"..v, GetEntityCoords(v)
                        if #(pedCoords - entCoords) <= 150 then
                            if not Targets[name] then
                                Targets[name] =
                                    createCircleTarget({name, vec3(entCoords.x, entCoords.y, entCoords.z+1.03), 0.5, { name=name, debugPoly=Config.System.Debug, useZ=true, },},
                                        { { action = function() lookEnt(v) TriggerEvent("jim-payments:Client:ATM") end,
                                            icon = "fas fa-money-check-alt", label = Loc[Config.Lan].target["atm"],
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

RegisterNetEvent('jim-payments:Client:ATM', function() local setheader = nil
	--this grabs all the info from names to savings account numbers in the databases
    local info = triggerCallback("jim-payments:GetInfo")

    playAnim("amb@prop_human_atm@male@enter", "enter", 2000, 1)

	if progressBar({ label = Loc[Config.Lan].menu["acc_atm"], time = 3000 }) then
        local Menu = {}

        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = Loc[Config.Lan].menu["welcome"]..info.name,
            txt = info.cid,
        }
        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = Loc[Config.Lan].menu["header_balance"],
            txt = Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)
        }
        Menu[#Menu+1] = {
            header = Loc[Config.Lan].menu["withdraw"],
            onSelect = function()
                atmWithdrawl(info)
            end,
        }
        local header = Loc[Config.Lan].menu["header_atm"]
        if Config.System.Menu == "qb" then header = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
        elseif Config.System.Menu == "ox" then header = '!['..''.. ']('..Config.General.menuLogo..')'
        end
        openMenu(Menu, { header = header, canClose = true, onExit = function() playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1) end, })
    else
        triggerNotify(nil, Loc[Config.Lan].error["cancel"], "error")
    end
end)

function atmWithdrawl(info)
    local setimage = Loc[Config.Lan].menu["header_atm"]
    if Config.System.Menu == "qb" then setimage = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
    elseif Config.System.Menu == "ox" then setimage = '!['..''.. ']('..Config.General.menuLogo..')'
    end
    local dialog = createInput(Loc[Config.Lan].menu["header_atm"], {
        {   type = 'radio',
            name = 'billtype',
            text =
            Config.System.Menu == "ox" and Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)
                or
            setimage..
            Loc[Config.Lan].menu["header_balance"]..br..
            Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..
            Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)..br..br..
            Loc[Config.Lan].menu["header_option"],
        options = {
            { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] },
        } },
        {   type = 'number',
            isRequired = true,
            name = 'amount',
            text = Loc[Config.Lan].menu["header_trans_amount"],
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
        TriggerServerEvent('jim-payments:server:ATM:use', dialog.amount, dialog.billtype, dialog.account, "atm", info.society, info.gsociety)
    end
end

