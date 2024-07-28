-- Variáveis
local items = BRIDGE.GetItems()
local selectedJob = {}

-- Definir itens para Ox Lib Select
local item_select = {}
local cached = {
    crafting_table_id = nil,
    crafting_item_id = nil,
    crafting_ingredience_id = nil
}

-- FUNÇÕES
local function isBlacklistedString(text)
    for _, v in pairs(Config.BlacklistedStrings) do
        if string.find(string.lower(text), string.lower(v)) then
            return true
        end
    end
    return false
end

for _, v in pairs(items) do
    if not isBlacklistedString(v.name) then
        table.insert(item_select, {
            label = string.format("%s (%s)", v.label, v.name),
            value = v.name
        })
    end
end

local function getRayCoords()
    lib.notify({
        title = "Selecionar coordenadas",
        description = "Confirme pressionando [E]",
        type = "info",
        duration = 10000
    })
    while true do
        local hit, entity, coords = lib.raycast.cam(1, 4)
        lib.showTextUI('PARA  \nCONFIRMAR  \n**LOCAL**  \n  \n X:  ' .. math.round(coords.x) .. ',  \n Y:  ' ..
                           math.round(coords.y) .. ',  \n Z:  ' .. math.round(coords.z), {
            icon = "e"
        })

        if hit then
            DrawSphere(coords.x, coords.y, coords.z, 0.2, 0, 0, 255, 0.2)
            if IsControlJustReleased(1, 38) then -- E
                lib.hideTextUI()
                return coords
            end
        end
    end
end

local function createCraftingTable()
    local coords = getRayCoords()
    if coords then
        if selectedJob.craftings then
            local input = lib.inputDialog('Criação de Crafting/Loja', {{
                type = 'input',
                label = 'Label',
                description = 'Adicionar rótulo',
                required = true,
                min = 1,
                max = 32
            }, {
                type = 'select',
                label = 'Ícone',
                description = 'Escolha o ícone da loja/crafting',
                options = {{
                    label = 'Crafting',
                    value = 'fa-solid fa-screwdriver-wrench',
                    icon = 'fa-solid fa-screwdriver-wrench'
                }, {
                    label = 'Loja',
                    value = 'fa-solid fa-cart-shopping',
                    icon = 'fa-solid fa-cart-shopping'
                }},
                default = 'Crafting',
                required = true
            }, {
                type = 'checkbox',
                label = 'É pública?',
                description = 'Marque caso queira deixar pública ao invés de ser permitido apenas pelo grupo.',
                default = false,
                required = true
            }})
            if not input then
                return
            end
            table.insert(selectedJob.craftings, {
                id = selectedJob.job .. #selectedJob.craftings .. "_" .. math.random(1, 9999),
                label = input[1],
                icon = input[2],
                public = input[3],
                coords = coords,
                items = {}
            })
            local alert = lib.alertDialog({
                header = 'Criação de crafting/loja',
                content = 'Sucesso! Você quer fazer outra loja/crafting?',
                centered = true,
                cancel = true
            })

            if alert == "confirm" then
                createCraftingTable()
            else
                TriggerSecureEvent("mri_Qjobsystem:server:saveNewJob", selectedJob)
                Wait(500)
                EditCrafings()
            end
        end
    end
end

local function createNewStash()
    local coords = getRayCoords()
    if coords then
        local input = lib.inputDialog('Criação de Baú', {{
            type = 'input',
            label = 'Nome',
            description = 'Nome do baú',
            required = true,
            min = 1,
            max = 32
        }, {
            type = 'number',
            label = 'Slots',
            description = 'Quantos slots terá o baú?',
            required = true
        }, {
            type = 'number',
            label = 'Peso',
            description = 'Peso máximo em gramas',
            required = true
        }, {
            type = "select",
            label = "Permissão",
            description = "Você quer limitar o acesso ao baú apenas para o grupo?",
            required = true,
            options = {{
                label = "Sim",
                value = "yyy"
            }, {
                label = "Não",
                value = "nah"
            }}
        }})
        if not input then
            return
        end
        if not selectedJob.stashes then
            selectedJob.stashes = {}
        end
        local limitedByJob = false
        if input[4] == "yyy" then
            limitedByJob = true
        end
        table.insert(selectedJob.stashes, {
            id = selectedJob.job .. #selectedJob.stashes .. "_" .. math.random(1, 9999),
            label = input[1],
            coords = coords,
            slots = input[2],
            weight = input[3],
            job = limitedByJob
        })
        TriggerSecureEvent("mri_Qjobsystem:server:saveNewJob", selectedJob)
    end
end

local function createNewPed()
    local input = lib.inputDialog('Crie Ped', {{
        type = 'input',
        label = 'Rótulo',
        description = 'Nome do ped',
        required = true,
        min = 1,
        max = 32
    }, {
        type = 'input',
        label = 'Modelo do Ped',
        description = 'Digite o modelo PED',
        required = true,
        min = 0,
        max = 64
    }, {
        type = 'input',
        label = 'Animação',
        description = 'Digite a animação',
        required = false,
        min = 0,
        max = 64
    }, {
        type = 'input',
        label = 'Dicionário da Animação',
        description = 'Digite o dicionário da animação',
        required = false,
        min = 0,
        max = 64
    }})
    if not input then
        return
    end
    if not selectedJob.peds then
        selectedJob.peds = {}
    end
    table.insert(selectedJob.peds, {
        label = input[1],
        model = input[2],
        coords = GetEntityCoords(cache.ped),
        heading = GetEntityHeading(cache.ped),
        animAnim = input[3],
        animDict = input[4]
    })
    TriggerSecureEvent("mri_Qjobsystem:server:saveNewJob", selectedJob)
end

local function addonsExists(value)
    if value then
        return "Criado"
    else
        return "Não criado"
    end
end

local function selectJob(jobData)
    selectedJob = jobData
    lib.registerContext({
        id = 'job_manipulate',
        title = jobData.label,
        description = "Gerenciamento",
        menu = 'job_menu_open',
        options = {{
            title = selectedJob.label,
            description = "Clique aqui para renomear.",
            icon = 'quote-left',
            onSelect = function()
                local input = lib.inputDialog('Editar nome', {{
                    type = 'input',
                    label = 'Nome',
                    description = 'Coloque algum nome para este grupo.',
                    required = true,
                    min = 1,
                    max = 32
                }})
                if not input then
                    return selectJob(jobData)
                end
                selectedJob.label = input[1]
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                Wait(500)
                selectJob(jobData)
            end
        }, {
            title = "Cargos",
            description = "Gerenciar hierarquia do grupo e salário.",
            icon = 'sitemap',
            onSelect = function()
                OpenJobsGrades(jobData)
            end
        }, {
            title = "Local para Bater Ponto",
            description = "Status: " .. addonsExists(selectedJob.duty),
            icon = 'clock',
            onSelect = function()
                if selectedJob.duty then
                    local alert = lib.alertDialog({
                        header = "Excluir o local de Bater Ponto",
                        content = "Você realmente quer excluir?",
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        selectedJob.duty = nil
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                else
                    local coords = getRayCoords()
                    if coords then
                        selectedJob.duty = coords
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                end
            end
        }, {
            title = "Caixa registradora",
            description = "Status: " .. addonsExists(selectedJob.register),
            icon = 'dollar',
            onSelect = function()
                if selectedJob.register then
                    local alert = lib.alertDialog({
                        header = "Excluir a caixa registradora",
                        content = "Você realmente quer excluir?",
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        selectedJob.register = nil
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                else
                    local coords = getRayCoords()
                    if coords then
                        selectedJob.register = coords
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                end
            end
        }, {
            title = "Alarme",
            description = "Status: " .. addonsExists(selectedJob.alarm),
            icon = "fa-solid fa-bell",
            onSelect = function()
                if selectedJob.alarm then
                    local alert = lib.alertDialog({
                        header = "Excluir alarme",
                        content = "Você realmente quer excluir?",
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        selectedJob.alarm = nil
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                else
                    local coords = getRayCoords()
                    if coords then
                        selectedJob.alarm = coords
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                end
            end
        }, {
            title = "Bossmenu",
            description = "Status: " .. addonsExists(selectedJob.bossmenu),
            icon = 'laptop',
            onSelect = function()
                if selectedJob.bossmenu then
                    local alert = lib.alertDialog({
                        header = "Boss menu",
                        content = "Você realmente quer excluir? ",
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        selectedJob.bossmenu = nil
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                else
                    local coords = getRayCoords()
                    if coords then
                        selectedJob.bossmenu = coords
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    Wait(500)
                    selectJob(jobData)
                end
            end
        }, {
            title = "Craftings/Lojas",
            description = "Clique aqui para abrir o menu de criar crafting/lojas.",
            icon = 'box',
            onSelect = function()
                EditCrafings()
            end
        }, {
            title = "Baús",
            description = "Clique aqui para o menu de baús.",
            icon = 'boxes-stacked',
            onSelect = function()
                EditStashes()
            end
        }, {
            title = "Peds",
            description = "Clique aqui para abrir o menu PED.",
            icon = 'person',
            onSelect = function()
                EditPeds()
            end
        }, {
            title = "Excluir grupo",
            description = "Clique aqui para excluir este grupo.",
            icon = 'trash',
            iconColor = 'red',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Excluir o grupo: ' .. selectedJob.label,
                    content = "Você realmente quer excluir o grupo?",
                    centered = true,
                    cancel = true
                })
                if alert == "confirm" then
                    TriggerSecureEvent("mri_Qjobsystem:server:deleteJob", selectedJob)
                end
                Wait(500)
                ExecuteCommand("open_jobs")
            end
        }, {
            title = "Atualizar para MIM",
            description = "Isso atualiza os empregos para você!",
            icon = 'arrow-up',
            onSelect = function()
                TriggerSecureEvent("mri_Qjobsystem:server:pullChanges", "creator")
                Wait(500)
                selectJob(jobData)
            end
        }, {
            title = "Atualizar para TODOS",
            description = "Isso atualiza os trabalhos para todos os jogadores no servidor!",
            icon = 'arrow-up',
            onSelect = function()
                TriggerSecureEvent("mri_Qjobsystem:server:pullChanges", "all")
                Wait(500)
                selectJob(jobData)
            end
        }, {
            title = "Backup",
            description = "Isso é ótimo se algo der errado. (Faz o backup para todos os grupos)",
            icon = 'floppy-disk',
            onSelect = function()
                local options = {{
                    title = "Criar backup",
                    description = "Salvar novo backup, isso sobrescreve o backup que existir atualmetente.",
                    icon = "plus",
                    onSelect = function()
                        TriggerSecureEvent("mri_Qjobsystem:server:createBackup")
                    end
                }, {
                    title = "Restaurar último backup existente",
                    description = "Usar o último backup! Primeiro verifique se server/backup.json NÃO ESTÁ VAZIO!",
                    icon = "floppy-disk",
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = 'Restaurar backup',
                            content = 'Você realmente quer fazer isso?** Confira backup.json no server/backup.json para ver se o arquivo existe ou está vazio! **',
                            centered = true,
                            cancel = true
                        })
                        if alert == "confirm" then
                            TriggerSecureEvent("mri_Qjobsystem:server:setBackup")
                        end
                    end
                }}
                lib.registerContext({
                    id = 'job_backupmenu',
                    title = "Backup",
                    options = options
                })
                lib.showContext("job_backupmenu")
            end
        }}
    })
    lib.showContext("job_manipulate")
end

function OpenJobsGrades(jobData)
    selectedJob = jobData
    print(json.encode(jobData))
    local options = {}
    if jobData.type == 'job' then
        options[#options + 1] = {
            title = "Editar Tipo",
            description = "Clique aqui para editar o tipo de trabalho.",
            icon = 'edit',
            onSelect = function()
                local input_options = Config.jobTypeList
                local input_type = lib.inputDialog('Configurações de Trabalho', {{
                    type = 'select',
                    label = 'Tipo de trabalho',
                    description = "leo = policiais, ems = paramédicos, mechanic = mecânicos, etc. Marque sem tipo caso não se aplique.",
                    options = input_options,
                    default = (jobData.jobtype or "Nenhum"),
                    required = true,
                    searchable = true,
                    clearable = true
                }})
                if not input_type then
                    return OpenJobsGrades(jobData)
                end
                if input_type ~= 'Nenhum' then
                    jobData.jobtype = input_type[1]
                else
                    jobData.jobtype = nil
                end

                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                lib.notify({
                    title = "Atualizado",
                    description = "Tipo de cargo alterado para " .. (jobData.jobtype or "Nenhum"),
                    type = "success"
                })
                Wait(500)
                return OpenJobsGrades(jobData)
            end
        }
    end

    options[#options + 1] = {
        title = "Criar cargo",
        description = "Clique aqui para criar um cargo.",
        icon = 'plus',
        onSelect = function()
            local inputOptions = {{
                type = 'input',
                label = 'Nome',
                description = 'Coloque algum nome para este cargo.',
                required = true,
                min = 1,
                max = 32
            }}

            if jobData.type == 'job' then
                inputOptions[#inputOptions + 1] = {
                    type = 'number',
                    label = 'Salário',
                    description = 'Coloque o valor do salário para este cargo.',
                    required = true,
                    min = 0
                }
            end
            local input = lib.inputDialog('Criar cargo', inputOptions)
            if not input then
                return selectJob(jobData)
            end

            local count = 0
            for i, grade in pairs(jobData.grades) do
                count = count + 1
            end

            selectedJob.grades[count] = {
                name = input[1],
                payment = input[2]
            }

            TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
            lib.notify({
                title = 'Cargo criado',
                description = 'O cargo foi criado com sucesso.',
                type = 'success'
            })
            Wait(500)
            return OpenJobsGrades(jobData)
        end
    }

    options[#options + 1] = {
        title = "Excluir cargo mais alto",
        description = "Clique para excluir o cargo mais alto.",
        icon = 'trash',
        iconColor = 'red',
        onSelect = function()
            local alert = lib.alertDialog({
                header = 'Excluir cargo',
                content = "Você realmente quer excluir o cargo?",
                centered = true,
                cancel = true
            })
            if alert ~= "confirm" then
                return OpenJobsGrades(jobData)
            end

            local count = -1
            for i, grade in pairs(jobData.grades) do
                count = count + 1
            end
            local newGrades = {}
            for k, v in pairs(jobData.grades) do
                if tonumber(k) ~= tonumber(count) then
                    newGrades[k] = v
                end
            end

            selectedJob.grades = newGrades
            TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)

            print(json.encode(selectedJob))

            lib.notify({
                title = 'Cargo excluído',
                description = 'O cargo foi excluído com sucesso.',
                type = 'success'
            })
            Wait(500)
            return OpenJobsGrades(selectedJob)
        end
    }

    local count = -1
    for i, grade in pairs(jobData.grades) do
        count = count + 1
    end
    for i, grade in pairs(jobData.grades) do
        local description = ""
        if jobData.type == 'job' then
            description = string.format('Salário: R$ %s', grade.payment)
        end

        if tonumber(i) == count then
            description = string.format('%s  \n  *Boss do Grupo*', description)
        end

        local newOption = {
            title = '[' .. i .. '] ' .. grade.name,
            description = description,
            icon = 'circle',
            onSelect = function()
                local inputOptions = {{
                    type = 'input',
                    label = 'Nome',
                    description = 'Coloque algum nome para este cargo.',
                    required = true,
                    min = 1,
                    max = 32,
                    default = grade.name
                }}

                if jobData.type == 'job' then
                    inputOptions[#inputOptions + 1] = {
                        type = 'number',
                        label = 'Salário',
                        description = 'Coloque o valor do salário para este cargo.',
                        required = true,
                        min = 0,
                        default = grade.payment
                    }
                end

                local input = lib.inputDialog('Editar cargo', inputOptions)
                if not input then
                    return selectJob(jobData)
                end

                if jobData.type == 'job' then
                    grade.payment = input[2]
                end
                grade.name = input[1]
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                Wait(500)
                OpenJobsGrades(jobData)
            end
        }
        table.insert(options, newOption)
    end
    table.sort(options, function(a, b)
        return a.title < b.title
    end)

    lib.registerContext({
        id = 'job_grades',
        title = 'Hierarquia',
        description = 'Gerenciamento',
        options = options,
        menu = 'job_manipulate',
        onBack = function()
            selectJob(jobData)
        end
    })
    lib.showContext("job_grades")
end

local function openCraftingTable(id)
    local selectedCrafting = selectedJob.craftings[id]
    cached.crafting_table_id = id
    if selectedCrafting then
        local options = {}
        for itemId, craftingItem in pairs(selectedCrafting.items) do
            local newOption = {
                title = items[craftingItem.itemName].label,
                description = "Editar o item existente.",
                icon = 'circle',
                image = Config.DirectoryToInventoryImages .. craftingItem.itemName .. ".png",
                onSelect = function()
                    cached.crafting_item_id = itemId
                    EditCraftingItem()
                end
            }
            table.insert(options, newOption)
        end
        table.insert(options, {
            title = "Crie um novo item",
            description = "Crie um novo item para vender ou fabricar.",
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog('Selecione Item e Ingredientes', {{
                    type = 'select',
                    label = "Item principal",
                    placeholder = "Selecionar",
                    description = "Este é o item que você deseja criar.",
                    required = true,
                    options = item_select,
                    searchable = true,
                    clearable = true
                }, {
                    type = 'multi-select',
                    label = "Itens necessários",
                    placeholder = "Quais itens serão necessários para fabricar o item principal? Coloque money se for loja por exemplo.",
                    description = "Required",
                    required = true,
                    options = item_select,
                    searchable = true,
                    clearable = true
                }})
                if input then
                    local defineIngedience = {}
                    for _, selectedIngedience in pairs(input[2]) do
                        table.insert(defineIngedience, {
                            itemName = selectedIngedience,
                            itemCount = 1
                        })
                    end

                    local newTable = {
                        itemName = input[1],
                        itemCount = 1,
                        ingedience = defineIngedience
                    }
                    table.insert(selectedJob.craftings[id].items, newTable)
                    TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    lib.notify({
                        title = "Sucesso",
                        description = "Parabéns! Criado com sucesso.",
                        type = "success"
                    })
                    openCraftingTable(cached.crafting_table_id)
                end
            end
        })

        local icon = selectedCrafting.icon or 'fa-solid fa-screwdriver-wrench'
        local type = (icon == 'fa-solid fa-screwdriver-wrench') and 'Crafting' or 'Loja'

        options[#options + 1] = {
            title = "Editar ícone",
            description = "Clique aqui para editar.",
            icon = icon,
            onSelect = function()
                local options = {{
                    label = 'Crafting',
                    value = 'fa-solid fa-screwdriver-wrench',
                    icon = 'fa-solid fa-screwdriver-wrench'
                }, {
                    label = 'Loja',
                    value = 'fa-solid fa-shopping-cart',
                    icon = 'fa-solid fa-shopping-cart'
                }}
                local input = lib.inputDialog('Icone', {{
                    type = 'select',
                    label = "Icone",
                    placeholder = "Selecionar",
                    description = "Selecione um icone para a loja/crafting.",
                    required = true,
                    options = options,
                    searchable = true,
                    clearable = true,
                    default = icon
                }})
                if not input then
                    return lib.notify({
                        title = "Negado",
                        description = "Operação cancelada.",
                        type = "error"
                    })
                end
                selectedCrafting.icon = input[1]
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                Wait(500)
                openCraftingTable(cached.crafting_table_id)
                lib.notify({
                    title = "Sucesso",
                    description = "Loja/crafting foi salvo com sucesso.",
                    type = "success"
                })
            end
        }

        local public = selectedCrafting.public or false

        options[#options + 1] = {
            title = string.format("Modo público: %s", public and "Ativado" or "Desativado"),
            description = "Clique aqui para ativar/desativar se essa loja ou crafting será pública ou apenas desse grupo.",
            iconColor = public and 'green' or 'red',
            icon = public and 'fa-solid fa-toggle-on' or 'fa-solid fa-toggle-off',
            onSelect = function()
                selectedCrafting.public = not public
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                Wait(500)
                openCraftingTable(cached.crafting_table_id)
                lib.notify({
                    title = "Sucesso",
                    description = "Loja/crafting foi salvo com sucesso.",
                    type = "success"
                })
            end
        }

        options[#options + 1] = {
            title = "Excluir mesa",
            description = "Clique aqui para excluir.",
            icon = 'trash',
            onSelect = function()
                table.remove(selectedJob.craftings, id)
                lib.notify({
                    title = "Sucesso",
                    description = "Loja/crafting foi excluído com sucesso.",
                    type = "success"
                })
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                Wait(500)
                EditCrafings()
            end
        }

        lib.registerContext({
            id = 'create_new_crafting_item',
            title = 'Gerenciar',
            options = options,
            menu = 'default',
            onBack = function()
                EditCrafings()
            end
        })
        lib.showContext("create_new_crafting_item")
    end
end

function EditCrafings()
    if selectedJob then
        local options = {}
        for i, crafting in pairs(selectedJob.craftings) do
            local icon = crafting.icon or 'fa-solid fa-screwdriver-wrench'
            local type = (icon == 'fa-solid fa-screwdriver-wrench') and 'Crafting' or 'Loja'

            local newOption = {
                title = string.format("[%s] %s", type, crafting.label),
                description = "Clique aqui para editar.",
                icon = icon,
                onSelect = function()
                    openCraftingTable(i)
                end
            }
            table.insert(options, newOption)
        end

        options[#options + 1] = {
            title = "Novo crafting/loja",
            description = "Criar um novo crafting/loja.",
            icon = "plus",
            onSelect = function()
                createCraftingTable()
            end
        }

        lib.registerContext({
            id = 'job_crafting_list',
            title = "Gerenciamento",
            description = "Craftings e Lojas",
            options = options,
            menu = 'default',
            onBack = function()
                selectJob(selectedJob)
            end
        })
        lib.showContext("job_crafting_list")
    end
end

function EditStashes()
    if selectedJob then
        local options = {}
        if not selectedJob.stashes then
            selectedJob.stashes = {}
        end
        for i, stashes in pairs(selectedJob.stashes) do
            local newOption = {
                title = stashes.label,
                description = "Click here for edit stashes. ",
                icon = 'circle',
                onSelect = function()
                    local options = {{
                        title = "Change stash ID",
                        description = "Click here if you want to change the stash ID! If you don't know what you are doing don't touch this.",
                        icon = 'circle',
                        onSelect = function()
                            local input = lib.inputDialog('Change stash ID', {'Enter new ID/Name'})
                            if input then
                                stashes.id = input[1]
                                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                            end
                        end
                    }, {
                        title = "Delete stash",
                        description = "Click here for delete stash.",
                        icon = 'trash',
                        onSelect = function()
                            print("Stash " .. stashes.id .. " deleted!")
                            print("This message is a last resort if you are an idiot and accidentally clicked.")
                            table.remove(selectedJob.stashes, i)
                            lib.notify({
                                title = "Deleted",
                                description = "Stash deleted!",
                                type = "success"
                            })
                            TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                        end
                    }}
                    lib.registerContext({
                        id = 'job_system_stashes_edit',
                        title = 'Baús',
                        options = options
                    })
                    lib.showContext("job_system_stashes_edit")
                end
            }
            table.insert(options, newOption)
        end

        table.insert(options, {
            title = "New stash",
            description = "Create stash",
            icon = "plus",
            onSelect = function()
                createNewStash()
            end
        })

        lib.registerContext({
            id = 'job_stashes_list',
            title = selectedJob.label .. " - Stashes",
            options = options
        })
        lib.showContext("job_stashes_list")
    end
end

function EditPeds()
    if selectedJob then
        local options = {}
        if not selectedJob.peds then
            selectedJob.peds = {}
        end
        for i, ped in pairs(selectedJob.peds) do
            local newOption = {
                title = ped.label,
                description = "Clique aqui para editar PED",
                icon = 'circle',
                onSelect = function()
                    local options = {{
                        title = "Excluir Ped",
                        description = "Clique aqui para excluir PED.",
                        icon = 'trash',
                        onSelect = function()
                            table.remove(selectedJob.peds, i)
                            lib.notify({
                                title = "Excluída",
                                description = "Ped excluído!",
                                type = "success"
                            })
                            TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                        end
                    }}
                    lib.registerContext({
                        id = 'job_system_peds_edit',
                        title = 'Ped',
                        options = options
                    })
                    lib.showContext("job_system_peds_edit")
                end
            }
            table.insert(options, newOption)
        end

        table.insert(options, {
            title = "New ped",
            description = "Create ped",
            icon = "plus",
            onSelect = function()
                createNewPed()
            end
        })

        lib.registerContext({
            id = 'job_stashes_list',
            title = selectedJob.label .. " - Stashes",
            options = options
        })
        lib.showContext("job_stashes_list")
    end
end

function EditCraftingItem()
    local count = 1
    if cached.crafting_item_id then
        if selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount then
            count = selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount
        end
        local options = {{
            title = "Quantidade: " .. count,
            description = "Isso é o que o jogador recebe",
            icon = 'hashtag',
            onSelect = function()
                print(selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount)
                local input = lib.inputDialog('Alterar quantidade', {'Digite a quantidade:'})
                if input then
                    selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount = tonumber(
                        input[1])
                    TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                end
                EditCraftingItem()
            end
        }, {
            title = "Mude a animação",
            description = "Clique aqui para mudar de animação!",
            icon = 'hippo',
            onSelect = function()
                if selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation then
                    local alert = lib.alertDialog({
                        header = 'Animação excluída',
                        content = 'Essa animação foi redefinida aos padrões.',
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation = nil
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                else
                    local input = lib.inputDialog('Editar Animação', {'Anim', "Dict"})
                    if input then
                        selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation = {
                            anim = input[1],
                            dict = input[2]
                        }
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                end
                EditCraftingItem()
            end
        }}
        for ingedienceId, v in pairs(selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id]
                                         .ingedience) do
            table.insert(options, {
                title = items[v.itemName].label .. " - x" .. v.itemCount,
                description = "Clique aqui para mudar a quantidade",
                image = Config.DirectoryToInventoryImages .. v.itemName .. ".png",
                icon = 'circle',
                onSelect = function()
                    local input = lib.inputDialog('Alterar quantidade', {'Quantidade:'})
                    if input then
                        selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].ingedience[ingedienceId]
                            .itemCount = tonumber(input[1])
                        TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                    end
                    EditCraftingItem()
                end
            })
        end
        table.insert(options, {
            title = "Excluir item",
            description = "Clique aqui para excluir este item",
            icon = 'trash',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Item excluído',
                    content = 'O item foi excluído.',
                    centered = true,
                    cancel = true
                })
                if alert ~= "confirm" then
                    return EditCraftingItem()
                end
                table.remove(selectedJob.craftings[cached.crafting_table_id].items, cached.crafting_item_id)
                TriggerSecureEvent("mri_Qjobsystem:server:saveJob", selectedJob)
                openCraftingTable(cached.crafting_table_id)
                lib.notify({
                    title = "Sucesso",
                    description = "O item foi excluído",
                    type = "success"
                })
            end
        })
        lib.registerContext({
            id = 'create_new_crafting_item',
            title = 'Gerenciar Item',
            options = options,
            menu = 'default',
            onBack = function()
                openCraftingTable(cached.crafting_table_id)
            end
        })
        lib.showContext("create_new_crafting_item")
    end
end

---- EVENTOS
RegisterNetEvent("mri_Qjobsystem:client:createjob", function()
    local newJob = Config.DefaultDataJob
    local input = lib.inputDialog('Criar um novo Grupo', {{
        type = 'input',
        label = 'Título',
        description = 'Qual o Título do grupo?',
        required = true,
        min = 1,
        max = 32
    }, {
        type = 'input',
        label = 'Código do grupo',
        description = 'Coloque por exemplo: police, ballas, etc. (SEMPRE EM MINÚSCULO)',
        required = true,
        min = 1,
        max = 32
    }, {
        type = 'select',
        label = 'Tipo',
        description = 'Qual o tipo? Job = salário e ponto | Gang = sem salário e sem bater ponto.',
        options = {{
            value = 'job',
            label = 'Job'
        }, {
            value = 'gang',
            label = 'Gang'
        }},
        default = 1,
        required = true
    }, {
        type = 'number',
        label = 'Cargos',
        description = 'Quantos cargos o grupo tem?',
        required = true,
        min = 1,
        max = 100
    }})

    if not input then
        return
    end
    newJob.label = input[1]
    newJob.coords = GetEntityCoords(cache.ped)
    newJob.job = string.lower(input[2])
    newJob.type = input[3]

    local Jobs = exports.qbx_core:GetJobs()
    print(json.encode(Jobs))
    for k, v in pairs(Jobs) do
        if k == newJob.job then
            lib.notify({
                title = "Erro",
                description = "Já existe um grupo com esse nome",
                type = "error"
            })
            return
        end
    end

    if input[3] == 'job' then
        local input_options = Config.jobTypeList
        local input_type = lib.inputDialog('Job: Configurações adicionais', {{
            type = 'select',
            label = 'Tipo de trabalho',
            description = "leo = policiais, ems = paramédicos, mechanic = mecânicos, etc. Marque sem tipo caso não se aplique.",
            options = input_options
        }})
        if not input_type then
            return
        end
        if input_type ~= 'none' then
            newJob.jobtype = input_type[1]
        end
    end

    local grades = {}

    for i = 1, input[4] do
        local options = {{
            type = 'number',
            label = 'Código do cargo',
            description = 'Qual o Código do cargo?',
            required = true,
            default = i - 1,
            disabled = true
        }, {
            type = 'input',
            label = 'Nome do cargo',
            description = 'Qual o nome do cargo?',
            required = true
        }}
        if input[3] == 'job' then
            options[#options + 1] = {
                type = 'number',
                label = 'Salário',
                description = 'Qual o Salário do cargo?',
                required = true,
                min = 0,
                max = 1000000
            }
        end

        local _input = lib.inputDialog(string.format('Criação de Cargos [%s]', i - 1), options)
        if not _input then
            return
        end
        local gradenumber = tonumber(_input[1])
        if not gradenumber then
            gradenumber = i - 1
        end

        if _input[3] then
            if i == input[4] then
                grades[gradenumber] = {
                    name = _input[2],
                    payment = _input[3],
                    isboss = true,
                    bankAuth = true
                }
            else
                grades[gradenumber] = {
                    name = _input[2],
                    payment = _input[3]
                }
            end
        else
            if i == input[4] then
                grades[gradenumber] = {
                    name = _input[2],
                    isboss = true,
                    bankAuth = true
                }
            else
                grades[gradenumber] = {
                    name = _input[2]
                }
            end
        end
    end

    newJob.grades = grades

    TriggerSecureEvent("mri_Qjobsystem:server:saveNewJob", newJob)
    Wait(500)
    ExecuteCommand("open_jobs")
end)

RegisterNetEvent("mri_Qjobsystem:client:openJobMenu", function(Jobs)
    if Jobs then
        local options = {}
        for _, job in pairs(Jobs) do
            local newOption = {
                title = job.label .. " - " .. job.job,
                description = 'Craftings/Lojas ' .. #job.craftings,
                icon = 'circle',
                onSelect = function()
                    selectJob(job)
                end
            }
            table.insert(options, newOption)
        end
        lib.registerContext({
            id = 'job_menu_open',
            title = 'Gerenciamento',
            description = 'Trabalhos e Facções',
            menu = 'menu_jobs',
            options = options
        })
        lib.showContext("job_menu_open")
    end
end)
