
fx_version 'adamant'
lua54 'yes'
game 'gta5'

description 'mri Qbox - Jobs and Gangs System'
credits 'Polisek'
ox_lib "locale"

shared_scripts {
    '@qbx_core/modules/playerdata.lua',
    'BRIDGE/config.lua',
    'BRIDGE/server/framework.lua',
    'config.lua',
    'secure.lua',
    '@ox_lib/init.lua',
    'client/utilities.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'BRIDGE/client/inventory.lua',
    'BRIDGE/client/target.lua',
	'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'BRIDGE/server/inventory.lua',
    'server/db.lua',
    'server/server.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql',
    'mri_Qbox'
}

files {
    "locales/*.json"
}