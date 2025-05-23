local QBCore = exports['qb-core']:GetCoreObject()
local agentsOnDuty = {}

-- 🔁 Servicio activo (bodycams)
RegisterNetEvent("police_cameras:setServiceStatus", function(state)
    local src = source
    if state then
        agentsOnDuty[src] = true
    else
        agentsOnDuty[src] = nil
    end
end)

-- 📡 Frecuencia de radio
RegisterNetEvent('police_radio:setFrequency', function(freq)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        print(('Jugador %s se conectó a frecuencia %s'):format(Player.PlayerData.name, freq))
    end
end)

-- 👤 Base de datos de ciudadanos
QBCore.Functions.CreateCallback("police_citizens:getCitizen", function(_, cb, query)
    local result = MySQL.query.await('SELECT * FROM players WHERE name LIKE ? OR citizenid = ? OR id = ?', {
        '%' .. query .. '%', query, tonumber(query)
    })

    if result and result[1] then
        local citizen = result[1]
        local licenses = MySQL.query.await('SELECT * FROM user_licenses WHERE citizenid = ?', { citizen.citizenid })
        local notes = MySQL.query.await('SELECT * FROM citizen_notes WHERE citizenid = ?', { citizen.citizenid })
        citizen.licenses = licenses or {}
        citizen.notes = notes[1] or { photo = nil, note = "", alert = false }
        cb(citizen)
    else
        cb(nil)
    end
end)

RegisterNetEvent("police_citizens:updateCitizenNotes", function(data)
    local cid = data.citizenid
    if not cid then return end

    local result = MySQL.query.await('SELECT * FROM citizen_notes WHERE citizenid = ?', { cid })

    if result[1] then
        MySQL.update('UPDATE citizen_notes SET note = ?, photo = ?, alert = ? WHERE citizenid = ?', {
            data.note, data.photo, data.alert, cid
        })
    else
        MySQL.insert('INSERT INTO citizen_notes (citizenid, note, photo, alert) VALUES (?, ?, ?, ?)', {
            cid, data.note, data.photo, data.alert
        })
    end
end)

-- 📋 Reportes policiales
RegisterNetEvent("police_reports:createReport", function(data)
    local src = source
    local officer = GetPlayerName(src)

    MySQL.insert('INSERT INTO police_reports (title, description, evidence, tags, citizenid, officer) VALUES (?, ?, ?, ?, ?, ?)', {
        data.title,
        data.description,
        data.evidence,
        data.tags,
        data.citizenid or nil,
        officer
    })
end)

QBCore.Functions.CreateCallback("police_reports:getAllReports", function(_, cb)
    local result = MySQL.query.await('SELECT * FROM police_reports ORDER BY date DESC LIMIT 50', {})
    cb(result or {})
end)

-- ⚖️ Código penal
QBCore.Functions.CreateCallback("penal_code:getAll", function(_, cb)
    local result = MySQL.query.await('SELECT * FROM penal_code ORDER BY chapter, id', {})
    cb(result or {})
end)

RegisterNetEvent("penal_code:save", function(data)
    if data.id then
        MySQL.update('UPDATE penal_code SET chapter = ?, title = ?, description = ?, fine = ?, jail_time = ? WHERE id = ?', {
            data.chapter, data.title, data.description, data.fine, data.jail_time, data.id
        })
    else
        MySQL.insert('INSERT INTO penal_code (chapter, title, description, fine, jail_time) VALUES (?, ?, ?, ?, ?)', {
            data.chapter, data.title, data.description, data.fine, data.jail_time
        })
    end
end)

RegisterNetEvent("penal_code:delete", function(id)
    MySQL.query('DELETE FROM penal_code WHERE id = ?', { id })
end)

-- 📡 Bodycams
QBCore.Functions.CreateCallback("police_cameras:getAgents", function(_, cb)
    local list = {}
    for src, _ in pairs(agentsOnDuty) do
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            table.insert(list, {
                id = src,
                name = Player.PlayerData.name
            })
        end
    end
    cb(list)
end)
