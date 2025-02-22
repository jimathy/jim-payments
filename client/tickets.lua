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