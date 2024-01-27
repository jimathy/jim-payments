local BankPed = nil
local Till = {}

function spawnCustomRegisters()
	for k, v in pairs(Config.CustomCashRegisters) do
		for i = 1, #v do
			local job, gang = v[i].gang and nil or k, v[i].gang and k or nil
            createBoxTarget({"CustomRegister: "..k..i, v[i].coords.xyz, 0.47, 0.34, { name="CustomRegister: "..k..i, heading = v[i].coords[4], debugPoly=Config.Debug, minZ=v[i].coords.z-0.1, maxZ=v[i].coords.z+0.4}}, {
                { onSelect = function() TriggerEvent("jim-payments:client:Charge", { job = job, gang = gang, img = ""}) end, icon = "fas fa-credit-card", label = Loc[Config.Lan].target["charge"], }
            }, 2.0)
			if v[i].prop then makeProp({prop = "prop_till_03", coords = v[i].coords}, 1, false) end
		end
	end
end
onPlayerLoaded(function() spawnCustomRegisters() end)

--Keeps track of duty on script restarts
AddEventHandler('onResourceStart', function(r) if GetCurrentResourceName() ~= r then return end
    spawnCustomRegisters()
end)

local billPrev = "cash"
RegisterNetEvent('jim-payments:client:Charge', function(data, outside)
	--Check if player is using /cashregister command
	local dialog
	--if not outside and not onDuty and data.gang == nil then triggerNotify(nil, Loc[Config.Lan].error["not_onduty"], "error") return end
	local newinputs = {} -- Begin qb-input creation here.
    local nearbyList = {}
    if Config.General.List then -- If nearby player list is wanted:
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
	--Check if image was given when opening the regsiter
	local img = ""
    if Config.System.Menu == "qb" then
        img = "<center><img src="..(data.img and data.img or "").." width=200px></center>"
    elseif Config.System.Menu == "ox" then
        img = ""
    end
	--Grab Player Job name or Gang Name if needed
	local label = PlayerJob.label
	local gang = false
	if data.gang then label = PlayerGang.label gang = true end
    if Config.General.List then
        newinputs[#newinputs+1] = { type = "select", text = Loc[Config.Lan].menu["cus_id"], name = "citizen", label = Loc[Config.Lan].menu["cus_id"], default = 1, options = nearbyList }
    else
        newinputs[#newinputs+1] = { type = 'text', isRequired = true, name = 'citizen',  text = Loc[Config.Lan].menu["cus_id"] }
    end
    newinputs[#newinputs+1] = {
        type = 'select',
        name = 'billtype',
        text = Loc[Config.Lan].menu["type"],
        default = billPrev,
        options = {
            { value = "cash", text = Loc[Config.Lan].menu["cash"] },
            { value = "bank", text = Loc[Config.Lan].menu["card"] }
        }
    }
    newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = Loc[Config.Lan].menu["amount_charge"] }

    local dialog = createInput(img, newinputs)

	if dialog then
        if dialog[1] then
            dialog.citizen = dialog[1]
            dialog.billtype = dialog[2]
            dialog.price = dialog[3]
        end
        billPrev = dialog.billtype
        TriggerServerEvent('jim-payments:server:Charge', dialog.citizen, dialog.price, dialog.billtype, data.img, outside, gang)
    end
end)

RegisterNetEvent("jim-payments:client:PayPopup", function(amount, biller, billtype, img, billerjob, gang, outside)
    local setimage = ""
    if Config.System.Menu == "qb" then
        setimage = "<center><img src="..(img and img or "").." width=200px></center>"
    elseif Config.System.Menu == "ox" then
        setimage = '!['..''.. ']('..(img and img or "")..')'
    end

    local Menu = {}
    Menu[#Menu+1] = {
        isMenuHeader = true,
        header = "🧾 "..billerjob..Loc[Config.Lan].menu["payment"],
        txt = Loc[Config.Lan].menu["accept_payment"]
    }
    Menu[#Menu+1] = {
        isMenuHeader = true,
        header = "",
        txt = billtype:gsub("^%l", string.upper)..Loc[Config.Lan].menu["payment_amount"]..amount
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-check",
        header = Loc[Config.Lan].menu["yes"],
        txt = "",
        onSelect = function()
            TriggerServerEvent("jim-payments:server:PayPopup", {
                accept = true,
                amount = amount,
                biller = biller,
                billtype = billtype,
                outside = outside
            })
        end,
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-xmark",
        header = Loc[Config.Lan].menu["no"],
        onSelect = function()
            TriggerServerEvent("jim-payments:server:PayPopup", {
                accept = false,
                amount = amount,
                biller = biller,
                billtype = billtype,
                outside = outside
            })
        end,
    }
    openMenu(Menu, {
        header = setimage,
        onExit = function()
            TriggerServerEvent("jim-payments:server:PayPopup", {
                accept = false,
                amount = amount,
                biller = biller,
                billtype = billtype,
                outside = outside
            })
        end,
    })
end)