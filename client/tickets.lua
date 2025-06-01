if not Config.Banks.enable or not Config.Receipts.CashInAnywhere then
    onPlayerLoaded(function()
        local locations = BankLocations
        if not Config.Receipts.CashInAnywhere then
            locations = {
                ["receipts"] = Config.Receipts.CashInLocations
            }
        end
        for k, v in pairs(locations) do
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
                local jobroles = {}
                local gangroles = {}
                for k, v in pairs(Config.Receipts.Jobs) do
                    if v.gang then
                        gangroles[k] = 0
                    else
                        jobroles[k] = 0
                    end
                end
                createCircleTarget(
                    { name, vec3(v[i].x, v[i].y, v[i].z+0.2), 2.0, { name = name, debugPoly = debugMode, useZ = true, }, }, {
                    {   action = function() TriggerEvent(getScript()..":Tickets:Menu", { gang = false }) end,
                        icon = "fas fa-receipt", label = locale("target", "cashin_boss"), job = jobroles,
                    },
                    {   action = function() TriggerEvent(getScript()..":Tickets:Menu", { gang = true }) end,
                        icon = "fas fa-receipt", label = locale("target", "cashin_gang"), gang = gangroles,
                    },
                }, 2.5)
            end
        end
    end, true)
end

RegisterNetEvent(getScript()..":Tickets:Menu", function(data)
    local PlayerInfo = getPlayer()
    local hasItem, hasTable = hasItem("payticket", 1)
    if not hasItem then
        triggerNotify(nil, locale("error" ,"no_ticket"), "error")
        return
    end
    local amount, sellable, name, label = hasTable["payticket"].count, false, "", ""
	for k, v in pairs(Config.Receipts.Jobs) do
        sellable = (data.gang and v.gang and k == PlayerInfo.gang) or (not data.gang and not v.gang and k == PlayerInfo.job)
        if sellable then name, label = k, (data.gang and Gangs[PlayerInfo.gang].label) or (not data.gang and Jobs[PlayerInfo.job].label) break end
    end
    if sellable then local Menu = {}
        Menu[#Menu+1] = {
            isMenuHeader = true,
            txt = locale("menu" ,"ticket_amount")..amount..locale("menu" ,"total_pay")..(Config.Receipts.Jobs[name].PayPerTicket * amount)
        }
        Menu[#Menu+1] = {
            icon = "fas fa-circle-check", header = locale("menu" ,"yes"),
            onSelect = function()
                TriggerServerEvent(getScript()..":Tickets:Sell")
                playAnim("pickup_object", "putdown_low", 2000, 1)
            end,
        }
        openMenu(Menu, { header = "🧾 "..label..locale("menu" ,"receipt"), headertxt = locale("menu" ,"trade_confirm"), canClose = true, })
    end
end)