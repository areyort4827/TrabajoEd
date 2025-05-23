local QBCore = exports['qb-core']:GetCoreObject()
local menuOpen = false

-- Abrir menú principal (F6 o comando)
RegisterCommand("policia", function()
    toggleMenu()
end)

RegisterKeyMapping("policia", "Abrir menú policial", "keyboard", "F6")

function toggleMenu()
    menuOpen = not menuOpen
    SetNuiFocus(menuOpen, menuOpen)
    SendNUIMessage({ action = menuOpen and "openUI" or "closeUI" })
end

-- Cerrar desde NUI
RegisterNUICallback("closeUI", function(_, cb)
    SetNuiFocus(false, false)
    menuOpen = false
    cb("ok")
end)

-- Redirección de módulos
RegisterNUICallback("loadModule", function(data, cb)
    local mod = data.module
    if mod == "radio" then
        openRadio()
    elseif mod == "camaras" then
        openCamaras()
    elseif mod == "ciudadanos" then
        openCiudadanos()
    elseif mod == "reportes" then
        openReportes()
    elseif mod == "penal" then
        openPenal()
    elseif mod == "evidencia" then
        openEscena()
    elseif mod == "k9" then
        openK9Menu()
    end
    cb("ok")
end)

-- Funciones para abrir módulos
-- funcion Radio
function openRadio()
    local frecs = {
        [1] = {label = "Patrulla Central", code = "PC-001"},
        [2] = {label = "Táctico", code = "TAC-002"},
        [3] = {label = "Intervenciones", code = "INT-003"},
    }

    QBCore.Functions.Notify("Selecciona una frecuencia vía comando /radiofrecuencia [número]", "primary")
    for k, v in pairs(frecs) do
        print(("[%d] %s - %s"):format(k, v.label, v.code))
    end
end

RegisterCommand("radiofrecuencia", function(_, args)
    local freq = tonumber(args[1])
    if not freq then return end
    TriggerServerEvent('police_radio:setFrequency', freq)
    QBCore.Functions.Notify("Conectado a frecuencia " .. freq, "success")
end)

local cam = nil

-- funcion camaras
function openCamaras()
    local cameras = {
        {label = "Banco Central", coords = vector3(253.47, 228.58, 101.68), heading = 250.0},
        {label = "MRPD", coords = vector3(441.6, -981.9, 30.6), heading = 180.0}
    }

    QBCore.Functions.Notify("Usa /camara [1-" .. #cameras .. "] para ver cámaras", "primary")
    for i, cam in pairs(cameras) do
        print("[" .. i .. "] " .. cam.label)
    end

    RegisterCommand("camara", function(_, args)
        local index = tonumber(args[1])
        local data = cameras[index]
        if not data then return end

        if cam then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(cam, false)
        end

        local coords = data.coords + vector3(0.0, 0.0, 1.0)
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(cam, coords.x, coords.y, coords.z)
        SetCamRot(cam, -20.0, 0.0, data.heading)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
    end)
end

-- funcion ciudadanos
function openCiudadanos()
    ExecuteCommand("ciudadanos")
end

-- funcion reportes
function openReportes()
    ExecuteCommand("reportes")
end

-- funcion penal
function openPenal()
    ExecuteCommand("codigo")
end

-- funcion escena
function openEscena()
    ExecuteCommand("escena")
end

-- funcion k9
function openK9Menu()
    QBCore.Functions.Notify("Usa /k9, /k9seguir, /k9sentarse, /k9buscar, /k9atacar", "primary")
end

local k9 = nil

RegisterCommand("k9", function()
    if DoesEntityExist(k9) then
        DeleteEntity(k9)
        QBCore.Functions.Notify("K9 guardado", "error")
        return
    end

    local model = GetHashKey("a_c_shepherd")
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local coords = GetEntityCoords(PlayerPedId())
    k9 = CreatePed(28, model, coords.x + 1.0, coords.y, coords.z, 0.0, true, true)
    SetEntityAsMissionEntity(k9, true, true)
    SetBlockingOfNonTemporaryEvents(k9, true)
    QBCore.Functions.Notify("K9 invocado", "success")
end)

RegisterCommand("k9seguir", function()
    if not DoesEntityExist(k9) then return end
    TaskFollowToOffsetOfEntity(k9, PlayerPedId(), 0.0, -1.5, 0.0, 2.0, -1, 1.0, true)
end)

RegisterCommand("k9sentarse", function()
    if not DoesEntityExist(k9) then return end
    ClearPedTasks(k9)
    TaskStartScenarioInPlace(k9, "WORLD_DOG_SITTING", 0, true)
end)

RegisterCommand("k9buscar", function()
    if not DoesEntityExist(k9) then return end
    local pos = GetEntityCoords(PlayerPedId())
    TaskWanderInArea(k9, pos.x, pos.y, pos.z, 20.0, 10.0, 10.0)
end)

RegisterCommand("k9atacar", function()
    local target = GetPlayerPed(GetClosestPlayer())
    if not DoesEntityExist(k9) or target == PlayerPedId() or target == 0 then return end
    ClearPedTasks(k9)
    TaskPutPedDirectlyIntoMelee(k9, target, 0.0, -1.0, 0.0, false)
end)

function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDist = -1
    local closestPlayer = -1
    local pCoords = GetEntityCoords(PlayerPedId())

    for _, id in ipairs(players) do
        local tgt = GetPlayerPed(id)
        if tgt ~= PlayerPedId() then
            local dist = #(GetEntityCoords(tgt) - pCoords)
            if closestDist == -1 or dist < closestDist then
                closestDist = dist
                closestPlayer = id
            end
        end
    end
    return closestPlayer
end

-- bodycam
local enServicio = false

RegisterCommand("servicio", function()
    enServicio = not enServicio
    TriggerServerEvent("police_cameras:setServiceStatus", enServicio)
    QBCore.Functions.Notify("Estás " .. (enServicio and "EN" or "FUERA DE") .. " servicio", "success")
end)

-- radar
local radarActivo = false

RegisterCommand("radar", function()
    radarActivo = not radarActivo
    QBCore.Functions.Notify(radarActivo and "Radar activado" or "Radar desactivado", "info")
end)

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if radarActivo then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                local pos = GetEntityCoords(veh)
                local forwardVeh = GetClosestVehicle(pos + GetEntityForwardVector(veh) * 20.0, 15.0, 0, 70)
                if forwardVeh then
                    local speed = GetEntitySpeed(forwardVeh) * 3.6
                    local plate = GetVehicleNumberPlateText(forwardVeh)
                    QBCore.Functions.Notify("Vehículo detectado: " .. plate .. " - " .. math.floor(speed) .. " km/h", "primary")
                end
            end
        end
    end
end)