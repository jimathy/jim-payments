RegisterNetEvent('jim-payments:Tickets:Menu', function(data)
    local hasItem, hasTable = hasItem("payticket", 1)
    if not hasItem then triggerNotify(nil, Loc[Config.Lan].error["no_ticket"], "error") return end
    local amount, sellable, name, label = hasTable["payticket"].count, false, "", ""
	for k, v in pairs(Config.Receipts.Jobs) do
        sellable = (data.gang and v.gang and k == PlayerGang.name) or (not data.gang and not v.gang and k == PlayerJob.name)
        if sellable then name, label = k, (data.gang and PlayerGang.label) or (not data.gang and PlayerJob.label) break end
    end
    if sellable then local Menu = {}
        Menu[#Menu+1] = {
            isMenuHeader = true,
            txt = Loc[Config.Lan].menu["ticket_amount"]..amount..Loc[Config.Lan].menu["total_pay"]..(Config.Receipts.Jobs[name].PayPerTicket * amount)
        }
        Menu[#Menu+1] = {
            icon = "fas fa-circle-check", header = Loc[Config.Lan].menu["yes"],
            onSelect = function() TriggerServerEvent('jim-payments:Tickets:Sell') end,
        }
        openMenu(Menu, { header = "🧾 "..label..Loc[Config.Lan].menu["receipt"], headertxt = Loc[Config.Lan].menu["trade_confirm"], canClose = true, })
    end
end)