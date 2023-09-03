QBCore = exports['qb-core']:GetCoreObject()

local time = 1000
function loadModel(model) if not HasModelLoaded(model) then
	if Config.Debug then print("^5Debug^7: ^2Loading Model^7: '^6"..model.."^7'") end
	while not HasModelLoaded(model) do
		if time > 0 then time -= 1 RequestModel(model)
		else time = 1000 print("^5Debug^7: ^3LoadModel^7: ^2Timed out loading model ^7'^6"..model.."^7'") break
		end
		Wait(10)
	end
end end
function unloadModel(model) if Config.Debug then print("^5Debug^7: ^2Removing Model^7: '^6"..model.."^7'") end SetModelAsNoLongerNeeded(model) end
function loadAnimDict(dict)	if not HasAnimDictLoaded(dict) then if Config.Debug then print("^5Debug^7: ^2Loading Anim Dictionary^7: '^6"..dict.."^7'") end while not HasAnimDictLoaded(dict) do RequestAnimDict(dict) Wait(5) end end end
function unloadAnimDict(dict) if Config.Debug then print("^5Debug^7: ^2Removing Anim Dictionary^7: '^6"..dict.."^7'") end RemoveAnimDict(dict) end
function loadPtfxDict(dict)	if not HasNamedPtfxAssetLoaded(dict) then if Config.Debug then print("^5Debug^7: ^2Loading Ptfx Dictionary^7: '^6"..dict.."^7'") end while not HasNamedPtfxAssetLoaded(dict) do RequestNamedPtfxAsset(dict) Wait(5) end end end
function unloadPtfxDict(dict) if Config.Debug then print("^5Debug^7: ^2Removing Ptfx Dictionary^7: '^6"..dict.."^7'") end RemoveNamedPtfxAsset(dict) end

function lookEnt(entity)
	if type(entity) == "vector3" then
		if not IsPedHeadingTowardsPosition(PlayerPedId(), entity, 10.0) then
			TaskTurnPedToFaceCoord(PlayerPedId(), entity, 1500)
			if Config.Debug then print("^5Debug^7: ^2Turning Player to^7: '^6"..json.encode(entity).."^7'") end
			Wait(1500)
		end
	else
		if DoesEntityExist(entity) then
			if not IsPedHeadingTowardsPosition(PlayerPedId(), GetEntityCoords(entity), 30.0) then
				TaskTurnPedToFaceCoord(PlayerPedId(), GetEntityCoords(entity), 1500)
				if Config.Debug then print("^5Debug^7: ^2Turning Player to^7: '^6"..entity.."^7'") end
				Wait(1500)
			end
		end
	end
end

function destroyProp(entity)
	if Config.Debug then print("^5Debug^7: ^2Destroying Prop^7: '^6"..entity.."^7'") end
	SetEntityAsMissionEntity(entity) Wait(5)
	DetachEntity(entity, true, true) Wait(5)
	DeleteObject(entity)
end

function makeProp(data, freeze, synced)
    loadModel(data.prop)
    local prop = CreateObject(data.prop, data.coords.x, data.coords.y, data.coords.z, synced or false, synced or false, 0)
    SetEntityHeading(prop, data.coords.w+180.0)
    FreezeEntityPosition(prop, freeze or 0)
    if Config.Debug then print("^5Debug^7: ^6Prop ^2Created ^7: '^6"..prop.."^7'") end
    return prop
end

function makePed(model, coords, freeze, collision, scenario, anim)
	loadModel(model)
	local ped = CreatePed(0, model, coords.x, coords.y, coords.z-1.03, coords.w, false, false)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, freeze or true)
    if collision then SetEntityNoCollisionEntity(ped, PlayerPedId(), false) end
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    if anim then
        loadAnimDict(anim[1])
        TaskPlayAnim(ped, anim[1], anim[2], 1.0, 1.0, -1, 1, 0.2, 0, 0, 0)
    end
	if Config.Debug then print("^5Debug^7: ^6Ped ^2Created for location^7: '^6"..model.."^7'") end
    return ped
end

function makeBlip(data)
	local blip = AddBlipForCoord(data.coords)
	SetBlipAsShortRange(blip, true)
	SetBlipSprite(blip, data.sprite or 1)
	SetBlipColour(blip, data.col or 0)
	SetBlipScale(blip, data.scale or 0.7)
	SetBlipDisplay(blip, (data.disp or 6))
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(tostring(data.name))
	EndTextCommandSetBlipName(blip)
	if Config.Debug then print("^5Debug^7: ^6Blip ^2created for location^7: '^6"..data.name.."^7'") end
    return blip
end

function triggerNotify(title, message, type, src)
	if Config.Notify == "okok" then
		if not src then	exports['okokNotify']:Alert(title, message, 6000, type or 'info')
		else TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type or 'info') end
	elseif Config.Notify == "qb" then
		if not src then	TriggerEvent("QBCore:Notify", message, "primary")
		else TriggerClientEvent("QBCore:Notify", src, message, "primary") end
	elseif Config.Notify == "t" then
		if not src then exports['t-notify']:Custom({title = title, style = type, message = message, sound = true})
		else TriggerClientEvent('t-notify:client:Custom', src, { style = type, duration = 6000, title = title, message = message, sound = true, custom = true}) end
	elseif Config.Notify == "infinity" then
		if not src then TriggerEvent('infinity-notify:sendNotify', message, type)
		else TriggerClientEvent('infinity-notify:sendNotify', src, message, type) end
	elseif Config.Notify == "rr" then
		if not src then exports.rr_uilib:Notify({msg = message, type = type, style = "dark", duration = 6000, position = "top-right", })
		else TriggerClientEvent("rr_uilib:Notify", src, {msg = message, type = type, style = "dark", duration = 6000, position = "top-right", }) end
	end
end

function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do a[#a+1] = n end
	table.sort(a)
	local i = 0
	local iter = function() i += 1 if a[i] == nil then return nil else return a[i], t[a[i]] end end
	return iter
end

function countTable(table) local i = 0 for keys in pairs(table) do i += 1 end return i end

function cv(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then break end
    end
    return formatted
end