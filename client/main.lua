if not LoadResourceFile(cache.resource, 'web/build/index.html') then
    error('Unable to load UI. Build ox_doorlock or download the latest release.\n    ^3https://github.com/overextended/ox_doorlock/releases/latest/download/ox_doorlock.zip^0')
end

if not lib.checkDependency('ox_lib', '3.14.0', true) then return end

local QBCore = nil

-- Check for QBCore
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

if not QBCore then
    print('Warning: no compatible framework was loaded, most features will not work')
    return
end

local function createDoor(door)
    local double = door.doors
    door.zone = GetLabelText(GetNameOfZone(door.coords.x, door.coords.y, door.coords.z))

    if double then
        for i = 1, 2 do
            AddDoorToSystem(double[i].hash, double[i].model, double[i].coords.x, double[i].coords.y, double[i].coords.z, false, false, false)
            DoorSystemSetDoorState(double[i].hash, 4, false, false)
            DoorSystemSetDoorState(double[i].hash, door.state, false, false)

            if door.doorRate or not door.auto then
                DoorSystemSetAutomaticRate(double[i].hash, door.doorRate or 10.0, false, false)
            end
        end
    else
        AddDoorToSystem(door.hash, door.model, door.coords.x, door.coords.y, door.coords.z, false, false, false)
        DoorSystemSetDoorState(door.hash, 4, false, false)
        DoorSystemSetDoorState(door.hash, door.state, false, false)

        if door.doorRate or not door.auto then
            DoorSystemSetAutomaticRate(door.hash, door.doorRate or 10.0, false, false)
        end
    end
end

local nearbyDoors = {}
local Entity = Entity

lib.callback('ox_doorlock:getDoors', false, function(data)
    doors = data

    for _, door in pairs(data) do
        createDoor(door)
    end

    while true do
        table.wipe(nearbyDoors)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for id, door in pairs(doors) do
            if #(coords - door.coords) < 50.0 then
                nearbyDoors[id] = door
            end
        end

        Wait(1000)
    end
end)

RegisterNetEvent('ox_doorlock:setState', function(id, state)
    local door = doors[id]

    if door then
        door.state = state

        if door.doors then
            for i = 1, 2 do
                DoorSystemSetDoorState(door.doors[i].hash, state, false, false)
            end
        else
            DoorSystemSetDoorState(door.hash, state, false, false)
        end
    end
end)

RegisterNetEvent('ox_doorlock:editDoorlock', function(id, data)
    if data then
        doors[id] = data
        createDoor(data)
    else
        doors[id] = nil
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for id, door in pairs(nearbyDoors) do
            local distance = #(coords - door.coords)

            if distance < 1.5 then
                sleep = 0

                if IsControlJustReleased(0, 38) then
                    local state = door.state == 0 and 1 or 0
                    TriggerServerEvent('ox_doorlock:setState', id, state)
                end

                local text = door.state == 0 and '[E] Unlock' or '[E] Lock'
                lib.showTextUI(text, { position = "top-center", icon = 'lock' })
            end
        end

        Wait(sleep)
    end
end)
