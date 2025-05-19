local BankPed = nil
local Till = {}

function spawnCustomRegisters()
    Wait(1000)
	for k, v in pairs(Config.CustomCashRegisters) do
		for i = 1, #v do
			local job, gang = v[i].gang and nil or k, v[i].gang and k or nil
            createBoxTarget({"CustomRegister: "..k..i, v[i].coords.xyz, 0.47, 0.34, { name="CustomRegister: "..k..i, heading = v[i].coords[4], debugPoly=debugMode, minZ=v[i].coords.z-0.1, maxZ=v[i].coords.z+0.4}}, {
                { onSelect = function() TriggerEvent(getScript()..":client:Charge", { job = job, gang = gang, img = ""}) end, icon = "fas fa-credit-card", label = locale("target", "charge"), }
            }, 2.0)
			if v[i].prop then makeProp({prop = "prop_till_03", coords = v[i].coords}, 1, false) end
		end
	end
end

onPlayerLoaded(function() spawnCustomRegisters() end, true)

RegisterNetEvent(getScript()..":client:Charge", function(data, outside)
    local billPrev = "cash"
	--if not outside and not onDuty and data.gang == nil then triggerNotify(nil, locale("error", "not_onduty") return end
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
		if not nearbyList[1] then
            triggerNotify(nil, locale("error" ,"no_one"), "error")
            return
        end

        newinputs[#newinputs+1] = {
            type = "select",
            text = locale("menu", "cus_id"),
            name = "citizen",
            label = locale("menu", "cus_id"),
            default = 1,
            options = nearbyList
        }
	else -- If Config.List is false, create input text box for ID's
		newinputs[#newinputs+1] = {
            type = 'text',
            isRequired = true,
            required = true,
            name = 'citizen',
            label = locale("menu", "cus_id"),
            text = locale("menu", "cus_id")
        }
	end

    local prop = nil
    if Config.General.Usebzzz then
        local Ped = PlayerPedId()
        prop = makeProp({ prop = 'bzzz_prop_payment_terminal', coords = vec4(0,0,0,0)}, false, true)
        AttachEntityToEntity(prop, Ped, GetPedBoneIndex(Ped, 57005), 0.17, 0.04, 0.01, 340.0, 200.0, 50.0, true, true, false, false, 1, true)
        playAnim('cellphone@', 'cellphone_text_read_base', -1, 49)
    end

	--Grab Player Job name or Gang Name if needed
    local getInfo = getPlayer()
	--Check if image was given when opening the regsiter
	local img = data.img ~= nil and (Config.System.Menu == "qb" and "<center><img src="..(data.img).." width=200px></center>") or Jobs[getInfo.job].label

    newinputs[#newinputs+1] = {
        type = 'select',
        name = 'billtype',
        text = locale("menu" ,"type"),
        default = billPrev,
        options = {
            { value = "cash", text = locale("menu" ,"cash"), label = locale("menu" ,"cash") },
            { value = "bank", text = locale("menu" ,"card"), label = locale("menu" ,"card") }
        }
    }
    newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'price', text = locale("menu" ,"amount_charge") }

    local dialog = createInput(img, newinputs)

	if dialog then
        if dialog[1] then   -- if ox menu, auto adjust values
            if dialog[1] == "" then
                TriggerEvent(getScript()..":client:Charge", data, outside)
                return
            end
            dialog.citizen = dialog[1]
            dialog.billtype = dialog[2]
            dialog.price = dialog[3]
        end
        billPrev = dialog.billtype
        TriggerServerEvent(getScript()..":server:Charge", dialog.citizen, dialog.price, dialog.billtype, data.img, outside, gang)
    end
    destroyProp(prop)
    stopAnim('cellphone@', 'cellphone_text_read_base')
end)

RegisterNetEvent(getScript()..":client:PayPopup", function(amount, biller, billtype, img, billerjob, gang, outside)
    local setimage = ""

    if not img then
        setimage = billerjob
    else
        if Config.System.Menu == "qb" then
            setimage = "<center><img src="..(img and img or "").." width=200px></center>"
        elseif Config.System.Menu == "ox" then
            setimage = '!['..''.. ']('..(img and img or "")..')'
        end
    end

    local Menu = {}
    Menu[#Menu+1] = {
        isMenuHeader = true,
        header = "🧾 "..locale("menu" ,"payment"),
        txt = locale("menu" ,"accept_payment")
    }
    Menu[#Menu+1] = {
        isMenuHeader = true,
        header = "",
        txt = billtype:gsub("^%l", string.upper)..locale("menu" ,"payment_amount")..amount
    }
    Menu[#Menu+1] = {
        icon = "fas fa-circle-check",
        header = locale("menu" ,"yes"),
        txt = "",
        onSelect = function()
            TriggerServerEvent(getScript()..":server:PayPopup", {
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
        header = locale("menu" ,"no"),
        onSelect = function()
            TriggerServerEvent(getScript()..":server:PayPopup", {
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
            TriggerServerEvent(getScript()..":server:PayPopup", {
                accept = false,
                amount = amount,
                biller = biller,
                billtype = billtype,
                outside = outside
            })
        end,
    })
end)