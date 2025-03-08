Peds = {}

RegisterNetEvent('QBCore:Client:SetDuty', function(duty) onDuty = duty end)

if Config.Banks.enable then
    for k, v in pairs(BankLocations) do
        for i = 1, #v do
            local name = getScript()..":BankLocation:"..k..i
            if Config.General.Peds then
                if not Config.Gabz then CreateModelHide(v[i].xyz, 1.0, `v_corp_bk_chair3`, true) end
                if not Peds[name] then
                    Peds[name] = makePed(Config.General.PedPool[math.random(1, #Config.General.PedPool)], v[i], false, false)
                    if isStarted("jim-talktonpc") then
                        exports["jim-talktonpc"]:createDistanceMessage("hi", Peds[name], 3.0, false)
                    end
                end
            end
            local jobroles = {} local gangroles = {}
            for k, v in pairs(Config.Receipts.Jobs) do
                if v.gang then
                    gangroles[k] = 0
                else
                    jobroles[k] = 0
                end
            end
            createCircleTarget(
                { name, vec3(v[i].x, v[i].y, v[i].z+0.2), 2.0, { name = name, debugPoly = debugMode, useZ = true, }, }, {
                    {   action = function()
                        if Config.General.Peds and isStarted("jim-talktonpc") then
                            exports["jim-talktonpc"]:createCam(Peds[name], true, "generic", true)
                        end
                        TriggerEvent(getScript()..":Client:Bank", { ped = Config.General.Peds and Peds[name] })
                    end,
                        icon = "fas fa-piggy-bank", label = locale("target", "bank") },
                    {   action = function() TriggerEvent(getScript()..":Tickets:Menu", { gang = false }) end,
                        icon = "fas fa-receipt", label = locale("target", "cashin_boss"), job = jobroles,
                    },
                    {   action = function() TriggerEvent(getScript()..":Tickets:Menu", { gang = true }) end,
                        icon = "fas fa-receipt", label = locale("target", "cashin_gang"), gang = gangroles,
                    },
                }, 2.5)
            if Config.Banks.showBlips then
                makeBlip({coords = v[i], sprite = 814, col = 2, scale = 0.7, disp = 6, name = locale("blip", "blip_bank") })
            end
        end
    end
end

RegisterNetEvent(getScript()..":Client:Bank", function(data) local setheader = nil
	--this grabs all the info from names to savings account numbers in the databases
    local bankinfo = triggerCallback(getScript()..":GetInfo")
    local info = getPlayer()
    info.ped = data.ped or nil

    playAnim("amb@prop_human_atm@male@enter", "enter", 2000, 1)

	if progressBar({ label = locale("menu", "acc_bank"), time = 3000 }) then
        local Menu = {}

        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = locale("menu", "welcome")..info.name,
            txt = locale("menu", "header_acc").." "..info.account..br..locale("menu", "citizenid").." "..info.citizenId,
        }
        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = locale("menu", "header_acc")..locale("menu", "header_balance"),
            txt = locale("menu", "bank_balance")..cv(info.bank)..br..locale("menu", "cash_balance")..cv(info.cash)
        }
        Menu[#Menu+1] = {
            header = locale("menu", "deposit").."/"..locale("menu", "withdraw"),
            icon = "fas fa-piggy-bank",
            onSelect = function()
                info.id = "bank"
                bankTransaction(info, bankinfo)
            end,
        }
        if isStarted(QBExport) and not isStarted(QBXExport) then -- only supports qbcore account transfers
            Menu[#Menu+1] = {
                header = locale("target", "transfer"),
                icon = "fas fa-arrow-right-arrow-left",
                onSelect = function()
                    info.id = "transfer"
                    bankTransaction(info, bankinfo)
                end,
            }

            Menu[#Menu+1] = {
                header = locale("target", "saving"),
                icon = "fas fa-money-check-dollar",
                onSelect = function()
                    info.id = "savings"
                    bankTransaction(info, bankinfo)
                end,
            }
        end
        if info.jobBoss then
            Menu[#Menu+1] = {
                header = locale("target", "soc_saving"),
                txt = Jobs[info.job].label..br.." 🏦 $"..bankinfo.society or "Error",
                icon = "fas fa-building",
                onSelect = function()
                    info.id = "society"
                    bankTransaction(info, bankinfo)
                end,
            }
            if isStarted(QBExport) and not isStarted(QBXExport) then -- only supports qbcore account transfers
                Menu[#Menu+1] = {
                    header = locale("target", "soc_trans"),
                    txt = Jobs[info.job].label or "Error",
                    icon = "fas fa-arrow-right-arrow-left",
                    onSelect = function()
                        info.id = "societytransfer"
                        bankTransaction(info, bankinfo)
                    end,
                }
            end
        end
        if info.gangBoss then
            Menu[#Menu+1] = {
                header = locale("target", "gang_acct"),
                txt = Gangs[info.gang].label or "Error",
                icon = "fas fa-building",
                onSelect = function()
                    info.id = "gang"
                    bankTransaction(info, bankinfo)
                end,
            }
            if isStarted(QBExport) then
                Menu[#Menu+1] = {
                    header = locale("target", "gang_trans"),
                    txt = Gangs[info.gang].label or "Error",
                    icon = "fas fa-arrow-right-arrow-left",
                    onSelect = function()
                        info.id = "gangtransfer"
                        bankTransaction(info, bankinfo)
                    end,
                }
            end
        end
        local header = locale("menu", "header_atm")
        if Config.System.Menu == "qb" then header = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
        elseif Config.System.Menu == "ox" then header = '!['..''.. ']('..Config.General.menuLogo..')'
        end
        openMenu(Menu, { header = header, canClose = true, onExit = function()
            if Config.General.Peds and isStarted("jim-talktonpc") then
                exports["jim-talktonpc"]:stopCam()
            end
            playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1)
        end, })
    else
        triggerNotify(nil, locale("error", "cancel"), "error")
    end
end)

function bankTransaction(info, bankinfo)
    local setimage = locale("menu", "header_atm")
    if Config.System.Menu == "qb" then setimage = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
    elseif Config.System.Menu == "ox" then setimage = '!['..''.. ']('..Config.General.menuLogo..')'
    end

    playAnim("amb@prop_human_atm@male@idle_a", "idle_a", nil, 1)
    if isStarted("jim-talktonpc") then exports["jim-talktonpc"]:injectEmotion("thanks", info.ped) end
	local setinputs, setheader = {}, ""

	if info.id == "bank" then
        setheader = locale("menu", "header_bank")
        setinputs = {
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
                    { value = "deposit", text = locale("menu", "deposit") }
                },
            },
			{   type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }

	elseif info.id == "transfer" then
        setheader = locale("menu", "header_trans")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..
                locale("menu", "header_option"),
                options = {
                    { value = "transfer", text = locale("menu", "transfer") }
                },
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = locale("menu", "header_account_no")
            },
			{ type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount"),
                min = 0,
                max = info.bank,
            },
        }

	elseif info.id == "savings" then
        setheader = locale("menu", "header_saving")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and locale("menu", "saving_balance")..cv(bankinfo.savbal)..locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                locale("menu", "saving_balance")..cv(bankinfo.savbal)..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..br..
                locale("menu", "header_option"),
                options = {
                    { value = "withdraw", text = locale("menu", "withdraw") },
                    { value = "deposit", text = locale("menu", "deposit") }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }

	elseif info.id == "society" then
        setheader = Jobs[info.job].label.." - "..locale("menu", "header_soc_bank")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text =  Config.System.Menu == "ox" and Jobs[info.job].label.." - $"..cv(bankinfo.society)..locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                Jobs[info.job].label.." - $"..cv(bankinfo.society)..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..br..
                locale("menu", "header_option"),
                options = {
                    { value = "withdraw", text = locale("menu", "withdraw") },
                    { value = "deposit", text = locale("menu", "deposit") }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }

	elseif info.id == "societytransfer" then
        setheader =Jobs[info.job].label.." - "..locale("menu", "header_trans")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text =  Config.System.Menu == "ox" and Jobs[info.job].label.." - $"..cv(bankinfo.society)..locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                Jobs[info.job].label.." - $"..cv(bankinfo.society)..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..br..
                locale("menu", "header_option"),
                options = { { value = "transfer", text = locale("menu", "transfer") } }
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = locale("menu", "header_account_no")
            },
			{ type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }

	elseif info.id == "gang" then
        setheader = Gangs[info.gang].label.." - "..locale("menu", "header_soc_bank")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and Gangs[info.gang].label.." - $"..cv(bankinfo.gsociety)..locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                Gangs[info.gang].label.." - $"..cv(bankinfo.gsociety)..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..br..
                locale("menu", "header_option"),
                options = {
                    { value = "withdraw", text = locale("menu", "withdraw") },
                    { value = "deposit", text = locale("menu", "deposit") }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }

	elseif info.id == "gangtransfer" then
        setheader = Gangs[info.gang].label.." - "..locale("menu", "header_soc_bank")
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and Gangs[info.gang].label.." - $"..cv(bankinfo.gsociety)..locale("menu", "bank_balance")..cv(info.bank)
                or
                setimage..
                locale("menu", "header_balance")..br..
                Gangs[info.gang].label.." - $"..cv(bankinfo.gsociety)..br..
                locale("menu", "bank_balance")..cv(info.bank)..br..br..
                locale("menu", "header_option"),
                options = {
                    { value = "transfer", text = locale("menu", "transfer") }
                }
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = locale("menu", "header_account_no")
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = locale("menu", "header_trans_amount")
            },
        }
	end

    local dialog = createInput(setheader, setinputs)
    if dialog then
        if dialog[1] then
            dialog.billtype = dialog[1]
            dialog.amount = dialog[2] or 1
        end
        if not dialog.amount then
            TriggerEvent(getScript()..":Client:Bank", { ped = info.ped })
            return
        end
        if Config.General.Peds and isStarted("jim-talktonpc") then
            exports["jim-talktonpc"]:stopCam()
        end
        playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1)
        Wait(1000)
        TriggerServerEvent(getScript()..":server:ATM:use", dialog.amount, dialog.billtype, dialog.account, info.id, bankinfo.society, bankinfo.gsociety)
    end
end