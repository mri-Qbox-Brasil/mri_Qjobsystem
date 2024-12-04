Jobs = {}
local Targets = {}
local Peds = {}
local items = BRIDGE.GetItems()

local function AddNewPed(pedData)
    table.insert(Peds, pedData)
end

local function generateCrafting(craftItems, label, type)
    local options = {}
    local metadata = {}
    if craftItems and type then
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

            table.insert(options, {
                title = items[k.itemName].label .. " - " .. (k and k.count or 1) .. " x",
                icon = Config.DirectoryToInventoryImages .. k.itemName .. ".png",
                image = Config.DirectoryToInventoryImages .. k.itemName .. ".png",
                onSelect = function()
                    -- Perguntar quantos ele quer fabricar
                    local input = lib.inputDialog('Digite a quantidade', {
                        {type = 'number', label = 'Quantidade', default = 1}
                    })

                    if not input then
                        return lib.notify({
                            title = "Ação cancelada.",
                            type = "error"
                        })
                    end

                    local amount = input and input[1] or 1

                    local hasAllItems = true
                    for _, v in pairs(k.ingedience) do
                        if v.itemCount * amount > BRIDGE.GetItemCount(v.itemName) then
                            hasAllItems = false
                        end
                    end
                    if hasAllItems then
                        local animData = {
                            anim = Config.DEFAULT_ANIM,
                            dict = Config.DEFAULT_ANIM_DIC
                        }
                        if k.animation then
                            animData = {
                                anim = k.animation.anim,
                                dict = k.animation.dict,
                                scully = k.animation.scully
                            }
                        end
                        local label_progress = type and "Fabricando" or "Comprando"

                        local anim = {
                            anim = animData.anim,
                            dict = animData.dict
                        }

                        if animData and animData.scully then
                            ExecuteCommand(string.format("e %s", animData.scully))
                            anim = nil
                        end

                        if lib.progressCircle({
                            duration = k.duration and k.duration * 1000 * amount or 5000 * amount,
                            label = label_progress .. ' ' .. items[k.itemName].label,
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true
                            },
                            anim = anim
                        }) then
                            if animData.scully then
                                ExecuteCommand("e c")
                            end
                            TriggerSecureEvent("mri_Qjobsystem:server:createItem", k, amount)
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

                            if type then
                                generateCrafting(crafting.items, craftinglabel, type)
                            else
                                print(crafting.id)
                                exports.ox_inventory:openInventory('shop', {
                                    type = crafting.id
                                })
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