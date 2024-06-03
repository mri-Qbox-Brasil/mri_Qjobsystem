-- VARIABLES
local items = BRIDGE.GetItems()
local selectedJob = {}

-- DEFINE ITEMS for lib select
local item_select = {}
local cached = {
  crafting_table_id = nil,
  crafting_item_id = nil,
  crafting_ingredience_id = nil,
}


-- FUNCTIONS
local function IsBlacklistedString(text)
  for _, v in pairs(Config.BlacklistedStrings) do
    if string.find(string.lower(text), string.lower(v)) then
      return true
    end
  end
  return false
end


for _, v in pairs(items) do
  if not IsBlacklistedString(v.name) then
    table.insert(item_select, {
      label = v.label,
      value = v.name,
    })
  end
end



local function CreateNewCraftingPoint()
  lib.notify({
    title = "Select point",
    description = "Confirm by [ E ]",
    type = "inform"
  })
  while true do
    Wait(0)
    local hit, entity, coords = lib.raycast.cam(1|16)
    if hit then
      DrawSphere(coords.x, coords.y, coords.z, 0.2, 0, 0, 255, 0.2)
      if IsControlJustPressed(1, 38) then -- E
        return coords
      end
    end
  end
end

local function CreateCraftingTable()
  local coords = CreateNewCraftingPoint()
  if coords then
    if selectedJob.craftings then
      local input = lib.inputDialog('Create new job',
        {
          { type = 'input', label = 'Label', description = 'Add crafting table label', required = true, min = 4, max = 32 },
        })
      if not input then return end
      table.insert(selectedJob.craftings, {
        id = selectedJob.job .. #selectedJob.craftings .. "_" .. math.random(1, 9999),
        label = input[1],
        coords = coords,
        items = {

        }
      })
      local alert = lib.alertDialog({
        header = 'Crafting creation',
        content = '# Crafting done! You want create new crafting point? ',
        centered = true,
        cancel = true
      })

      if alert == "confirm" then
        CreateCraftingTable()
      else
        TriggerSecureEvent("pls_jobsystem:server:saveNewJob", selectedJob)
      end
    end
  end
end


local function CreateNewStash()
  local coords = CreateNewCraftingPoint()
  if coords then
    local input = lib.inputDialog('Create stash',
      {
        { type = 'input',  label = 'Label',  description = 'Stash label',                 required = true, min = 4, max = 32 },
        { type = 'number', label = 'Slots',  description = 'How many slots do you want?', required = true },
        { type = 'number', label = 'Weight', description = 'Maximum weight',              required = true },
        {
          type = "select",
          label = "Limited by job",
          description = "You want limite by job?",
          required = true,
          options = {
            {
              label = "Yes",
              value = "yyy",
            },
            {
              label = "No",
              value = "nah",
            },
          }
        }
      })
    if not input then return end
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
      job = limitedByJob,
    })
    TriggerSecureEvent("pls_jobsystem:server:saveNewJob", selectedJob)
  end
end


local function CreateNewPed()
  local input = lib.inputDialog('Create ped',
    {
      { type = 'input', label = 'Label',          description = 'Ped name',             required = true,  min = 4, max = 32 },
      { type = 'input', label = 'Ped model',      description = 'Enter ped model',      required = true,  min = 0, max = 64 },
      { type = 'input', label = 'Animation',      description = 'Enter animation',      required = false, min = 0, max = 64 },
      { type = 'input', label = 'Animation DICT', description = 'Enter animation dict', required = false, min = 0, max = 64 },
    })
  if not input then return end
  if not selectedJob.peds then
    selectedJob.peds = {}
  end
  table.insert(selectedJob.peds, {
    label = input[1],
    model = input[2],
    coords = GetEntityCoords(cache.ped),
    heading = GetEntityHeading(cache.ped),
    animAnim = input[3],
    animDict = input[4],
  })
  TriggerSecureEvent("pls_jobsystem:server:saveNewJob", selectedJob)
end
local function AddonsExists(value)
  if value then
    return "Created"
  else
    return "Not created"
  end
end

local function selectJob(jobData)
  selectedJob = jobData
  lib.registerContext({
    id = 'job_manipulate',
    title = 'Gerenciar',
    menu = 'job_menu_open',
    options = {
      {
        title = selectedJob.label,
        description = "Clique aqui para renomear",
        icon = 'quote-left',
        onSelect = function()
          local input = lib.inputDialog('Trabalho de edição',
            {
              { type = 'input', label = 'Label', description = 'Coloque algum nome para este trabalho.', required = true, min = 4, max = 16 },
            })
          if not input then return end
          selectedJob.label = input[1]
          TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
        end,
      },
      {
        title = "Tamanho da área:" .. selectedJob.area,
        description = "Clique aqui para mudar a área de trabalho",
        icon = 'expand',
        onSelect = function()
          local input = lib.inputDialog('Trabalho de edição',
            {
              { type = 'number', label = 'Área', description = 'Qual é o tamanho da área de trabalho?', icon = 'hashtag', min = 10, max = 100 },
            })
          if not input then return end
          selectedJob.area = input[1]
          TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
        end,
      },
      {
        title = "Caixa registradora",
        description = "Status: " .. AddonsExists(selectedJob.register),
        icon = 'dollar',
        onSelect = function()
          if selectedJob.register then
            local alert = lib.alertDialog({
              header = "Exclua a caixa registradora",
              content = "Você realmente quer excluir? ",
              centered = true,
              cancel = true
            })
            if alert == "confirm" then
              selectedJob.register = nil
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          else
            local coords = CreateNewCraftingPoint()
            if coords then
              selectedJob.register = coords
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          end
        end,
      },
      {
        title = "Alarme",
        description = "Status: " .. AddonsExists(selectedJob.alarm),
        icon = 'bell',
        onSelect = function()
          if selectedJob.alarm then
            local alert = lib.alertDialog({
              header = "Excluir alarme",
              content = "Você realmente quer excluir? ",
              centered = true,
              cancel = true
            })
            if alert == "confirm" then
              selectedJob.alarm = nil
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          else
            local coords = CreateNewCraftingPoint()
            if coords then
              selectedJob.alarm = coords
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          end
        end,
      },
      {
        title = "Bossmenu",
        description = "Status: " .. AddonsExists(selectedJob.bossmenu) .. " / Export config.lua - function openBossmenu",
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
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          else
            local coords = CreateNewCraftingPoint()
            if coords then
              selectedJob.bossmenu = coords
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          end
        end,
      },
      {
        title = "Craftings",
        description = "Clique aqui para abrir o menu de artesanato",
        icon = 'box',
        onSelect = function()
          EditCrafings()
        end,
      },
      {
        title = "Baús",
        description = "Clique aqui para o menu de baús",
        icon = 'boxes-stacked',
        onSelect = function()
          EditStashes()
        end,
      },
      {
        title = "Peds",
        description = "Clique aqui para abrir o menu PED",
        icon = 'person',
        onSelect = function()
          EditPeds()
        end,
      },
      {
        title = "Excluir trabalho",
        description = "Clique aqui para excluir este trabalho.",
        icon = 'trash',
        onSelect = function()
          local alert = lib.alertDialog({
            header = 'Excluir trabalho' .. selectedJob.label,
            content = "Você realmente quer excluir o trabalho?",
            centered = true,
            cancel = true
          })
          if alert == "confirm" then
            TriggerSecureEvent("pls_jobsystem:server:deleteJob", selectedJob)
          end
          Wait(500)
          ExecuteCommand("open_jobs")
        end,
      },
      {
        title = "Atualizar para MIM",
        description = "Isso atualiza os empregos para você!",
        icon = 'arrow-up',
        onSelect = function()
          TriggerSecureEvent("pls_jobsystem:server:pullChanges", "creator")
        end,
      },
      {
        title = "Atualizar para TODOS",
        description = "Isso atualiza os trabalhos para todos os jogadores no servidor!",
        icon = 'arrow-up',
        onSelect = function()
          TriggerSecureEvent("pls_jobsystem:server:pullChanges", "all")
        end,
      },
      {
        title = "Backup",
        description = "Isso é ótimo se algo der errado. (Isso é backup para todos os trabalhos!)",
        icon = 'floppy-disk',
        onSelect = function()
          local options = {
            {
              title = "Criar backup",
              description = "Isso cria backup...",
              icon = "plus",
              onSelect = function()
                TriggerSecureEvent("pls_jobsystem:server:createBackup")
              end
            },
            {
              title = "Use o último backup!",
              description = "Usar o último backup! Primeiro verifique se server/backup.json NÃO ESTÁ VAZIO!",
              icon = "floppy-disk",
              onSelect = function()
                local alert = lib.alertDialog({
                  header = 'Restaurar backup',
                  content =
                  'Você realmente quer fazer isso?** Confira backup.json no server/backup.json para ver se o arquivo existe ou está vazio! **',
                  centered = true,
                  cancel = true
                })
                if alert == "confirm" then
                  TriggerSecureEvent("pls_jobsystem:server:setBackup")
                end
              end
            }
          }
          lib.registerContext({
            id = 'job_backupmenu',
            title = "Backup",
            options = options
          })
          lib.showContext("job_backupmenu")
        end,
      }
    }
  })
  lib.showContext("job_manipulate")
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
        onSelect = function()
          cached.crafting_item_id = itemId
          EditCraftingItem()
        end,
      }
      table.insert(options, newOption)
    end
    table.insert(options, {
      title = "Crie um novo item",
      description = "Crie um novo item para esta tabela de CRAFTING.",
      icon = 'circle',
      onSelect = function()
        local FilterData = {
          useFilter = false,
          filteredData = {}
        }
        :: BackToFilter ::
        local showedItems = {}
        if FilterData.useFilter then
          for _, filterWorld in pairs(FilterData.filteredData) do
            for _, item in pairs(item_select) do
              if string.find(string.lower(item.label), string.lower(filterWorld)) then
                table.insert(showedItems, item)
              end
            end
          end
        else
          showedItems = item_select
          FilterData.filteredData = {}
        end
        local input = lib.inputDialog('Selecione Item e Ingredientes', {
          { type = 'textarea',     label = "Filter - Filled search / Unfilled saves", description = "Write the labels of the items you want to filter. Separate them with ,", required = false, placeholder = "Meat, Fish, Bone", clearable = true },
          { type = 'select',       label = "Main item",                               description = "This is the item you want to crafting.",                                 required = true,  options = showedItems,            clearable = true },
          { type = 'multi-select', label = "Ingedience",                              description = "Required",                                                               required = true,  options = showedItems,            clearable = true },
        })
        if input then
          if tostring(input[1]) ~= "" then
            local searched_value = tostring(input[1])
            FilterData.useFilter = true
            for word in searched_value:gmatch("[^,%s]+") do
              table.insert(FilterData.filteredData, word)
            end
            goto BackToFilter
          end
          if input[1] == "" then
            local defineIngedience = {}
            for _, selectedIngedience in pairs(input[3]) do
              table.insert(defineIngedience, {
                itemName = selectedIngedience,
                itemCount = 1,
              })
            end

            local newTable = {
              itemName = input[2],
              itemCount = 1,
              ingedience = defineIngedience
            }
            table.insert(selectedJob.craftings[id].items, newTable)
            TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            lib.notify({
              title = "New recipe created",
              description = "Congrats! New recepie has been created.",
              type = "success"
            })
            openCraftingTable(cached.crafting_table_id)
          end
        end
      end,
    })

    table.insert(options, {
      title = "Delete table",
      description = "Click here for delete this table",
      icon = 'trash',
      onSelect = function()
        table.remove(selectedJob.craftings, id)
        lib.notify({
          title = "Deleted",
          description = "Crafting table has been deleted",
          type = "success"
        })
        TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
      end
    })

    lib.registerContext({
      id = 'create_new_crafting_item',
      title = 'Novo item',
      options = options
    })
    lib.showContext("create_new_crafting_item")
  end
end

function EditCrafings()
  if selectedJob then
    local options = {}
    for i, crafting in pairs(selectedJob.craftings) do
      local newOption = {
        title = crafting.label,
        description = "Click here for open crafting.",
        icon = 'circle',
        onSelect = function()
          openCraftingTable(i)
        end,
      }
      table.insert(options, newOption)
    end

    table.insert(options, {
      title = "New table",
      description = "Create new crafting table",
      icon = "plus",
      onSelect = function()
        CreateCraftingTable()
      end
    })

    lib.registerContext({
      id = 'job_crafting_list',
      title = selectedJob.label .. " - Crafting list",
      options = options
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
          local options = {
            {
              title = "Change stash ID",
              description =
              "Click here if you want to change the stash ID! If you don't know what you are doing don't touch this.",
              icon = 'circle',
              onSelect = function()
                local input = lib.inputDialog('Change stash ID', { 'Enter new ID/Name' })
                if input then
                  stashes.id = input[1]
                  TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
                end
              end
            }
            , {
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
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          }
          }
          lib.registerContext({
            id = 'job_system_stashes_edit',
            title = 'Baús',
            options = options
          })
          lib.showContext("job_system_stashes_edit")
        end,
      }
      table.insert(options, newOption)
    end

    table.insert(options, {
      title = "New stash",
      description = "Create stash",
      icon = "plus",
      onSelect = function()
        CreateNewStash()
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
        description = "Click here for edit ped",
        icon = 'circle',
        onSelect = function()
          local options = {
            {
              title = "Delete ped",
              description = "Click here for delete ped.",
              icon = 'trash',
              onSelect = function()
                table.remove(selectedJob.peds, i)
                lib.notify({
                  title = "Deleted",
                  description = "Ped deleted!",
                  type = "success"
                })
                TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
              end
            }
          }
          lib.registerContext({
            id = 'job_system_peds_edit',
            title = 'Ped',
            options = options
          })
          lib.showContext("job_system_peds_edit")
        end,
      }
      table.insert(options, newOption)
    end

    table.insert(options, {
      title = "New ped",
      description = "Create ped",
      icon = "plus",
      onSelect = function()
        CreateNewPed()
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

---- EVENTS
RegisterNetEvent("pls_jobsystem:client:createjob")
AddEventHandler("pls_jobsystem:client:createjob", function()
  local newJob = Config.DefaultDataJob
  local input = lib.inputDialog('Criar um novo Grupo',
    {
      { type = 'input',  label = 'Título',          description = 'Qual o Título do grupo?',                                                                         required = true,  min = 4,  max = 16 },
      { type = 'input',  label = 'Código do grupo', description = 'Coloque por exemplo: police, ballas, etc.',                                                       required = true,  min = 1,  max = 16 },
      { type = 'number', label = 'Área',            description = 'Tamanho da área do grupo. Para aparecer os peds, carregar targets e outros eventos necessários.', icon = 'hashtag', min = 10, max = 100 },
      {
        type = 'select',
        label = 'Tipo',
        description = 'Qual o tipo? Job = salário e ponto | Gang = sem salário e sem bater ponto.',
        options = { { value = 'job', label = 'Job' }, { value = 'gang', label = 'Gang' } },
        default = 1,
        required = true
      },
      { type = 'number', label = 'Cargos', description = 'Quantos cargos o grupo tem?', required = true, min = 1, max = 100 },
    })

  if not input then return end
  newJob.label = input[1]
  newJob.coords = GetEntityCoords(cache.ped)
  newJob.job = input[2]
  newJob.area = tonumber(input[3])
  newJob.type = input[4]

  local grades = {}

  for i = 1, input[5] do
    local options = {
      { type = 'number', label = 'Código do cargo', description = 'Qual o Código do cargo?', required = true, default = i - 1, disabled = true },
      { type = 'input',  label = 'Nome do cargo',   description = 'Qual o nome do cargo?',   required = true },
    }
    if input[4] == 'job' then
      options[#options + 1] = { type = 'number', label = 'Salário', description = 'Qual o Salário do cargo?', required = true, min = 0, max = 1000000 }
    end

    local _input = lib.inputDialog('Criação de Cargos', options)
    if not _input then return end
    local gradenumber = tonumber(_input[1])
    print(gradenumber)
    if not gradenumber then gradenumber = i - 1 end

    if _input[3] then
      if i == input[5] then
        grades[gradenumber] = {
          name = _input[2],
          payment = _input[3],
          isboss = true,
          bankAuth = true,
        }
      else
        grades[gradenumber] = {
            name = _input[2],
            payment = _input[3]
        }
      end
    else
      if i == input[5] then
        grades[gradenumber] = {
          name = _input[2],
          isboss = true,
          bankAuth = true,
        }
      else
        grades[gradenumber] = {
          name = _input[2],
        }
      end
    end
  end

  newJob.grades = grades


  local alert = lib.alertDialog({
    header = 'Criação de Craftings',
    content = 'Deseja criar um local de fabricação agora ou depois? ',
    centered = true,
    cancel = true
  })

  if alert == "confirm" then
    selectedJob = newJob
    CreateCraftingTable()
  else
    TriggerSecureEvent("pls_jobsystem:server:saveNewJob", newJob)
  end
end)


function EditCraftingItem()
  local count = 1
  if cached.crafting_item_id then
    if selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount then
      count = selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount
    end
    local options = {
      {
        title = "Contar: " .. count,
        description = "Isso é o que o jogador recebe",
        icon = 'hashtag',
        onSelect = function()
          print(selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount)
          local input = lib.inputDialog('Change count', { 'Enter number' })
          if input then
            selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].itemCount = tonumber(input[1])
            TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            openCraftingTable(cached.crafting_table_id)
          end
        end
      },
      {
        title = "Mude a animação",
        description = "Clique aqui para mudar de animação!",
        icon = 'hippo',
        onSelect = function()
          if selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation then
            local alert = lib.alertDialog({
              header = 'Animation clear',
              content = 'This clear animation! ( The default will be used / config.lua )',
              centered = true,
              cancel = true
            })
            if alert == "confirm" then
              selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation = nil
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          else
            local input = lib.inputDialog('Crafting animation', { 'Anim', "Dict" })
            if input then
              selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].animation = {
                anim = input
                    [1],
                dict = input[2]
              }
              TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            end
          end
          openCraftingTable(cached.crafting_table_id)
        end,
      }
    }
    for ingedienceId, v in pairs(selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].ingedience) do
      table.insert(options, {
        title = items[v.itemName].label .. " - x" .. v.itemCount,
        description = "Click here for change count",
        icon = 'circle',
        onSelect = function()
          local input = lib.inputDialog('Change count', { 'Enter number' })
          if input then
            selectedJob.craftings[cached.crafting_table_id].items[cached.crafting_item_id].ingedience[ingedienceId].itemCount =
                tonumber(input[1])
            TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
            openCraftingTable(cached.crafting_table_id)
          end
        end,
      })
    end
    table.insert(options, {
      title = "Delete item",
      description = "Click here for delete this item from crafting",
      icon = 'trash',
      onSelect = function()
        table.remove(selectedJob.craftings[cached.crafting_table_id].items, cached.crafting_item_id)
        TriggerSecureEvent("pls_jobsystem:server:saveJob", selectedJob)
        openCraftingTable(cached.crafting_table_id)
        lib.notify({
          title = "Deleted",
          description = "Item has been deleted",
          type = "success"
        })
      end,
    })
    lib.registerContext({
      id = 'create_new_crafting_item',
      title = 'Item de Crafting',
      options = options
    })
    lib.showContext("create_new_crafting_item")
  end
end

RegisterNetEvent("pls_jobsystem:client:openJobMenu")
AddEventHandler("pls_jobsystem:client:openJobMenu", function(Jobs)
  if Jobs then
    local options = {}
    for _, job in pairs(Jobs) do
      local newOption = {
        title = job.label .. " - " .. job.job,
        description = 'Craftings ' .. #job.craftings .. " / Area: " .. job.area,
        icon = 'circle',
        onSelect = function()
          selectJob(job)
        end,
      }
      table.insert(options, newOption)
    end
    lib.registerContext({
      id = 'job_menu_open',
      title = 'Trabalhos e Gangues',
      menu = 'menu_jobs',
      options = options
    })
    lib.showContext("job_menu_open")
  end
end)
