Peds = {}

onPlayerLoaded(function() Core.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang end) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerJob = JobInfo onDuty = PlayerJob.onduty end)
RegisterNetEvent('QBCore:Client:SetDuty', function(duty) onDuty = duty end)
RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo) PlayerGang = GangInfo end)

AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	Core.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job PlayerGang = PlayerData.gang onDuty = PlayerJob.onduty end)
end)

if Config.Banks.enable then
    for k, v in pairs(BankLocations) do
        for i = 1, #v do
            local name = GetCurrentResourceName()..":BankLocation:"..k..i
            if Config.General.Peds then
                if not Config.Gabz then CreateModelHide(v[i].xyz, 1.0, `v_corp_bk_chair3`, true) end
                if not Peds[name] then
                    Peds[name] = makePed(Config.General.PedPool[math.random(1, #Config.General.PedPool)], v[i], false, false)
                    if GetResourceState("jim-talktonpc"):find("start") then
                        exports["jim-talktonpc"]:createDistanceMessage("hi", Peds[name], 3.0, false)
                    end
                end
            end
            local jobroles = {} local gangroles = {}
            for k, v in pairs(Config.Receipts.Jobs) do if v.gang then gangroles[k] = 0 else jobroles[k] = 0 end end
            createCircleTarget(
                { name, vector3(v[i].x, v[i].y, v[i].z+0.2), 2.0, { name = name, debugPoly = Config.System.Debug, useZ = true, }, }, {
                    {   action = function()
                        if Config.General.Peds and GetResourceState("jim-talktonpc"):find("start") then
                            exports["jim-talktonpc"]:createCam(Peds[name], true, "generic", true)
                        end
                        TriggerEvent("jim-payments:Client:Bank", { ped = Config.General.Peds and Peds[name] })
                    end,
                        icon = "fas fa-piggy-bank", label = Loc[Config.Lan].target["bank"] },
                    {   action = function() TriggerEvent("jim-payments:Tickets:Menu", { gang = false }) end,
                        icon = "fas fa-receipt", label = Loc[Config.Lan].target["cashin_boss"], job = jobroles,
                    },
                    {   action = function() TriggerEvent("jim-payments:Tickets:Menu", { gang = true }) end,
                        icon = "fas fa-receipt", label = Loc[Config.Lan].target["cashin_gang"], gang = gangroles,
                    },
                }, 2.5)
            if Config.Banks.showBlips then
                makeBlip({coords = v[i], sprite = 814, col = 2, scale = 0.7, disp = 6, name = Loc[Config.Lan].blip["blip_bank"] })
            end
        end
    end
end

RegisterNetEvent('jim-payments:Client:Bank', function(data) local setheader = nil
	--this grabs all the info from names to savings account numbers in the databases
    local info = triggerCallback("jim-payments:GetInfo")
	if Config.Banking == "qb" then -- Callbacks to get society cash info
		local p = promise.new()
		QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetAccount', function(cb) p:resolve(cb) end, PlayerJob.name) info.society = Citizen.Await(p)
		local p2 = promise.new()
		QBCore.Functions.TriggerCallback('qb-gangmenu:server:GetAccount', function(cb) p2:resolve(cb) end, PlayerGang.name) info.gsociety = Citizen.Await(p2)
	end

    playAnim("amb@prop_human_atm@male@enter", "enter", 2000, 1)
    if data.ped then info.ped = data.ped end
	if progressBar({ label = Loc[Config.Lan].menu["acc_bank"], time = 3000 }) then
        local Menu = {}

        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = Loc[Config.Lan].menu["welcome"]..info.name,
            txt = Loc[Config.Lan].menu["header_acc"].." "..info.account..br..info.cid,
        }
        Menu[#Menu+1] = {
            isMenuHeader = true,
            header = Loc[Config.Lan].menu["header_acc"]..Loc[Config.Lan].menu["header_balance"],
            txt = Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)
        }
        Menu[#Menu+1] = {
            header = Loc[Config.Lan].menu["deposit"].."/"..Loc[Config.Lan].menu["withdraw"],
            icon = "fas fa-piggy-bank",
            onSelect = function() info.id = "bank" bankTransaction(info) end,
        }
        Menu[#Menu+1] = {
            header = Loc[Config.Lan].target["transfer"],
            icon = "fas fa-arrow-right-arrow-left",
            onSelect = function() info.id = "transfer" bankTransaction(info) end,
        }
        Menu[#Menu+1] = {
            header = Loc[Config.Lan].target["saving"],
            icon = "fas fa-money-check-dollar",
            onSelect = function() info.id = "savings" bankTransaction(info) end,
        }
        if PlayerJob.isboss then
            Menu[#Menu+1] = {
                header = Loc[Config.Lan].target["soc_saving"],
                txt = PlayerJob.label,
                icon = "fas fa-building",
                onSelect = function() info.id = "society" bankTransaction(info) end,
            }
            Menu[#Menu+1] = {
                header = Loc[Config.Lan].target["soc_trans"],
                txt = PlayerJob.label,
                icon = "fas fa-arrow-right-arrow-left",
                onSelect = function() info.id = "societytransfer" bankTransaction(info) end,
            }
        end
        if PlayerGang.isboss then
            Menu[#Menu+1] = {
                header = Loc[Config.Lan].target["gang_acct"],
                txt = PlayerGang.label,
                icon = "fas fa-building",
                onSelect = function() info.id = "gang" bankTransaction(info) end,
            }
            Menu[#Menu+1] = {
                header = Loc[Config.Lan].target["gang_trans"],
                txt = PlayerGang.label,
                icon = "fas fa-arrow-right-arrow-left",
                onSelect = function() info.id = "gangtransfer" bankTransaction(info) end,
            }
        end
        local header = Loc[Config.Lan].menu["header_atm"]
        if Config.System.Menu == "qb" then header = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
        elseif Config.System.Menu == "ox" then header = '!['..''.. ']('..Config.General.menuLogo..')'
        end
        openMenu(Menu, { header = header, canClose = true, onExit = function()
            if Config.General.Peds and GetResourceState("jim-talktonpc"):find("start") then
                exports["jim-talktonpc"]:stopCam()
            end
            playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1)
        end, })
    else
        triggerNotify(nil, Loc[Config.Lan].error["cancel"], "error")
    end
end)

function bankTransaction(info)
    local setimage = Loc[Config.Lan].menu["header_atm"]
    if Config.System.Menu == "qb" then setimage = "<center><img src="..Config.General.menuLogo.." width=200px></center>"
    elseif Config.System.Menu == "ox" then setimage = '!['..''.. ']('..Config.General.menuLogo..')'
    end

    playAnim("amb@prop_human_atm@male@idle_a", "idle_a", nil, 1)
    exports["jim-talktonpc"]:injectEmotion("thanks", info.ped)
	local setinputs, setheader = {}, ""

	if info.id == "bank" then
        setheader = Loc[Config.Lan].menu["header_bank"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..
                Loc[Config.Lan].menu["cash_balance"]..cv(info.cash)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] },
                    { value = "deposit", text = Loc[Config.Lan].menu["deposit"] }
                },
            },
			{ type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
            },
        }

	elseif info.id == "transfer" then
        setheader = Loc[Config.Lan].menu["header_trans"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "transfer", text = Loc[Config.Lan].menu["transfer"] }
                },
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = Loc[Config.Lan].menu["header_account_no"]
            },
			{ type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"],
                min = 0,
                max = info.bank,
            },
        }

	elseif info.id == "savings" then
        setheader = Loc[Config.Lan].menu["header_saving"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and Loc[Config.Lan].menu["saving_balance"]..cv(info.savbal)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                Loc[Config.Lan].menu["saving_balance"]..cv(info.savbal)..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] },
                    { value = "deposit", text = Loc[Config.Lan].menu["deposit"] }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
            },
        }

	elseif info.id == "society" then
        setheader = PlayerJob.label.." - "..Loc[Config.Lan].menu["header_soc_bank"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text =  Config.System.Menu == "ox" and PlayerJob.label.." - $"..cv(info.society)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                PlayerJob.label.." - $"..cv(info.society)..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] },
                    { value = "deposit", text = Loc[Config.Lan].menu["deposit"] }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
            },
        }

	elseif info.id == "societytransfer" then
        setheader = PlayerJob.label.." - "..Loc[Config.Lan].menu["header_trans"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text =  Config.System.Menu == "ox" and PlayerJob.label.." - $"..cv(info.society)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                PlayerJob.label.." - $"..cv(info.society)..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = { { value = "transfer", text = Loc[Config.Lan].menu["transfer"] } }
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = Loc[Config.Lan].menu["header_account_no"]
            },
			{ type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
            },
        }

	elseif info.id == "gang" then
        setheader = PlayerGang.label.." - "..Loc[Config.Lan].menu["header_soc_bank"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and PlayerGang.label.." - $"..cv(info.gsociety)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                PlayerGang.label.." - $"..cv(info.gsociety)..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "withdraw", text = Loc[Config.Lan].menu["withdraw"] },
                    { value = "deposit", text = Loc[Config.Lan].menu["deposit"] }
                }
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
            },
        }

	elseif info.id == "gangtransfer" then
        setheader = PlayerGang.label.." - "..Loc[Config.Lan].menu["header_soc_bank"]
        setinputs = {
            { type = 'radio',
                name = 'billtype',
                text = Config.System.Menu == "ox" and PlayerGang.label.." - $"..cv(info.gsociety)..Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)
                or
                setimage..
                Loc[Config.Lan].menu["header_balance"]..br..
                PlayerGang.label.." - $"..cv(info.gsociety)..br..
                Loc[Config.Lan].menu["bank_balance"]..cv(info.bank)..br..br..
                Loc[Config.Lan].menu["header_option"],
                options = {
                    { value = "transfer", text = Loc[Config.Lan].menu["transfer"] }
                }
            },
            { type = 'text',
                isRequired = true,
                name = 'account',
                text = Loc[Config.Lan].menu["header_account_no"]
            },
            { type = 'number',
                isRequired = true,
                name = 'amount',
                text = Loc[Config.Lan].menu["header_trans_amount"]
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
            TriggerEvent("jim-payments:Client:Bank", { ped = info.ped })
            return
        end
        if Config.General.Peds and GetResourceState("jim-talktonpc"):find("start") then
            exports["jim-talktonpc"]:stopCam()
        end
        playAnim("amb@prop_human_atm@male@exit", "exit", 3000, 1)
        Wait(1000)
        TriggerServerEvent('jim-payments:server:ATM:use', dialog.amount, dialog.billtype, dialog.account, info.id, info.society, info.gsociety)
    end
end