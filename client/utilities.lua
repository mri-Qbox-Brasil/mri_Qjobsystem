local JOBS
local GANGS
local PlayerData

function CheckPlayerIsbossByJobSystemData(groupType, data)
    print('qual o player data? ' .. json.encode(data))
    JOBS = exports.qbx_core:GetJobs()
    GANGS = exports.qbx_core:GetGangs()
    PlayerData = data

    if not PlayerData[groupType].name then return false end
    local isBoss
    if groupType == "job" then
        isBoss = JOBS[PlayerData[groupType].name].grades[PlayerData[groupType].grade.level]["isboss"] or false
    else
        isBoss = GANGS[PlayerData[groupType].name].grades[PlayerData[groupType].grade.level]["isboss"] or false
    end
    if isBoss then return isBoss else return false end
end
exports('CheckPlayerIsbossByJobSystemData', CheckPlayerIsbossByJobSystemData)

function CheckPlayerIrecruiterByJobSystemData(groupType, data)
    print('qual o player data? ' .. json.encode(data))
    JOBS = exports.qbx_core:GetJobs()
    GANGS = exports.qbx_core:GetGangs()
    PlayerData = data
    

    if not PlayerData[groupType].name then return false end
    local isRecruiter
     if groupType == "job" then
        isRecruiter = JOBS[PlayerData[groupType].name].grades[PlayerData[groupType].grade.level]["isrecruiter"] or false
     else
        isRecruiter = GANGS[PlayerData[groupType].name].grades[PlayerData[groupType].grade.level]["isrecruiter"] or false
     end
    if isRecruiter then return isRecruiter else return false end
end

exports('CheckPlayerIrecruiterByJobSystemData', CheckPlayerIrecruiterByJobSystemData)

-- Função para ordenar uma tabela com base nos números entre colchetes no título
function SortByTitleIndex(options)

    table.sort(options, function(a, b)
        -- Tenta extrair o número dentro de [] no título (captura o número entre os colchetes)
        local aIndex = tonumber(string.match(a.title or a.label, "%[(%d+)%]"))
        local bIndex = tonumber(string.match(b.title or a.label, "%[(%d+)%]"))

        -- Se ambos `a` e `b` têm índices numéricos, ordena pelos números nos colchetes
        if aIndex and bIndex then
            return aIndex < bIndex
        -- Se `a` tem número e `b` não, coloca `b` (botão) antes
        elseif aIndex and not bIndex then
            return false
        -- Se `b` tem número e `a` não, coloca `a` (botão) antes
        elseif bIndex and not aIndex then
            return true
        -- Se nenhum tem número, mantém a ordem original (botões entre si)
        else
            return false
        end
    end)

    -- (Opcional) Retorna a tabela ordenada
    return options
end

-- Exporta a função para ser usada em outros scripts
exports('SortByTitleIndex', SortByTitleIndex)
