local IS_SERVER = IsDuplicityVersion()

Config = {}

Config.DefaultDataJob = {
    label = "", -- STRING
    job = "", -- STRING
    area = vector3(0,0,0), -- VECTOR 3
    craftings = {}, -- TABLE
    type = "",
    grades = {}
}

Config.DEFAULT_ANIM = "hack_loop"
Config.DEFAULT_ANIM_DIC = "mp_prison_break"

Config.BlacklistedStrings = {
    -- "weapon", "weed", "meth", "coke", "ammo", "gun", "pistol", "drug", "c4", "WEAPON", "AMMO", "at_", "keycard", "gun", "money", "black_money"
}

Config.DirectoryToInventoryImages = "nui://ox_inventory/web/images/"

if not IS_SERVER then
    function openBossmenu(jobtype)
        -- print("Bossmenu open")
        exports.qbx_management:OpenBossMenu(jobtype)
    end

    function SendDispatch(coords, jobLabel)
        -- YOU DISPATCH
        -- cache.ped
        -- print(coords)
        -- print(jobLabel)
        local PoliceJobs = { 'police' }
        exports["ps-dispatch"]:CustomAlert({
            coords = coords,
            job = PoliceJobs,
            message = 'Alarme Acionado!',
            dispatchCode = '10-??',
            firstStreet = coords,
            description = 'Alarme acionado de ' .. jobLabel,
            radius = 0,
            sprite = 161,
            color = 1,
            scale = 1.0,
            length = 3,
        })
    end
end
