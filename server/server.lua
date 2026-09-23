local Jobs = {}
local dataJobs = {}

local function decodeGrades(grades)
    local result = {}
    local count = -1
    local newboss = {}
    for k, v in pairs(grades) do
        count = count + 1
    end

    for k, v in pairs(grades) do
        if tonumber(k) == tonumber(count) then
            newboss = v
            newboss.isboss = true
            newboss.bankAuth = true
            result[tonumber(k)] = newboss
        else
            result[tonumber(k)] = v
        end
    end
    return result
end

local function BuildGroupData(job)
    if job.type == "job" then
        return {
            label = job.label,
            type = job.jobtype,
            defaultDuty = job.defaultDuty,
            offDutyPay = false,
            grades = decodeGrades(job.grades)
        }
    elseif job.type == "gang" then
        return {
            label = job.label,
            grades = decodeGrades(job.grades)
        }
    end
end

local function PushGroup(job)
    if type(job) ~= "table" or type(job.job) ~= "string" or type(job.grades) ~= "table" then
        return
    end

    local data = BuildGroupData(job)
    if not data then return end

    dataJobs[job.job] = data

    if job.type == "job" then
        exports.qbx_core:CreateJob(job.job, data)
    else
        exports.qbx_core:CreateGangs({
            [job.job] = data
        })
    end
end

local function IsManagedGroup(name)
    for _, job in pairs(Jobs) do
        if job.job == name then return true end
    end
    return false
end

-- Ajusta os grupos que vêm do shared/ do qbx_core (upstream) para o padrão MRI
local function ApplyQboxDefaults()
    if Config.RemoveQboxDefaultGroups then
        for _, name in ipairs(Config.QboxDefaultJobs) do
            if not IsManagedGroup(name) and exports.qbx_core:GetJob(name) then
                exports.qbx_core:RemoveJob(name)
            end
        end

        for _, name in ipairs(Config.QboxDefaultGangs) do
            if not IsManagedGroup(name) and exports.qbx_core:GetGang(name) then
                exports.qbx_core:RemoveGang(name)
            end
        end
    end

    exports.qbx_core:CreateJobs(Config.QboxBaseJobs)
    exports.qbx_core:CreateGangs(Config.QboxBaseGangs)
end

local function LoadJobs(isStarting)
    if isStarting then
        DB.CreateTable()
    end

    local data = DB.FetchJobs()
    if #data <= 0 then
        local loadFile = LoadResourceFile(GetCurrentResourceName(), "./server/jobs.json")
        Jobs = json.decode(loadFile) or {}

        DB.InsertJobs(Jobs)
    else
        Jobs = json.decode(data[1].jobs)
    end

    ApplyQboxDefaults()

    for _, job in pairs(Jobs) do
        if isStarting then
            if job.stashes then
                for _, stash in pairs(job.stashes) do
                    BRIDGE.RegisterStash(stash.id, stash.label, stash.slots, stash.weight)
                end
            else
                job.stashes = {}
            end

            Citizen.CreateThread(function()
                for k, v in pairs(job.craftings) do
                    local shopItems = {}

                    for _, item in ipairs(v.items) do
                        table.insert(shopItems, {
                            name = item.itemName,
                            price = item.ingedience[1].itemCount or 0,
                            currency = item.ingedience[1].itemName,
                            count = item.stockAmount,
                            license = item.license,
                            metadata = item.metadata,
                            grade = item.grade
                        })
                    end
                    exports.ox_inventory:RegisterShop(v.id, {
                        name = v.label,
                        inventory = shopItems,
                    })

                end
            end)

        end
        PushGroup(job)
    end
    if isStarting then
        Wait(2000)
        TriggerClientEvent("mri_Qjobsystem:client:receiveJobs", -1, Jobs)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        LoadJobs(true)
    end
end)

local lastJobsPush = {}

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local now = GetGameTimer()

    if lastJobsPush[src] and now - lastJobsPush[src] < 2000 then return end
    lastJobsPush[src] = now

    Wait(2000)
    TriggerClientEvent("mri_Qjobsystem:client:receiveJobs", src, Jobs)
end)

AddEventHandler('playerDropped', function()
    lastJobsPush[source] = nil
end)

AddEventHandler(GetCurrentResourceName() .. ':playerLoaded', function(playerId)
    TriggerClientEvent("mri_Qjobsystem:client:receiveJobs", playerId, Jobs)
end)

local function SaveJobs(changedJob)
    DB.SaveJobs(Jobs)

    if changedJob then
        PushGroup(changedJob)
    end
end

local function IsJobExist(jobName)
    for _, job in pairs(Jobs) do
        if job.job == jobName then
            return true
        end
    end
    return false
end

local function IsPlayerHasCustomPerms(playerId)
    -- THIS IS FOR YOUR CUSTOM PERMS
    return true
end

lib.callback.register('mri_Qjobsystem:server:getBalance', function(source, jobName)
    for _, job in pairs(Jobs) do
        if job.job == jobName then
            if not job.balance then
                job.balance = 0
            end
            return job.balance
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:saveNewJob", function(jobData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            if not IsJobExist(jobData.job) then
                table.insert(Jobs, jobData)
                lib.notify(src, {
                    title = "Sucesso",
                    description = "Um novo trabalho foi criado!",
                    type = "success"
                })
                SaveJobs(jobData)
            else
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        Jobs[i] = jobData
                        SaveJobs(jobData)
                        lib.notify(src, {
                            title = "Sucesso",
                            description = "O trabalho foi salvo!",
                            type = "success"
                        })
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:saveJob", function(jobData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            if IsJobExist(jobData.job) then
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        Jobs[i] = jobData
                        SaveJobs(jobData)
                        lib.notify(src, {
                            title = "Sucesso",
                            description = "O trabalho foi salvo!",
                            type = "success"
                        })
                    end
                end
            else
                lib.notify(src, {
                    title = "Erro",
                    description = "Alguém provavelmente já excluiu esse grupo :( ",
                    type = "error"
                })
            end
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:deleteJob", function(jobData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            if IsJobExist(jobData.job) then
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        table.remove(Jobs, i)
                        SaveJobs()

                        dataJobs[v.job] = nil
                        if v.type == "gang" then
                            exports.qbx_core:RemoveGang(v.job)
                        else
                            exports.qbx_core:RemoveJob(v.job)
                        end

                        lib.notify(src, {
                            title = "Sucesso",
                            description = "O grupo foi excluído!",
                            type = "success"
                        })
                        break
                    end
                end
            else
                lib.notify(src, {
                    title = "Erro",
                    description = "Este trabalho não existe!",
                    type = "error"
                })
            end
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:pullChanges", function(pullType)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            for _, job in pairs(Jobs) do
                if job.stashes then
                    for _, stash in pairs(job.stashes) do
                        BRIDGE.RegisterStash(stash.id, stash.label, stash.slots, stash.weight)
                    end
                else
                    job.stashes = {}
                end
            end
            if pullType == "creator" then
                TriggerClientEvent("mri_Qjobsystem:client:Pull", src, Jobs)
            elseif pullType == "all" then
                TriggerClientEvent("mri_Qjobsystem:client:Pull", -1, Jobs)
            end
        end
    end
end)

local function FindCrafting(craftingId)
    for _, job in pairs(Jobs) do
        for _, crafting in pairs(job.craftings or {}) do
            if crafting.id == craftingId then
                return crafting, job
            end
        end
    end
end

RegisterNetEvent("mri_Qjobsystem:server:createItem", function(craftingId, itemIndex, itemName, amount)
    local amount = tonumber(amount or 1)
    local src = source
    if not amount or amount < 1 or amount ~= math.floor(amount) then return end
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            local crafting, job = FindCrafting(craftingId)
            if not crafting then return end
            -- mesma regra do client: bancada com outro ícone é loja do ox_inventory
            if (crafting.icon or 'fa-solid fa-screwdriver-wrench') ~= 'fa-solid fa-screwdriver-wrench' then return end
            if not crafting.public and BRIDGE.GetPlayerJob(src) ~= job.job and BRIDGE.GetPlayerGang(src) ~= job.job then return end
            local craftingData = crafting.items and crafting.items[itemIndex]
            if type(craftingData) ~= "table" or craftingData.itemName ~= itemName or type(craftingData.ingedience) ~= "table" then return end
            local hasAllItems = true
            for _, v in pairs(craftingData.ingedience) do
                if v.itemCount * amount > BRIDGE.GetItemCount(src, v.itemName) then
                    hasAllItems = false
                end
            end
            if hasAllItems then
                for _, v in pairs(craftingData.ingedience) do
                    BRIDGE.RemoveItem(src, v.itemName, v.itemCount * amount)
                end
                BRIDGE.AddItem(src, craftingData.itemName, craftingData.itemCount * amount)
            else
                lib.notify(src, {
                    title = "Negado",
                    description = "Você não tem todos os itens!",
                    type = "error"
                })
            end
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:makeRegisterAction", function(jobName, action, number)
    local src = source
    if CanTrustPlayer(src) then
        if IsJobExist(jobName) then
            for _, job in pairs(Jobs) do
                if job.job == jobName then
                    if not job.balance then
                        job.balance = 0
                    end
                    if action == "withdraw" then
                        if job.balance > 0 and job.balance >= number and job.balance - number >= 0 then
                            job.balance = job.balance - number
                            BRIDGE.AddItem(src, "money", number)
                            lib.notify(src, {
                                title = "Retirar",
                                description = "Realizado com sucesso!!",
                                type = "success"
                            })
                            DB.SaveJobs(Jobs)
                        else
                            lib.notify(src, {
                                title = "Retirar",
                                description = "Não pode ser feito",
                                type = "error"
                            })
                        end
                    elseif action == "deposit" then
                        local playerMoney = BRIDGE.GetItemCount(src, "money")
                        if playerMoney >= number then
                            job.balance = job.balance + number
                            BRIDGE.RemoveItem(src, "money", number)
                            lib.notify(src, {
                                title = "Depósito",
                                description = "Realizado com sucesso!",
                                type = "success"
                            })
                            DB.SaveJobs(Jobs)
                        else
                            lib.notify(src, {
                                title = "Depósito",
                                description = "Você não tem dinheiro suficiente",
                                type = "error"
                            })
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:createBackup", function(pullType)
    local src = source
    if CanTrustPlayer(src) then
        SaveResourceFile(GetCurrentResourceName(), "./server/backup.json", json.encode(Jobs), -1)
        lib.notify(src, {
            title = "Backup feito com sucesso!",
            description = "Parabéns! Agora você pode fazer coisas estúpidas.",
            type = "success"
        })
    end
end)

RegisterNetEvent("mri_Qjobsystem:server:setBackup", function(pullType)
    local src = source
    if CanTrustPlayer(src) then
        local loadFile = LoadResourceFile(GetCurrentResourceName(), "./server/backup.json")
        if loadFile then
            Jobs = json.decode(loadFile)
            SaveJobs()
            for _, job in pairs(Jobs) do
                PushGroup(job)
            end
        end
    end
end)

lib.addCommand('createjob', {
    help = 'Este comando cria jobs e gangs',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent("mri_Qjobsystem:client:createjob", source)
end)

lib.addCommand('open_jobs', {
    help = 'Este comando abre seu menu de jobs e gangs.',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent("mri_Qjobsystem:client:openJobMenu", source, Jobs)
end)

----------------- updateJobGradePermission
lib.callback.register('mri_Qjobsystem:server:updateJobGradePermission', function(source, data, propName, key, maiorIndice)
    local jobEncontrado = nil
        jobEncontrado = data
    if not jobEncontrado then
        lib.notify(source, {
            description = 'Erro ao tentar alterar cargo, entre em contato com a Administração.',
            type = 'error',
            duration = 3000
        })
        return data
    end

    if propName == "isboss" and tostring(maiorIndice) == key then
        lib.notify(source, {
            description = 'Você não pode alterar o cargo do Líder.',
            type = 'error',
            duration = 3600
        })
        return data
    end
    jobEncontrado[propName] = not (jobEncontrado[propName] or false)
    data[propName] = jobEncontrado[propName]

    local changedJob
            for i, jobGradeItem in pairs(Jobs) do
                if jobGradeItem.label == data.label then
                    jobGradeItem.grades[key][propName] = data[propName]
                    changedJob = jobGradeItem
                break end
            end

    SaveJobs(changedJob)

    lib.notify(source, {
        description = 'Cargo atualizado com sucesso!',
        type = 'success',
        duration = 3600
    })

    if propName == "isrecruiter" then
        return data
    end

    local groupEntries = DB.FetchPlayersInGroup(data.groupName, data.groupType, tonumber(key))
        if next(groupEntries) == nil then
            return data
        end
    local setPlayerFunction
    if data.groupType == 'job' then
        setPlayerFunction = function(playerID, groupName)
            exports.qbx_core:SetPlayerPrimaryJob(playerID, groupName)
        end
    else
        setPlayerFunction = function(playerID, groupName)
            exports.qbx_core:SetPlayerPrimaryGang(playerID, groupName)
        end
    end
    for i = 1, #groupEntries do
        local citizenid = groupEntries[i].citizenid
        if exports.qbx_core:GetPlayerByCitizenId(citizenid) then
            setPlayerFunction(citizenid, data.groupName)
            Wait(80)
        end
    end
    return data
end)
