Jobs = {}
local Targets = {}
local Peds = {}
local items = BRIDGE.GetItems()

local function AddNewPed(pedData)
    table.insert(Peds, pedData)
end

local function generateCrafting(craftItems, label, icon)
    local options = {}
    local metadata = {}
    if craftItems then
        options = {}
        for _, k in pairs(craftItems) do
            metadata = {{
                label = "Itens requeridos",
                value = ""
            }}
            for _, l in pairs(k.ingedience) do
                local label = items[l.itemName].label
                if not items[l.itemName] then
                    print("[PLS] Error  ITEM NOT FOUND")
                end
                table.insert(metadata, {
                    label = label,
                    value = l.itemCount
                })
            end
            local count = 1
            if k.count then
                count = k.count
            end
            table.insert(options, {
                title = items[k.itemName].label .. " - " .. count .. " x",
                icon = Config.DirectoryToInventoryImages .. k.itemName .. ".png",
                image = Config.DirectoryToInventoryImages .. k.itemName .. ".png",
                onSelect = function()
                    local hasAllItems = true
                    for _, v in pairs(k.ingedience) do
                        if v.itemCount > BRIDGE.GetItemCount(v.itemName) then
                            hasAllItems = false
                        end
                    end
                    if hasAllItems then
                        local animData = {
                            anim = Config.DEFAULT_ANIM,
                            dict = Config.DEFAULT_ANIM_DIC
                        }
                        if k.animation then
                            if k.animation.dict and k.animation.anim then
                                animData = {
                                    anim = Config.DEFAULT_ANIM,
                                    dict = k.animation.dict
                                }
                            end
                        end
                        local label_progress = icon and "Fabricando" or "Comprando"
                        if lib.progressCircle({
                            duration = 10000,
                            label = label_progress .. ' ' .. items[k.itemName].label,
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true
                            },
                            anim = {
                                dict = animData.dict,
                                clip = animData.anim
                            }
                        }) then
                            TriggerSecureEvent("mri_Qjobsystem:server:createItem", k)
                        end
                    else
                        lib.notify({
                            title = "Erro",
                            description = "Você não tem todos os itens!",
                            type = "error"
                        })
                    end
                end,
                metadata = metadata
            })
        end
        lib.registerContext({
            id = "job_system_crafting",
            title = label,
            description = "Lista de itens",
            options = options
        })
        lib.showContext("job_system_crafting")
    end
end

local function openCashRegister(job)
    local cashBalance = lib.callback.await('mri_Qjobsystem:server:getBalance', 100, job)
    if cashBalance then
        lib.registerContext({
            id = "cash_register",
            title = "Caixa registradora",
            options = {{
                name = 'balance',
                icon = 'fa-solid fa-dollar',
                title = "Saldo: R$" .. cashBalance
            }, {
                name = 'withdraw',
                icon = 'fa-solid fa-arrow-down',
                title = "Retirar",
                -- groups = job.job,
                onSelect = function(data)
                    local input = lib.inputDialog('Crie um novo trabalho', {{
                        type = 'number',
                        label = 'Retirar',
                        description = 'Quanto você quer retirar?',
                        icon = 'hashtag',
                        min = 1
                    }})
                    if input then
                        TriggerSecureEvent("mri_Qjobsystem:server:makeRegisterAction", job, "withdraw", input[1])
                    end
                end
            }, {
                name = 'deposit',
                icon = 'fa-solid fa-arrow-up',
                title = "Depósito",
                -- groups = job.job,
                onSelect = function(data)
                    local input = lib.inputDialog('Crie um novo trabalho', {{
                        type = 'number',
                        label = 'Depósito',
                        description = 'Quanto você deseja depósito',
                        icon = 'hashtag',
                        min = 1
                    }})
                    if input then
                        TriggerSecureEvent("mri_Qjobsystem:server:makeRegisterAction", job, "deposit", input[1])
                    end
                end
            }}
        })
        lib.showContext("cash_register")
    end
end

local function GenerateCraftings()
    for _, job in pairs(Jobs) do
        for _, crafting in pairs(job.craftings) do
            local craftinglabel = crafting.label
            local targetId = BRIDGE.AddSphereTarget({
                coords = vector3(crafting.coords.x, crafting.coords.y, crafting.coords.z),
                options = {{
                    name = 'sphere',
                    icon = crafting.icon or 'fa-solid fa-screwdriver-wrench',
                    label = string.format("Abrir %s", crafting.label),
                    onSelect = function(data)
                        local jobname = BRIDGE.GetPlayerJob()
                        local gangname = BRIDGE.GetPlayerGang()

                        if crafting.public or (jobname == job.job) or (gangname == job.job) then
                            local icon = crafting.icon or 'fa-solid fa-screwdriver-wrench'
                            local type = (icon == 'fa-solid fa-screwdriver-wrench') and true or false

                            generateCrafting(crafting.items, craftinglabel, type)
                        else
                            lib.notify({
                                title = "Você não tem permissão",
                                description = "Você não pode usar isso.",
                                type = "error"
                            })
                        end
                    end
                }},
                debug = false,
                radius = 0.2
            })
            table.insert(Targets, targetId)
        end

        ------- ON DUTY
        if job.duty then
            local DutyRegister = BRIDGE.AddSphereTarget({
                coords = vector3(job.duty.x, job.duty.y, job.duty.z),
                options = {{
                    name = 'bell',
                    icon = 'fa-solid fa-briefcase',
                    label = "Bater ponto",
                    onSelect = function(data)
                        local jobname = BRIDGE.GetPlayerJob()
                        if jobname == job.job then
                            TriggerServerEvent("QBCore:ToggleDuty")
                        else
                            lib.notify({
                                title = "Você não tem permissão",
                                description = "Você não pode usar isso.",
                                type = "error"
                            })
                        end
                    end
                }},
                debug = false,
                radius = 0.2
            })
            table.insert(Targets, DutyRegister)
        end

        ------- CASH REGISTER

        if job.register then
            local CashRegister = BRIDGE.AddSphereTarget({
                coords = vector3(job.register.x, job.register.y, job.register.z),
                options = {{
                    name = 'bell',
                    icon = 'fa-solid fa-circle',
                    label = "Caixa registradora",
                    onSelect = function(data)
                        local jobname = BRIDGE.GetPlayerJob()
                        local gangname = BRIDGE.GetPlayerGang()

                        if jobname == job.job or gangname == job.job then
                            openCashRegister(job.job)
                        else
                            lib.notify({
                                title = "Você não tem permissão",
                                description = "Você não pode usar isso.",
                                type = "error"
                            })
                        end
                    end
                }},
                debug = false,
                radius = 0.2
            })
            table.insert(Targets, CashRegister)
        end

        ------- ALARM
        if job.alarm then
            local AlarmTarget = BRIDGE.AddSphereTarget({
                coords = vector3(job.alarm.x, job.alarm.y, job.alarm.z),
                options = {{
                    name = 'bell',
                    icon = 'fa-solid fa-circle',
                    label = "Alarme",
                    onSelect = function(data)
                        local jobname = BRIDGE.GetPlayerJob()
                        if jobname == job.job then
                            local alert = lib.alertDialog({
                                header = "Ligue para a polícia",
                                content = "Você realmente quer ligar para a polícia?",
                                centered = true,
                                cancel = true
                            })
                            if alert == "confirm" then
                                SendDispatch(GetEntityCoords(cache.ped), job.label)
                            end
                        else
                            lib.notify({
                                title = "Você não tem permissão",
                                description = "Você não pode usar isso.",
                                type = "error"
                            })
                        end
                    end
                }},
                debug = false,
                radius = 0.2
            })
            table.insert(Targets, AlarmTarget)
        end

        if job.bossmenu then
            local BossTarget = BRIDGE.AddSphereTarget({
                coords = vector3(job.bossmenu.x, job.bossmenu.y, job.bossmenu.z),
                options = {{
                    name = 'bell',
                    icon = 'fa-solid fa-laptop',
                    label = "Boss menu",
                    onSelect = function(data)
                        local jobname = BRIDGE.GetPlayerJob()
                        local gangname = BRIDGE.GetPlayerGang()
                        if jobname == job.job or gangname == job.job then
                            openBossmenu(job.type)
                        else
                            lib.notify({
                                title = "Você não tem permissão",
                                description = "Você não pode usar isso.",
                                type = "error"
                            })
                        end
                    end
                }},
                debug = false,
                radius = 0.2
            })
            table.insert(Targets, BossTarget)
        end

        if job.stashes then
            for _, stash in pairs(job.stashes) do
                local stashID = BRIDGE.AddSphereTarget({
                    coords = vector3(stash.coords.x, stash.coords.y, stash.coords.z),
                    options = {{
                        name = stash.id,
                        icon = 'fa-solid fa-boxes-stacked',
                        label = stash.label,
                        onSelect = function(data)
                            if stash.job then
                                local jobname = BRIDGE.GetPlayerJob()
                                local gangname = BRIDGE.GetPlayerGang()
                                if jobname == job.job or gangname == job.job then
                                    BRIDGE.OpenStash(stash.id, stash.weight, stash.slots)
                                else
                                    lib.notify({
                                        title = "Você não tem permissão",
                                        description = "Você não pode usar isso.",
                                        type = "error"
                                    })
                                end
                            else
                                BRIDGE.OpenStash(stash.id)
                            end
                        end
                    }},
                    debug = false,
                    radius = 0.2
                })
                table.insert(Targets, stashID)
            end
        end
        if job.peds then
            for _, ped in pairs(Peds) do
                if ped.entity then
                    DeleteEntity(ped.entity)
                end
            end
            Peds = {}
            for _, ped in pairs(job.peds) do
                AddNewPed(ped)
            end
        end
    end
end

RegisterNetEvent("mri_Qjobsystem:client:receiveJobs", function(ServerJobs)
    if ServerJobs then
        Jobs = ServerJobs
        GenerateCraftings()
    end
    RemoveManagementItems()
    AddManagementItens()
end)

RegisterNetEvent("mri_Qjobsystem:client:Pull")
AddEventHandler("mri_Qjobsystem:client:Pull", function(ServerJobs)
    for _, tid in pairs(Targets) do
        BRIDGE.RemoveSphereTarget(tid)
    end
    Wait(100)
    Jobs = ServerJobs
    Wait(100)
    GenerateCraftings()
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        for i, ped in pairs(Peds) do
            if not Peds[i].entity then
                if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) -
                    vector3(ped.coords.x, ped.coords.y, ped.coords.z)) < 60.0 then
                    local model = ped.model
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Wait(50)
                    end
                    Peds[i].entity = CreatePed(4, model, ped.coords.x, ped.coords.y, ped.coords.z - 1, ped.heading,
                        false, true)
                    FreezeEntityPosition(Peds[i].entity, true)
                    SetEntityInvincible(Peds[i].entity, true)
                    SetBlockingOfNonTemporaryEvents(Peds[i].entity, true)
                    if ped.animDict and ped.animAnim then
                        RequestAnimDict(ped.animDict)
                        while not HasAnimDictLoaded(ped.animDict) do
                            Wait(50)
                        end

                        TaskPlayAnim(Peds[i].entity, ped.animDict, ped.animAnim, 8.0, 0, -1, 1, 0, 0, 0)
                    end
                end
            else
                if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) -
                    vector3(ped.coords.x, ped.coords.y, ped.coords.z)) > 60.0 then
                    DeleteEntity(Peds[i].entity)
                    Peds[i].entity = nil
                end
            end
        end
        Wait(8000)
    end
end)
