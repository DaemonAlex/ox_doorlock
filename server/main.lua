local QBCore = nil

-- Check for QBCore
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

if not QBCore then
    print('Warning: no compatible framework was loaded, most features will not work')
    return
end

---@type table<number, EntityInterface>
local entityStates = {}

---@param netId number
RegisterNetEvent('ox_target:setEntityHasOptions', function(netId)
    local entity = Entity(NetworkGetEntityFromNetworkId(netId))
    entity.state.hasTargetOptions = true
    entityStates[netId] = entity
end)

---@param netId number
---@param door number
RegisterNetEvent('ox_target:toggleEntityDoor', function(netId, door)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end

    local owner = NetworkGetEntityOwner(entity)
    TriggerClientEvent('ox_target:toggleEntityDoor', owner, netId, door)
end)

CreateThread(function()
    local arr = {}
    local num = 0

    while true do
        Wait(10000)

        for netId, entity in pairs(entityStates) do
            if not DoesEntityExist(entity.__data) or not entity.state.hasTargetOptions then
                entityStates[netId] = nil
                num += 1

                arr[num] = netId
            end
        end

        if num > 0 then
            TriggerClientEvent('ox_target:removeEntity', -1, arr)
            table.wipe(arr)
            num = 0
        end
    end
end)

-- Example of using QBCore functions
QBCore.Functions.CreateCallback('ox_doorlock:getDoorState', function(source, cb, doorId)
    -- Your code to get the door state
end)

-- Add your server-side logic here

local function setDoorState(source, id, state, authorised)
    local door = doors[id]

    if door then
        if door.state ~= state then
            door.state = state

            if door.auto then
                CreateThread(function()
                    Wait(door.auto)

                    if door.state == state then
                        door.state = 1

                        TriggerClientEvent('ox_doorlock:setState', -1, id, door.state)
                        TriggerEvent('ox_doorlock:stateChanged', nil, door.id, door.state == 1)
                    end
                end)
            end

            TriggerEvent('ox_doorlock:stateChanged', source, door.id, state == 1,
                type(authorised) == 'string' and authorised)

            return true
        end

        if source then
            lib.notify(source,
                { type = 'error', icon = 'lock', description = state == 0 and 'cannot_unlock' or 'cannot_lock' })
        end
    end

    return false
end

RegisterNetEvent('ox_doorlock:setState', setDoorState)
exports('setDoorState', setDoorState)

lib.callback.register('ox_doorlock:getDoors', function()
    while not isLoaded do Wait(100) end

    return doors, sounds
end)

RegisterNetEvent('ox_doorlock:editDoorlock', function(id, data)
    if IsPlayerAceAllowed(source, 'command.doorlock') then
        if data then
            if not data.coords then
                local double = data.doors
                data.coords = double[1].coords - ((double[1].coords - double[2].coords) / 2)
            end

            if not data.name then
                data.name = tostring(data.coords)
            end

            doors[id] = data
            TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, data)
        else
            doors[id] = nil
            TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, false)
        end
    end
end)
