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

    for _, job in pairs(Jobs) do
        if isStarting then
            if job.stashes then
                for _, stash in pairs(job.stashes) do
                    BRIDGE.RegisterStash(stash.id, stash.label, stash.slots, stash.weight)
                end
            else
                job.stashes = {}
            end
        end
        if job.type == "job" then
            dataJobs[job.job] = {
                label = job.label,
                type = job.jobtype,
                defaultDuty = true,
                offDutyPay = false,
                grades = decodeGrades(job.grades)
            }
            exports.qbx_core:CreateJobs({
                [job.job] = dataJobs[job.job]
            })
        elseif job.type == "gang" then
            dataJobs[job.job] = {
                label = job.label,
                grades = decodeGrades(job.grades)
            }
            exports.qbx_core:CreateGangs({
                [job.job] = dataJobs[job.job]
            })
        end
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

RegisterServerEvent('QBCore:Server:OnPlayerLoaded', function()
    LoadJobs(true)
end)

AddEventHandler(GetCurrentResourceName() .. ':playerLoaded', function(playerId)
    LoadJobs(true)
    Wait(2000)
    TriggerClientEvent("mri_Qjobsystem:client:receiveJobs", playerId, Jobs)
end)

local function SaveJobs()
    DB.SaveJobs(Jobs)
    LoadJobs()
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

RegisterNetEvent("mri_Qjobsystem:server:saveNewJob")
AddEventHandler("mri_Qjobsystem:server:saveNewJob", function(jobData)
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
                SaveJobs()
            else
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        Jobs[i] = jobData
                        SaveJobs()
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

RegisterNetEvent("mri_Qjobsystem:server:saveJob")
AddEventHandler("mri_Qjobsystem:server:saveJob", function(jobData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            if IsJobExist(jobData.job) then
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        Jobs[i] = jobData
                        SaveJobs()
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

RegisterNetEvent("mri_Qjobsystem:server:deleteJob")
AddEventHandler("mri_Qjobsystem:server:deleteJob", function(jobData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            if IsJobExist(jobData.job) then
                for i, v in pairs(Jobs) do
                    if v.job == jobData.job then
                        table.remove(Jobs, i)
                        SaveJobs()
                        lib.notify(src, {
                            title = "Sucesso",
                            description = "O grupo foi excluído!",
                            type = "success"
                        })
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

RegisterNetEvent("mri_Qjobsystem:server:pullChanges")
AddEventHandler("mri_Qjobsystem:server:pullChanges", function(pullType)
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

RegisterNetEvent("mri_Qjobsystem:server:createItem")
AddEventHandler("mri_Qjobsystem:server:createItem", function(craftingData)
    local src = source
    if CanTrustPlayer(src) then
        if IsPlayerHasCustomPerms(src) then
            local hasAllItems = true
            for _, v in pairs(craftingData.ingedience) do
                if v.itemCount > BRIDGE.GetItemCount(src, v.itemName) then
                    hasAllItems = false
                end
            end
            if hasAllItems then
                for _, v in pairs(craftingData.ingedience) do
                    BRIDGE.RemoveItem(src, v.itemName, v.itemCount)
                end
                BRIDGE.AddItem(src, craftingData.itemName, craftingData.itemCount)
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

RegisterNetEvent("mri_Qjobsystem:server:makeRegisterAction")
AddEventHandler("mri_Qjobsystem:server:makeRegisterAction", function(jobName, action, number)
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
                            SaveJobs()
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
                            SaveJobs()
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

RegisterNetEvent("mri_Qjobsystem:server:createBackup")
AddEventHandler("mri_Qjobsystem:server:createBackup", function(pullType)
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

RegisterNetEvent("mri_Qjobsystem:server:setBackup")
AddEventHandler("mri_Qjobsystem:server:setBackup", function(pullType)
    local src = source
    if CanTrustPlayer(src) then
        local loadFile = LoadResourceFile(GetCurrentResourceName(), "./server/backup.json")
        if loadFile then
            Jobs = json.decode(loadFile)
            SaveJobs()
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
