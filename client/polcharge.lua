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

    elseif Config.General.lookAtCharge then
        local selectedPed = nil
        local highlightedPed = nil
        local running = true

        CreateThread(function()
            while running do
                Wait(0)

                -- Raycast to get entity being looked at
                local camCoord = GetGameplayCamCoord()
                local direction = RotationToDirection(GetGameplayCamRot(2))
                local targetCoord = camCoord + direction * 6.0

                local hit, _ , hitCoords, _, entityHit = PerformRaycast(camCoord, targetCoord, PlayerPedId(), 4)
                if hit then
                    DrawSphere(hitCoords.x, hitCoords.y, hitCoords.z, 0.05, 0, 0, 255, 0.5)
                end
                if entityHit and IsEntityAPed(entityHit) and entityHit ~= PlayerPedId() then
                    if highlightedPed ~= entityHit then
                        if highlightedPed and DoesEntityExist(highlightedPed) then
                            SetEntityAlpha(highlightedPed, 255, false)
                            ResetEntityAlpha(highlightedPed)
                        end
                        highlightedPed = entityHit
                        SetEntityAlpha(highlightedPed, 200, false)
                    end
                elseif highlightedPed then
                    SetEntityAlpha(highlightedPed, 255, false)
                    ResetEntityAlpha(highlightedPed)
                    highlightedPed = nil
                end

                local loc = vec2(0.89+0.037, 0.9)
                DrawSprite("timerbars", "all_black_bg", loc.x, loc.y, 0.12, 0.05, 0.0, 255, 255, 255, 255)
                SetTextScale(0.80, 0.80)
                SetTextWrap(0.75, 0.985)
                SetTextJustification(2)
                SetTextFont(4)
                SetTextColour(255, 255, 255, 255)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringKeyboardDisplay(highlightedPed and "~s~Selected ID: ~b~"..GetPlayerServerId(NetworkGetPlayerIndexFromPed(highlightedPed)) or "~s~No Selection")
                EndTextCommandDisplayText(loc.x+0.06, loc.y - 0.026)

                -- Show instructional UI
                local buttons = {
                    { keys = { 194 }, text = "Cancel" }
                }
                if highlightedPed then
                    table.insert(buttons, { keys = { 86, 191 }, text = "Confirm" })
                end
                makeInstructionalButtons(buttons)

                -- Handle controls
                if IsControlJustPressed(0, 194) then -- Backspace
                    if highlightedPed then
                        SetEntityAlpha(highlightedPed, 255, false)
                        ResetEntityAlpha(highlightedPed)
                    end
                    running = false
                    return
                end

                if highlightedPed and (IsControlJustPressed(0, 191) or IsControlJustPressed(0, 86)) then
                    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(highlightedPed))
                    if serverId then
                        running = false
                        SetEntityAlpha(highlightedPed, 255, false)
                        ResetEntityAlpha(highlightedPed)

                        local newinputs = {
                            {
                                type = 'select',
                                name = 'billtype',
                                text = locale("menu", "type"),
                                default = billPrev,
                                options = {
                                    { value = "cash", text = locale("menu", "cash"), label = locale("menu", "cash") },
                                    { value = "bank", text = locale("menu", "card"), label = locale("menu", "card") }
                                }
                            },
                            {
                                type = 'number',
                                isRequired = true,
                                name = 'price',
                                text = locale("menu", "amount_charge")
                            }
                        }

                        local dialog = createInput(Jobs[getPlayer().job].label, newinputs)

                        if dialog then
                            -- If ox_menu style input, fix indexes
                            if dialog[1] then
                                dialog.billtype = dialog[1]
                                dialog.price = dialog[2]
                            end

                            billPrev = dialog.billtype

                            TriggerServerEvent(getScript()..":server:PolCharge", serverId, dialog.price)

                        end
                    end
                end
            end
        end)
        return -- Skip continuing function until selection is made

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

RegisterNetEvent(getScript()..":client:PolPopup", function(amount, biller, billerjob, commPercent)
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
                commPercent = commPercent,
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