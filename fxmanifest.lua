
fx_version 'adamant'
lua54 'yes'
game 'gta5'

description 'mri Qbox - Jobs and Gangs System'
credits 'Polisek'

shared_scripts { 
    'BRIDGE/config.lua',
    'BRIDGE/server/framework.lua',
    'config.lua',
    'secure.lua',
    '@ox_lib/init.lua', 
}

client_scripts {
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